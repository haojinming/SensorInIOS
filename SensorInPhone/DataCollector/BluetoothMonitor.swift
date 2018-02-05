//
//  BluetoothMonitor.swift
//  SeamlessDemo
//
//  Created by utrc on 22/01/2018.
//  Copyright © 2018 utrc. All rights reserved.
//

import Foundation
import CoreBluetooth

class BluetoothMonitor: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    static let shared = BluetoothMonitor.init()
    
    //private let serviceUUID = CBUUID.init(string: "FFF0")
    private let serviceUUID = CBUUID.init(string: "0xFEA7")
    
    private var timeIntervalBLEScan = 1.0 / 10.0
    private var timerBLEDevice : Timer!
    private var cbCentralManager : CBCentralManager!
    private var cbPeripheralDevice : CBPeripheral!
    
    public var bleState = "PowerOff"
    public var bleDevicesData = [BLEDeviceData]()
    
    override init() {
    }
    
    public func startScanPeripheral(){
        if self.cbCentralManager == nil{
            self.cbCentralManager = CBCentralManager.init(delegate: self, queue: DispatchQueue.main, options: [CBCentralManagerOptionRestoreIdentifierKey : "HJMID"])
        }
        
        if timerBLEDevice != nil{
            timerBLEDevice.fire()
        }else{
            timerBLEDevice = Timer.init(fire: Date.init(), interval: timeIntervalBLEScan, repeats: true, block: { (timerBLEDevice) in
                switch self.cbCentralManager.state {
                case .poweredOn:
                    if self.cbCentralManager.isScanning{
                        self.cbCentralManager.stopScan()
                    }
                    self.cbCentralManager.scanForPeripherals(withServices: [self.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
                    self.bleState = "PowerOn"
                default:
                    break
                }
            })
            RunLoop.main.add(timerBLEDevice, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    public func stopScanPeripheral(){
        if timerBLEDevice != nil{
            timerBLEDevice.invalidate()
            timerBLEDevice = nil
        }
        if cbCentralManager != nil{
            cbCentralManager.stopScan()
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            self.bleState = "PowerOn"
            if self.cbCentralManager.isScanning{
                cbCentralManager.stopScan()
            }
            cbCentralManager.scanForPeripherals(withServices: [serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        case .poweredOff:
            self.bleState = "PoweredOff"
        case .resetting:
            self.bleState = "Resetting"
        case .unauthorized:
            self.bleState = "Unauthorized"
        case .unsupported:
            self.bleState = "Unsupported"
        default:
            self.bleState = "Unknown"
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var bleState = "Not supported"
        switch peripheral.state {
        case .connected:
            bleState = "Connected"
        case .connecting:
            bleState = "Connecting"
        case .disconnecting:
            bleState = "Disconnecting"
        case .disconnected:
            bleState = "Disconnected"
            //cbCentralManager.connect(peripheral, options: nil)
        }
        var bleName = "No Name"
        if peripheral.name != nil {
            bleName = peripheral.name!
        }
        let bleUUID = peripheral.identifier.uuidString
        let bleRSSI = RSSI.intValue
        let bleDevice = BLEDeviceData.init(name: bleName, uuid: bleUUID, state: bleState, rssi: bleRSSI)
        let infoStr = "Detect BLE: " + bleUUID + ": " + String(bleRSSI)
        updateBLEDeviceDate(inputBleDevice: bleDevice)
    }
    
    private func updateBLEDeviceDate(inputBleDevice : BLEDeviceData){
        //If exist same device, update its information.
        var currentIndex = -1
        for ii in 0..<self.bleDevicesData.count{
            if self.bleDevicesData[ii].uuid == inputBleDevice.uuid{
                currentIndex = ii
            }
        }
        if currentIndex >= 0{
            self.bleDevicesData.remove(at: currentIndex)
        }
        self.bleDevicesData.append(inputBleDevice)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        cbPeripheralDevice = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error == nil{
            for service in peripheral.services!{
                let serviceID = service.uuid
                print(serviceID)
                print(serviceUUID)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("APP will restore")
        
        let restoreID = dict[CBCentralManagerOptionRestoreIdentifierKey]
        if restoreID != nil {
            cbCentralManager = CBCentralManager.init(delegate: self, queue: DispatchQueue.main, options: [CBCentralManagerOptionRestoreIdentifierKey : restoreID as! String])
        }else{
            cbCentralManager = CBCentralManager.init(delegate: self, queue: DispatchQueue.main, options: [CBCentralManagerOptionRestoreIdentifierKey : "HJMID"])
        }
    }
    
    private func getAllBLEDevices() -> [String]{
        var result : [String] = []
        for oneDevice in bleDevicesData{
            if !result.contains(oneDevice.uuid){
                result.append(oneDevice.uuid)
            }
        }
        result.sort()
        return result
    }
}
