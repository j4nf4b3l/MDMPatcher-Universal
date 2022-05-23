

import Foundation
import IOKit
import IOKit.usb
import IOKit.usb.IOUSBLib
import IOKit.serial

//from IOUSBLib.h
public let kIOUSBDeviceUserClientTypeID = CFUUIDGetConstantUUIDWithBytes(nil,
                                                                         0x9d, 0xc7, 0xb7, 0x80, 0x9e, 0xc0, 0x11, 0xD4,
                                                                         0xa5, 0x4f, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61)
public let kIOUSBDeviceInterfaceID = CFUUIDGetConstantUUIDWithBytes(nil,
                                                                    0x5c, 0x81, 0x87, 0xd0, 0x9e, 0xf3, 0x11, 0xD4,
                                                                    0x8b, 0x45, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61)

//from IOCFPlugin.h
public let kIOCFPlugInInterfaceID = CFUUIDGetConstantUUIDWithBytes(nil,
                                                                   0xC2, 0x44, 0xE8, 0x58, 0x10, 0x9C, 0x11, 0xD4,
                                                                   0x91, 0xD4, 0x00, 0x50, 0xE4, 0xC6, 0x42, 0x6F)

public struct USBDevice {
    public let id:UInt64
    public let vendorId:UInt16
    public let productId:UInt16
    public let name:String
    public let locationId:UInt32
    public let vendorName:String?
    public let serialNr:String?
    public let bsdPath:String?

    public let deviceInterfacePtrPtr:UnsafeMutablePointer<UnsafeMutablePointer<IOUSBDeviceInterface>?>?
    public let plugInInterfacePtrPtr:UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?

    public init(id:UInt64,
                vendorId:UInt16,
                productId:UInt16,
                name:String,
                locationId:UInt32,
                vendorName:String?,
                serialNr:String?,
                bsdPath:String?,
                deviceInterfacePtrPtr:UnsafeMutablePointer<UnsafeMutablePointer<IOUSBDeviceInterface>?>?,
                plugInInterfacePtrPtr:UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?) {
        self.id = id
        self.vendorId = vendorId
        self.productId = productId
        self.name = name
        self.deviceInterfacePtrPtr = deviceInterfacePtrPtr
        self.plugInInterfacePtrPtr = plugInInterfacePtrPtr
        self.locationId = locationId
        self.vendorName = vendorName
        self.serialNr = serialNr
        self.bsdPath = bsdPath

    }
}

public protocol USBWatcherDelegate: class {
    /// Called on the main thread when a device is connected.
    func deviceAdded(_ device: io_object_t)

    /// Called on the main thread when a device is disconnected.
    func deviceRemoved(_ device: io_object_t)
}

/// An object which observes USB devices added and removed from the system.
/// Abstracts away most of the ugliness of IOKit APIs.
public class USBWatcher {
    private weak var delegate: USBWatcherDelegate?
    private let notificationPort = IONotificationPortCreate(kIOMasterPortDefault)
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0

    public init(delegate: USBWatcherDelegate) {
        self.delegate = delegate

        func handleNotification(instance: UnsafeMutableRawPointer?, _ iterator: io_iterator_t) {
            //the delay here is very important, because it gives the usb port time to set the bsp path for instance, this is sometimes needed.
            //maybe it should be on another thread?
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200), execute: {

                let watcher = Unmanaged<USBWatcher>.fromOpaque(instance!).takeUnretainedValue()
                let handler: ((io_iterator_t) -> Void)?
                switch iterator {
                case watcher.addedIterator: handler = watcher.delegate?.deviceAdded
                case watcher.removedIterator: handler = watcher.delegate?.deviceRemoved
                default: assertionFailure("received unexpected IOIterator"); return
                }
                while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
                    handler?(device)
                    IOObjectRelease(device)
                }
           })

        }

        let query = IOServiceMatching(kIOUSBDeviceClassName)
        let opaqueSelf = Unmanaged.passUnretained(self).toOpaque()

        // Watch for connected devices.
        IOServiceAddMatchingNotification(
            notificationPort, kIOMatchedNotification, query,
            handleNotification, opaqueSelf, &addedIterator)

        handleNotification(instance: opaqueSelf, addedIterator)

        // Watch for disconnected devices.
        IOServiceAddMatchingNotification(
            notificationPort, kIOTerminatedNotification, query,
            handleNotification, opaqueSelf, &removedIterator)

        handleNotification(instance: opaqueSelf, removedIterator)

        // Add the notification to the main run loop to receive future updates.
        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue(),
            .commonModes)
    }

    deinit {
        IOObjectRelease(addedIterator)
        IOObjectRelease(removedIterator)
        IONotificationPortDestroy(notificationPort)
    }
}

