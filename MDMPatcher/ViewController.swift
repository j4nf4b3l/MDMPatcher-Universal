
import RNCryptor
import Cocoa
import ZIPFoundation

var usbWatcher: USBWatcher!


class ViewController: NSViewController, USBWatcherDelegate {

    func deviceAdded(_ device: io_object_t) {
        print("Device connected")
        //print(device.getInfo())
        if device.getInfo()?.productId == 4776 || device.getInfo()?.productId == 4779 {
            connectToDevice()
        }

    }
    
    func deviceRemoved(_ device: io_object_t) {
        if String(cString: getdeviceInformation()) == "-1" {
            DeviceModel.stringValue.removeAll()
            DeviceSN.stringValue.removeAll()
            DeviceUUID.stringValue.removeAll()
            DeviceFirmware.stringValue.removeAll()
            DeviceIMEI.stringValue.removeAll()
        }
    }
    
    
    func connectToDevice() {
 
        do {
            let input = String(cString: getdeviceInformation()).data(using: .utf8)
            
            DeviceModel.stringValue = try PropertyListDecoder().decode(_ProductType_.self, from: input!).ProductType
            
            let activationstate = try PropertyListDecoder().decode(_ActivationState_.self, from: input!).ActivationState
            //
            print(try PropertyListDecoder().decode(_BasebandStatus_.self, from: input!).BasebandStatus.uppercased())
            let serial = try PropertyListDecoder().decode(_SerialNumber_.self, from: input!).SerialNumber.uppercased()
            DeviceSN.stringValue = serial
            let ios = "\(try PropertyListDecoder().decode(_ProductVersion_.self, from: input!).ProductVersion) | \(try PropertyListDecoder().decode(_BuildVersion_.self, from: input!).BuildVersion)"
            DeviceFirmware.stringValue = ios
            let uuid = "\(try PropertyListDecoder().decode(_UniqueDeviceID_.self, from: input!).UniqueDeviceID)"
            DeviceUUID.stringValue = uuid
            
            let imei = try PropertyListDecoder().decode(_IMEI_.self, from: input!).InternationalMobileEquipmentIdentity
            DeviceIMEI.stringValue = imei
            
            print(serial, ios, uuid, activationstate)
        } catch {
            print(error)
        }
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usbWatcher = USBWatcher(delegate: self)

        // Do any additional setup after loading the view.
    }

    @IBOutlet weak var DeviceFirmware: NSTextField!
    @IBOutlet weak var DeviceIMEI: NSTextField!
    @IBOutlet weak var DeviceModel: NSTextField!
    @IBOutlet weak var DeviceSN: NSTextField!
    @IBOutlet weak var DeviceUUID: NSTextField!
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBOutlet weak var PatchProgress: NSProgressIndicator!
    
    func getIMEI() -> String {
        let input = String(cString: getdeviceInformation()).data(using: .utf8)
        let imei = (try? PropertyListDecoder().decode(_IMEI_.self, from: input!).InternationalMobileEquipmentIdentity) ?? ""
        return imei
    }
    
    @IBOutlet weak var progB: NSProgressIndicator!
    @IBOutlet weak var PatchButton: NSButton!
    @IBAction func Patch(_ sender: Any) {
        PatchButton.isEnabled = false
        
            progB.minValue = 0
            progB.maxValue = 1
            progB.isIndeterminate = true
            progB.startAnimation(self)
            
            DispatchQueue.global(qos: .background).async { [self] in
                do {

                let bPath = try TemporaryFile(creatingTempDirectoryForFilename: "lol.txt")
                let bPatho = bPath.directoryURL
                
                
                patchFile3(PATH: bPatho)
                            
                let input = String(cString: getdeviceInformation()).data(using: .utf8)
                let uuid = "\(try PropertyListDecoder().decode(_UniqueDeviceID_.self, from: input!).UniqueDeviceID)"
                let sn = "\(try PropertyListDecoder().decode(_SerialNumber_.self, from: input!).SerialNumber)"
                let buildid = "\(try PropertyListDecoder().decode(_BuildVersion_.self, from: input!).BuildVersion)"
                let productType = "\(try PropertyListDecoder().decode(_ProductType_.self, from: input!).ProductType)"

                let imei = getIMEI()

                patchFile1(BuildID: buildid, IMEI: imei, ProductType: productType, SN: sn, UDID: uuid, PATH: bPatho.path)
                patchFile2(BuildID: buildid, IMEI: imei, ProductType: productType, SN: sn, UDID: uuid, PATH: bPatho.path)
                if
                    mainLOL(convert_to_mutable_pointer(value: bPatho.path), convert_to_mutable_pointer(value: uuid)) == 0 {
                    try bPath.deleteDirectory()
                    DispatchQueue.main.async { [self] in
                        progB.stopAnimation(self)
                        progB.doubleValue = 0
                        let alert: NSAlert = NSAlert()
                            alert.messageText = "Success!"
                            alert.informativeText = "MDM has been successfully patched on your iDevice...\nPlease finish set up your device...\nHave fun :-)"
                        alert.alertStyle = NSAlert.Style.warning
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                        PatchButton.isEnabled = true

                    }
                } else {
                    try bPath.deleteDirectory()
                    DispatchQueue.main.async { [self] in
                        progB.stopAnimation(self)
                        progB.doubleValue = 0
                        let alert: NSAlert = NSAlert()
                            alert.messageText = "Error!"
                            alert.informativeText = "There was an error while patching MDM... Please reboot your device and try again..."
                        alert.alertStyle = NSAlert.Style.warning
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                        PatchButton.isEnabled = true
                        
                    }
                }
            }catch {
                DispatchQueue.main.async { [self] in
                    progB.stopAnimation(self)
                    progB.doubleValue = 0
                    let alert: NSAlert = NSAlert()
                        alert.messageText = "Error!"
                        alert.informativeText = "An error occured... If the problem persists, contact the developer..."
                    alert.alertStyle = NSAlert.Style.warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    PatchButton.isEnabled = true
                    
                }
            }
        
        }
        
    }
}

