

import Foundation
//com.apple.disk_usage
//com.apple.disk_usage.factory
//com.apple.mobile.battery
//com.apple.iqagent
//com.apple.purplebuddy
//com.apple.PurpleBuddy
//com.apple.mobile.chaperone
//com.apple.mobile.third_party_termination
//com.apple.mobile.lockdownd
//com.apple.mobile.lockdown_cache
//com.apple.xcode.developerdomain
//com.apple.international
//com.apple.mobile.data_sync
//com.apple.mobile.tethered_sync
//com.apple.mobile.mobile_application_usage
//com.apple.mobile.backup
//com.apple.mobile.nikita
//com.apple.mobile.restriction
//com.apple.mobile.user_preferences
//com.apple.mobile.sync_data_class
//com.apple.mobile.software_behavior
//com.apple.mobile.iTunes.SQLMusicLibraryPostProcessCommands
//com.apple.mobile.iTunes.accessories
//com.apple.mobile.internal
//com.apple.mobile.wireless_lockdown
//com.apple.fairplay
//com.apple.iTunes
//com.apple.mobile.iTunes.store
//com.apple.mobile.iTunes


struct _ActivationState_: Codable {
    let ActivationState:String
}
struct _BluetoothAddress_: Codable {
    let BluetoothAddress:String
}
struct _WiFiAddress_: Codable {
    let WiFiAddress:String
}
struct _SerialNumber_: Codable {
    let SerialNumber:String
}
struct _DeviceName_: Codable {
    let DeviceName:String
}
struct _DeviceClass_: Codable {
    let DeviceClass:String
}
struct _UniqueChipID_: Codable {
    let UniqueChipID:Int
}

struct _UniqueDeviceID_: Codable {
    let UniqueDeviceID:String
}
struct _ProductionSOC_: Codable {
    let ProductionSOC:Bool
}
struct _ProductVersion_: Codable {
    let ProductVersion:String
}
struct _ProductType_: Codable {
    let ProductType:String
}

struct _HardwareModel_: Codable {
    let HardwareModel:String
}
struct _BoardId_: Codable {
    let BoardId:Int
}
struct _BrickState_: Codable {
    let BrickState:Bool
}
struct _BuildVersion_: Codable {
    let BuildVersion:String
}

struct _CPUArchitecture_: Codable {
    let CPUArchitecture:String
}
struct _EthernetAddress_: Codable {
    let EthernetAddress:String
}
struct _FirmwareVersion_: Codable {
    let FirmwareVersion:String
}
struct _MLBSerialNumber_: Codable {
    let MLBSerialNumber:String
}

struct _RegionInfo_: Codable {
    let RegionInfo:String
}
struct _BasebandCertId_: Codable {
    let BasebandCertId:Int
}
struct _BasebandStatus_: Codable {
    let BasebandStatus:String
}
struct _BasebandVersion_: Codable {
    let BasebandVersion:String
}

struct _SIMStatus_: Codable {
    let SIMStatus:String
}
struct _SIMTrayStatus_: Codable {
    let SIMTrayStatus:String
}

struct _IMEI_: Codable {
    let InternationalMobileEquipmentIdentity:String
}

struct _GasGauge_Battery_Info_: Codable {
    let GasGauge:Gas_Gauge_Detail
}
struct Gas_Gauge_Detail: Codable {
    let CycleCount:Int
    let DesignCapacity:Int
    let FullChargeCapacity:Int
}