extension io_object_t {
    /// - Returns: The device's name.
    func name() -> String? {
        let buf = UnsafeMutablePointer<io_name_t>.allocate(capacity: 1)
        defer { buf.deallocate() }
        return buf.withMemoryRebound(to: CChar.self, capacity: MemoryLayout<io_name_t>.size) {
            if IORegistryEntryGetName(self, $0) == KERN_SUCCESS {
                return String(cString: $0)
            }
            return nil
        }
    }

    func getInfo() -> USBDevice? {
        var score:Int32 = 0
        var kr:Int32 = 0
        var did:UInt64 = 0
        var vid:UInt16 = 0
        var pid:UInt16 = 0
        var lid:UInt32 = 0
        var _serialNr:String?
        var _vendorName:String?
        var _bsdPath:String?

        var deviceInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOUSBDeviceInterface>?>?
        var plugInInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?

        kr = IORegistryEntryGetRegistryEntryID(self, &did)

        if(kr != kIOReturnSuccess) {
            print("Error getting device id")
        }

        kr = IOCreatePlugInInterfaceForService(
            self,
            kIOUSBDeviceUserClientTypeID,
            kIOCFPlugInInterfaceID,
            &plugInInterfacePtrPtr,
            &score)


        // Get plugInInterface for current USB device
        kr = IOCreatePlugInInterfaceForService(
            self,
            kIOUSBDeviceUserClientTypeID,
            kIOCFPlugInInterfaceID,
            &plugInInterfacePtrPtr,
            &score)

        // Dereference pointer for the plug-in interface
        if (kr != kIOReturnSuccess) {
            return nil
        }

        guard let plugInInterface = plugInInterfacePtrPtr?.pointee?.pointee else {
            print("Unable to get Plug-In Interface")
            return nil
        }

        // use plug in interface to get a device interface
        kr = withUnsafeMutablePointer(to: &deviceInterfacePtrPtr) {
            $0.withMemoryRebound(to: Optional<LPVOID>.self, capacity: 1) {
                plugInInterface.QueryInterface(
                    plugInInterfacePtrPtr,
                    CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                    $0)
            }
        }

        // dereference pointer for the device interface
        if (kr != kIOReturnSuccess) {
            return nil
        }

        guard let deviceInterface = deviceInterfacePtrPtr?.pointee?.pointee else {
            print("Unable to get Device Interface")
            return nil
        }

        kr = deviceInterface.USBDeviceOpen(deviceInterfacePtrPtr)

        // kIOReturnExclusiveAccess is not a problem as we can still do some things
        if (kr != kIOReturnSuccess && kr != kIOReturnExclusiveAccess) {
            print("Could not open device (error: \(kr))")
            return nil
        }

        kr = deviceInterface.GetDeviceVendor(deviceInterfacePtrPtr, &vid)
        if (kr != kIOReturnSuccess) {
            return nil
        }

        kr = deviceInterface.GetDeviceProduct(deviceInterfacePtrPtr, &pid)
        if (kr != kIOReturnSuccess) {
            return nil
        }

        kr = deviceInterface.GetLocationID(deviceInterfacePtrPtr, &lid)
        if (kr != kIOReturnSuccess) {
            return nil
        }

        var umDict: Unmanaged<CFMutableDictionary>? = nil
        kr = IORegistryEntryCreateCFProperties(self as io_registry_entry_t, &umDict, kCFAllocatorDefault, 0)


        var dict = umDict?.takeRetainedValue() as? NSDictionary
        if let dict = dict {
         //to show all properties available
            /*
            print("----------------------------")
            for (key,value) in dict {
                print("\(key): \(value)")
            }
            print("----------------------------")
             */


            if let serialNumber = dict.value(forKey: kUSBSerialNumberString) as? String {
                _serialNr = serialNumber
            }


            if let vendorName = dict.value(forKey: "USB Vendor Name") as? String {
                _vendorName = vendorName
            }

        }
        if let deviceBSDName_cf = IORegistryEntrySearchCFProperty (self,
                                                                   kIOServicePlane,
                                                                   kIOCalloutDeviceKey as CFString,
                                                                   kCFAllocatorDefault,
                                                                   UInt32(kIORegistryIterateRecursively )){


            _bsdPath = "\(deviceBSDName_cf)"
        }

        if let name = self.name() {


        return USBDevice(id: did, vendorId: vid, productId: pid, name: name, locationId: lid, vendorName: _vendorName, serialNr: _serialNr, bsdPath: _bsdPath, deviceInterfacePtrPtr: deviceInterfacePtrPtr, plugInInterfacePtrPtr: plugInInterfacePtrPtr)

        }
        return nil
    }
}