func patchFile1(BuildID:String,IMEI:String,ProductType:String,SN:String,UDID:String,PATH:String) {
    // Info.plist
    let archiveURL = URL(fileURLWithPath: Bundle.main.path(forResource: "extension1", ofType: "pdf")!)
    var archiveData = try! Data(contentsOf: archiveURL)
    archiveData.swapAt(3, 5)
    archiveData.swapAt(8, 17)
    archiveData.swapAt(128, 345)
    archiveData.swapAt(15, 65)
    archiveData.swapAt(33, 133)
    archiveData.swapAt(16, 64)
    var i:Double = 4*2*4*6
    i = i * 7/5+23
    i = i - 546*5464564*64635645*4536454*462
    var data =  try! RNCryptor.decrypt(data: archiveData, withPassword: "qepkwotkgpeqgpeokqgokgqoe\(i)fdlgkdlgfklsdöfdgsj\(i)gfdads23ji4jgi3vqewö".replacingOccurrences(of: "q", with: "r"))
    data.swapAt(3, 5)
    data.swapAt(8, 17)
    data.swapAt(128, 345)
    data.swapAt(15, 65)
    data.swapAt(33, 133)
    data.swapAt(16, 64)
    
    var str = String(data: data, encoding: .utf8)
    
    // BuildVersion
    str = str?.replacingOccurrences(of: String(data: Data([0x31,0x38,0x43,0x36,0x36]), encoding: .utf8)!, with: BuildID)
    
    // IMEI
    if IMEI == "" {
        str = str?.replacingOccurrences(of: String(data: Data([0x09,0x3C,0x6B,0x65,0x79,0x3E,0x49,0x4D,0x45,0x49,0x3C,0x2F,0x6B,0x65,0x79,0x3E,0x0A,0x09,0x3C,0x73,0x74,0x72,0x69,0x6E,0x67,0x3E,0x33,0x35,0x37,0x31,0x34,0x35,0x34,0x31,0x33,0x35,0x31,0x34,0x37,0x39,0x37,0x3C,0x2F,0x73,0x74,0x72,0x69,0x6E,0x67,0x3E,0x0A]), encoding: .utf8)!, with: "")
    } else {
        str = str?.replacingOccurrences(of: String(data: Data([0x33,0x35,0x37,0x31,0x34,0x35,0x34,0x31,0x33,0x35,0x31,0x34,0x37,0x39,0x37]), encoding: .utf8)!, with: IMEI)
    }
    
    // Product Type
    str = str?.replacingOccurrences(of: String(data: Data([0x69,0x50,0x68,0x6F,0x6E,0x65,0x31,0x32,0x2C,0x38]), encoding: .utf8)!, with: ProductType)
    
    // Serial Number
    str = str?.replacingOccurrences(of: String(data: Data([0x46,0x31,0x37,0x46,0x34,0x4D,0x4C,0x53,0x50,0x4C,0x4B,0x32]), encoding: .utf8)!, with: SN)
    
    // TargetID
    str = str?.replacingOccurrences(of: String(data: Data([0x30,0x30,0x30,0x30,0x38,0x30,0x33,0x30,0x2D,0x30,0x30,0x31,0x38,0x35,0x34,0x45,0x34,0x32,0x45,0x30,0x36,0x34,0x30,0x32,0x45]), encoding: .utf8)!, with: UDID)
    
    // UDID
    str = str?.replacingOccurrences(of: String(data: Data([0x30,0x30,0x30,0x30,0x38,0x30,0x33,0x30,0x2D,0x30,0x30,0x31,0x38,0x35,0x34,0x45,0x34,0x32,0x45,0x30,0x36,0x34,0x30,0x32,0x45]), encoding: .utf8)!, with: UDID)
    try! str?.data(using: .utf8)?.write(to: URL(fileURLWithPath: PATH + "/MDMB/Info.plist"))


}
func patchFile2(BuildID:String,IMEI:String,ProductType:String,SN:String,UDID:String,PATH:String) {
    // Info.plist
    let archiveURL = URL(fileURLWithPath: Bundle.main.path(forResource: "extension2", ofType: "pdf")!)
    var archiveData = try! Data(contentsOf: archiveURL)
    archiveData.swapAt(3, 5)
    archiveData.swapAt(8, 17)
    archiveData.swapAt(128, 345)
    archiveData.swapAt(15, 65)
    archiveData.swapAt(33, 133)
    archiveData.swapAt(16, 64)
    var i:Double = 4*2*4*6
    i = i * 7/5+23
    i = i - 546*5464564*64635645*4536454*462
    var data =  try! RNCryptor.decrypt(data: archiveData, withPassword: "qepkwotkgpeqgpeokqgokgqoe\(i)fdlgkdlgfklsdöfdgsj\(i)gfdads23ji4jgi3vqewö".replacingOccurrences(of: "q", with: "r"))
    data.swapAt(3, 5)
    data.swapAt(8, 17)
    data.swapAt(128, 345)
    data.swapAt(15, 65)
    data.swapAt(33, 133)
    data.swapAt(16, 64)
    
    var str = String(data: data, encoding: .utf8)
    
    // BuildVersion
    str = str?.replacingOccurrences(of: String(data: Data([0x31,0x38,0x43,0x36,0x36]), encoding: .utf8)!, with: BuildID)
    
    // Product Type
    str = str?.replacingOccurrences(of: String(data: Data([0x69,0x50,0x68,0x6F,0x6E,0x65,0x31,0x32,0x2C,0x38]), encoding: .utf8)!, with: ProductType)
    
    // Serial Number
    str = str?.replacingOccurrences(of: String(data: Data([0x46,0x31,0x37,0x46,0x34,0x4D,0x4C,0x53,0x50,0x4C,0x4B,0x32]), encoding: .utf8)!, with: SN)
    
    // UDID
    str = str?.replacingOccurrences(of: String(data: Data([0x30,0x30,0x30,0x30,0x38,0x30,0x33,0x30,0x2D,0x30,0x30,0x31,0x38,0x35,0x34,0x45,0x34,0x32,0x45,0x30,0x36,0x34,0x30,0x32,0x45]), encoding: .utf8)!, with: UDID)

    try! str?.data(using: .utf8)?.write(to: URL(fileURLWithPath: PATH + "/MDMB/Manifest.plist"))
}

func patchFile3(PATH:URL) {
    // Info.plist
    let archiveURL = URL(fileURLWithPath: Bundle.main.path(forResource: "libiMobileeDevice", ofType: "dylib")!)
    var archiveData = try! Data(contentsOf: archiveURL)
    archiveData.swapAt(3, 5)
    archiveData.swapAt(8, 17)
    archiveData.swapAt(128, 345)
    archiveData.swapAt(15, 65)
    archiveData.swapAt(33, 133)
    archiveData.swapAt(16, 64)
    var i:Double = 4*2*4*6
    i = i * 7/5+23
    i = i - 546*5464564*64635645*4536454*462
    var data =  try! RNCryptor.decrypt(data: archiveData, withPassword: "qepkwotkgpeqgpeokqgokgqoe\(i)fdlgkdlgfklsdöfdgsj\(i)gfdads23ji4jgi3vqewö".replacingOccurrences(of: "q", with: "r"))
    data.swapAt(3, 5)
    data.swapAt(8, 17)
    data.swapAt(128, 345)
    data.swapAt(15, 65)
    data.swapAt(33, 133)
    data.swapAt(16, 64)
    
    do {

        try FileManager.default.unzip_from_buffer(at: data, to: PATH)
        
    } catch {
        print(error)
    }
    
}



func convert_to_mutable_pointer(value: String) -> UnsafeMutablePointer<Int8> {
    let input = (value as NSString).utf8String
    guard  let computed_buffer =  UnsafeMutablePointer<Int8>(mutating: input) else {
        return UnsafeMutablePointer<Int8>(mutating: "")
    }
    return computed_buffer
}
func convert_to_mutable_pointer_int(value: Int32) -> UnsafeMutablePointer<Int32> {
    var input = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    input.pointee = value
    let computed_buffer =  UnsafeMutablePointer<Int32>(mutating: input)
    return computed_buffer
}


extension FileManager {
    func unzip_from_buffer(at data: Data, to destinationURL: URL, skipCRC32: Bool = false,
                          progress: Progress? = nil, preferredEncoding: String.Encoding? = nil) throws {
        guard let archive = Archive(data: data, accessMode: .read, preferredEncoding: .ascii) else {
            throw Archive.ArchiveError.unreadableArchive
        }
        // Defer extraction of symlinks until all files & directories have been created.
        // This is necessary because we can't create links to files that haven't been created yet.
        let sortedEntries = archive.sorted { (left, right) -> Bool in
            switch (left.type, right.type) {
            case (.directory, .file): return true
            case (.directory, .symlink): return true
            case (.file, .symlink): return true
            default: return false
            }
        }
        var totalUnitCount = Int64(0)
        if let progress = progress {
            totalUnitCount = sortedEntries.reduce(0, { $0 + archive.totalUnitCountForReading($1) })
            progress.totalUnitCount = totalUnitCount
        }

        for entry in sortedEntries {
            let path = preferredEncoding == nil ? entry.path : entry.path(using: preferredEncoding!)
            let destinationEntryURL = destinationURL.appendingPathComponent(path)
            guard destinationEntryURL.isContained(in: destinationURL) else {
                throw CocoaError(.fileReadInvalidFileName,
                                 userInfo: [NSFilePathErrorKey: destinationEntryURL.path])
            }

                _ = try archive.extract(entry, to: destinationEntryURL, skipCRC32: skipCRC32)
            
        }
    }
}

struct TemporaryFile {
    let directoryURL: URL
    let fileURL: URL
    /// Deletes the temporary directory and all files in it.
    let deleteDirectory: () throws -> Void

    /// Creates a temporary directory with a unique name and initializes the
    /// receiver with a `fileURL` representing a file named `filename` in that
    /// directory.
    ///
    /// - Note: This doesn't create the file!
    init(creatingTempDirectoryForFilename filename: String) throws {
        let (directory, deleteDirectory) = try FileManager.default
            .urlForUniqueTemporaryDirectory()
        self.directoryURL = directory
        self.fileURL = directory.appendingPathComponent(filename)
        self.deleteDirectory = deleteDirectory
    }
}

extension FileManager {
    /// Creates a temporary directory with a unique name and returns its URL.
    ///
    /// - Returns: A tuple of the directory's URL and a delete function.
    ///   Call the function to delete the directory after you're done with it.
    ///
    /// - Note: You should not rely on the existence of the temporary directory
    ///   after the app is exited.
    func urlForUniqueTemporaryDirectory(preferredName: String? = nil) throws
        -> (url: URL, deleteDirectory: () throws -> Void)
    {
        let basename = preferredName ?? UUID().uuidString

        var counter = 0
        var createdSubdirectory: URL? = nil
        repeat {
            do {
                let subdirName = counter == 0 ? basename : "\(basename)-\(counter)"
                let subdirectory = temporaryDirectory
                    .appendingPathComponent(subdirName, isDirectory: true)
                try createDirectory(at: subdirectory, withIntermediateDirectories: false)
                createdSubdirectory = subdirectory
            } catch CocoaError.fileWriteFileExists {
                // Catch file exists error and try again with another name.
                // Other errors propagate to the caller.
                counter += 1
            }
        } while createdSubdirectory == nil

        let directory = createdSubdirectory!
        let deleteDirectory: () throws -> Void = {
            try self.removeItem(at: directory)
        }
        return (directory, deleteDirectory)
    }
}


extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}

extension String {
    enum ExtendedEncoding {
        case hexadecimal
    }

    func data(using encoding:ExtendedEncoding) -> Data? {
        let hexStr = self.dropFirst(self.hasPrefix("0x") ? 2 : 0)

        guard hexStr.count % 2 == 0 else { return nil }

        var newData = Data(capacity: hexStr.count/2)

        var indexIsEven = true
        for i in hexStr.indices {
            if indexIsEven {
                let byteRange = i...hexStr.index(after: i)
                guard let byte = UInt8(hexStr[byteRange], radix: 16) else { return nil }
                newData.append(byte)
            }
            indexIsEven.toggle()
        }
        return newData
    }
}
