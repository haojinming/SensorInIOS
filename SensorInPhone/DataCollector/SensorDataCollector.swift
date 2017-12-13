//
//  SensorInformation.swift
//  SensorInfo
//
//  Created by utrc on 28/08/2017.
//  Copyright © 2017 utrc. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import CoreMotion
import AVFoundation
import CoreImage
import ImageIO
import CoreBluetooth

enum Frequency : String {
    case HZ_1 = "1 HZ"
    case HZ_10 = "10 HZ"
    case HZ_20 = "20 HZ"
    case HZ_50 = "50 HZ"
    case HZ_100 = "100 HZ"
}

class SensorDataCollector: UIResponder, AVCaptureVideoDataOutputSampleBufferDelegate, AVAudioRecorderDelegate, CBCentralManagerDelegate,  CBPeripheralDelegate, CLLocationManagerDelegate {
    
    static let shared = SensorDataCollector.init()
    
    private override init() {
        realTimeData = RealTimeData.init()
        frequency = Frequency.HZ_50
        
        isRunning = false
        super.init()
    }
    
    private var isRunning : Bool
    
    /****************experiment information************************/
    private var startTime : Date?
    private var endTime : Date?
    private var frequency : Frequency
    private var realTimeData : RealTimeData
    private var audioURL : URL!
    
    public func getStartTime() -> Date?{
        return startTime
    }
    public func getEndTime() -> Date?{
        return endTime
    }
    
    public func getFrequency() -> Frequency{
        return frequency
    }
    public func setFrequency(freq : Frequency){
        self.frequency = freq
        var value : Double = 1.0
        switch freq {
        case .HZ_10:
            value = 1.0 / 10.0
        case .HZ_20:
            value = 1.0 / 20.0
        case .HZ_50:
            value = 1.0 / 50.0
        case .HZ_100:
            value = 1.0 / 100.0
        default:
            value = 1.0
        }
        timeIntervalUpdate = value
    }

    /*****************************************************************/
    public func setShakeStatus(status : String){
        realTimeData.sensorData.shakeStatus = status
    }
    public func getShakeTimes() -> Int{
        return realTimeData.sensorData.shakeTimes
    }
    public func setShakeTimes(times : Int){
        realTimeData.sensorData.shakeTimes = times
    }

    private var peripheralDevices : [CBPeripheral] = []
    private let motionManager = CMMotionManager.init()
    private let motionActivityManager = CMMotionActivityManager.init()
    private var locationManager : CLLocationManager!
    private let pedometer = CMPedometer.init()
    private let session = AVCaptureSession.init()
    private let altitudeSensor = CMAltimeter.init()
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioRecorder : AVAudioRecorder!
    private var cbCentralManager : CBCentralManager!
    private var cbPeripheralDevice : CBPeripheral!
    
    private var timeIntervalUpdate = 1.0 / 10.0
    private var timeIntervalBLEScan = 1.0 / 10.0
    private var refreshTimer : Timer!
    private var timerBLEDevice : Timer!
    
    //init setting
    private func initSetting(){
        peripheralDevices.removeAll()
        self.realTimeData = RealTimeData.init()
        realTimeData.sensorData.shakeTimes = 0
        realTimeData.sensorData.shakeStatus = "No Shake."
        
        let userDefault = UserDefaults.init()
        if let frequencyStr = userDefault.string(forKey: SettingKey.Frequency.rawValue){
            if let fre = Frequency(rawValue : frequencyStr){
                self.setFrequency(freq: fre)
            }
        }
    }
    //If the newrecord is false, it means it's collecting data in background.
    public func startCollectSensorData(){
        if isRunning {
            return
        }else{
            isRunning = true
        }
        initSetting()
        
        startUpdateMotionSensor()
        startPedometerData()
        startAltitudeData()
        startGetAmbientLightValue()
        startRecordAudio()
        startProximityStatus()
        startUpdateLocation()
        // If this is the record from background call, don't need start peripheral scan again.
        startScanPeripheral()
        if refreshTimer != nil{
            refreshTimer.fire()
        }
        else{
            //new refresh timer
            self.refreshTimer = Timer.init(fire: Date.init(), interval: timeIntervalUpdate, repeats: true, block: { (freshTimer) in
                self.fillRealtimeData()
                //append the realtime date to window filter
            })
            RunLoop.main.add(refreshTimer, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    public func stopCollectSensorData(){
        endTime = Date.init()
        stopUpdateMotionSensor()
        stopPedometerData()
        stopAltitudeData()
        stopCaptureSession()
        stopRecordAudio()
        stopProximityStatus()
        stopScanPeripheral()
        stopUpdateLocation()
        
        if refreshTimer != nil{
            refreshTimer.invalidate()
            refreshTimer = nil
        }
        isRunning = false
    }
    
    public func getRealtimeSensorData() -> ([String], [String]){
        return realTimeData.printRealtimeDataWithFormat()
    }
    
    private func fillRealtimeData(){
        self.realTimeData.recordTime = Date.init()
        self.realTimeData.sensorData.wifiSSID = self.getWifiSSID()
        self.realTimeData.sensorData.wifiStrength = self.getWifiStrength()
        
        //get the motion sensor data
        if let data = self.motionManager.accelerometerData{
            self.realTimeData.sensorData.accelerometerData = data.acceleration
        }
        if let data = self.motionManager.gyroData{
            self.realTimeData.sensorData.gyroscopeData = data.rotationRate
        }
        if let data = self.motionManager.magnetometerData{
            self.realTimeData.sensorData.magnetometerData = data.magneticField
        }
        
        //fill audio decibel data
        if self.audioRecorder != nil && self.audioRecorder.isRecording{
            self.audioRecorder.updateMeters()
            let power = self.audioRecorder.averagePower(forChannel: 0)
            self.realTimeData.sensorData.audioData = Double(power)
        }
    }
    
    //start/stop collecting data of motion sensor
    private func startUpdateMotionSensor(){
        //usage of core motion manager
        if self.motionManager.isAccelerometerAvailable{
            self.motionManager.accelerometerUpdateInterval = timeIntervalUpdate
            self.motionManager.startAccelerometerUpdates()
        }
        if self.motionManager.isGyroAvailable {
            self.motionManager.gyroUpdateInterval = timeIntervalUpdate
            self.motionManager.startGyroUpdates()
        }
        if self.motionManager.isMagnetometerAvailable{
            self.motionManager.magnetometerUpdateInterval = timeIntervalUpdate
            self.motionManager.startMagnetometerUpdates()
        }
        self.motionActivityManager.startActivityUpdates(to: OperationQueue.main) { (motionActivity) in
            var status = MotionActivity.Unkown
            var confidence = "Low"
            if let activity = motionActivity{
                if activity.unknown{
                    status = MotionActivity.Unkown
                }else if activity.walking{
                    status = MotionActivity.Walking
                }else if activity.running{
                    status = MotionActivity.Running
                }else if activity.cycling{
                    status = MotionActivity.Cycling
                }else if activity.automotive{
                    status = MotionActivity.Automotive
                }else if activity.stationary{
                    status = MotionActivity.Stationary
                }
                switch activity.confidence{
                case .high:
                    confidence = "High"
                case .medium:
                    confidence = "Medium"
                case .low:
                    confidence = "Low"
                }
                self.realTimeData.sensorData.activity = status
                self.realTimeData.sensorData.confidence = confidence
            }
        }
    }
    
    private func stopUpdateMotionSensor(){
        if self.motionManager.isAccelerometerAvailable{
            self.motionManager.stopAccelerometerUpdates()
        }
        if self.motionManager.isGyroAvailable{
            self.motionManager.stopGyroUpdates()
        }
        if self.motionManager.isMagnetometerAvailable{
            self.motionManager.stopMagnetometerUpdates()
        }
        self.motionActivityManager.stopActivityUpdates()
    }
    
    //start/stop collecting pedometer data
    private func startPedometerData(){
        self.realTimeData.sensorData.pedometerData = CMPedometerData.init()
        if !CMPedometer.isStepCountingAvailable(){
            print("Pedometer is not available.")
        }
        if !CMPedometer.isPaceAvailable(){
            print("Pace is not available.")
        }
        self.pedometer.startUpdates(from: Date.init(), withHandler: { data, error in
            if (error != nil){
                print(error.debugDescription)
            }
            if let tempData = data{
                self.realTimeData.sensorData.pedometerData = tempData
            }
        })
    }
    
    private func stopPedometerData(){
        if CMPedometer.isStepCountingAvailable(){
            self.pedometer.stopUpdates()
        }
    }
    
    //start/stop
    private func startAltitudeData(){
        if CMAltimeter.isRelativeAltitudeAvailable(){
            self.altitudeSensor.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: {
                data, error in
                if error != nil{
                    print("Error occurs within altitude sensor.")
                }
                if let dataTemp = data{
                    self.realTimeData.sensorData.altitudeData = dataTemp
                }
            })
        }
        else{
            print("Altitude sensor is not available.")
        }
    }
    
    private func stopAltitudeData(){
        if CMAltimeter.isRelativeAltitudeAvailable(){
            CMAltimeter.init().stopRelativeAltitudeUpdates()
        }
    }
    
    //get ambient light brightbess value from camera
    private func startGetAmbientLightValue(){
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted) in
            if granted && AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == AVAuthorizationStatus.authorized{
                //input of camera
                if let cameraDevice = AVCaptureDevice.default(for: AVMediaType.video){
                    do{
                        let deviceInput = try AVCaptureDeviceInput.init(device: cameraDevice)
                        if self.session.canAddInput(deviceInput){
                            self.session.addInput(deviceInput)
                        }
                    }catch{
                        print("Error occurs during start recording audio.")
                    }
                }

                //ouput of camera
                let deviceOutput = AVCaptureVideoDataOutput.init()
                deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
                if self.session.canAddOutput(deviceOutput){
                    self.session.addOutput(deviceOutput)
                }
                self.session.startRunning()
            }
            else{
                print("Camera is not available.")
            }
        }
    }
    private func stopCaptureSession(){
        session.stopRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let metaDataDict = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        let metaData = NSMutableDictionary.init(dictionary: metaDataDict!)
        let exifMetaData = metaData.object(forKey: kCGImagePropertyExifDictionary) as! NSDictionary
        let brightness = exifMetaData.object(forKey: kCGImagePropertyExifBrightnessValue) as! Double
        self.realTimeData.sensorData.ambientLight = brightness
    }
    
    private func startRecordAudio(){
        let audioSetting = [AVSampleRateKey : Float(8000.0),
                            AVFormatIDKey : Int32(kAudioFormatMPEG4AAC),
                            AVNumberOfChannelsKey : 1,
                            AVEncoderAudioQualityKey : Int32(AVAudioQuality.medium.rawValue)] as [String : Any]
        self.audioSession.requestRecordPermission { (granted) in
            if granted{
                var recordURL = self.createAudioURL()
                if recordURL == nil{
                    recordURL = URL.init(fileURLWithPath: "dev/null")
                }
                do{
                    try self.audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
                    try self.audioRecorder = AVAudioRecorder(url: recordURL!, settings: audioSetting)
                    self.audioRecorder.delegate = self
                    self.audioRecorder.isMeteringEnabled = true
                    self.audioRecorder.prepareToRecord()
                }catch let error as NSError{
                    print(error)
                    return
                }
                if !self.audioRecorder.isRecording{
                    do{
                        try self.audioSession.setActive(true)
                        self.audioRecorder.record()
                        self.audioURL = nil
                    }catch{
                        print("Cann't enable audio record session.")
                    }
                }
            }
            else{
                print("Audio is not availible")
            }
        }
    }
    
    private func stopRecordAudio(){
        if audioRecorder != nil && audioRecorder.isRecording{
            audioRecorder.stop()
            do{
                try self.audioSession.setActive(false)
            }catch{
                print("Cann't disable audio record session.")
            }
        }
    }
    
    private func createAudioURL() -> URL?{
        var result : URL?
        if let currentFolder = Utils.getDocumentURL(){
            let audioName = "Audio.m4a"
            result = currentFolder.appendingPathComponent(audioName)
        }else{
            result = nil
        }
        
        return result
    }
    
    public func getWifiSSID() -> String{
        var result : String = "NoWifi"
        let network = NetworkInfo()
        if let wifiSSID = network.getWifiSSID(){
            result = wifiSSID
        }else{
            //print("No wifi connected.")
        }
        
        return result
    }
    
    public func getWifiStrength() -> Int{
        return Int(NetworkInfo.getWifiStrength())
    }
    //var cnManagers : [CBCentralManager] = []
    private func startScanPeripheral(){
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
                    self.cbCentralManager.scanForPeripherals(withServices: [self.cbuuid], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
                    self.realTimeData.sensorData.bleState = "PowerOn"
                default:
                    break
                }
            })
            RunLoop.main.add(timerBLEDevice, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    private func stopScanPeripheral(){
        if timerBLEDevice != nil{
            timerBLEDevice.invalidate()
            timerBLEDevice = nil
        }
        if cbCentralManager != nil{
            cbCentralManager.stopScan()
            for peripheral in peripheralDevices{
                cbCentralManager.cancelPeripheralConnection(peripheral)
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            self.realTimeData.sensorData.bleState = "PowerOn"
            if self.cbCentralManager.isScanning{
                cbCentralManager.stopScan()
            }
            cbCentralManager.scanForPeripherals(withServices: [cbuuid], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        case .poweredOff:
            self.realTimeData.sensorData.bleState = "PoweredOff"
        case .resetting:
            self.realTimeData.sensorData.bleState = "Resetting"
        case .unauthorized:
            self.realTimeData.sensorData.bleState = "Unauthorized"
        case .unsupported:
            self.realTimeData.sensorData.bleState = "Unsupported"
        default:
            self.realTimeData.sensorData.bleState = "Unknown"
            break
        }
    }
    
    let cbuuid = CBUUID.init(string: "0xFEA7")
    
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
        //print(bleUUID)
        let bleRSSI = RSSI.intValue
        let bleDevice = BLEDeviceData.init(name: bleName, uuid: bleUUID, state: bleState, rssi: bleRSSI)
        
        updateBLEDeviceDate(inputBleDevice: bleDevice)
        if !peripheralDevices.contains(peripheral) {
            self.peripheralDevices.append(peripheral)//Strong reference
        }
    }
    
    private func updateBLEDeviceDate(inputBleDevice : BLEDeviceData){
        //If exist same device, update its information.
        var currentIndex = -1
        for ii in 0..<realTimeData.sensorData.bleDevicesData.count{
            if realTimeData.sensorData.bleDevicesData[ii].uuid == inputBleDevice.uuid{
                currentIndex = ii
            }
        }
        if currentIndex >= 0{
            realTimeData.sensorData.bleDevicesData.remove(at: currentIndex)
        }
        realTimeData.sensorData.bleDevicesData.append(inputBleDevice)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error == nil{
            //print("Discover services in device.")
            for service in peripheral.services!{
                peripheral.discoverCharacteristics(nil, for: service)
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
    
    private func startUpdateLocation(){
        if locationManager == nil {
            locationManager = CLLocationManager.init()
            locationManager.delegate = self
        }
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func stopUpdateLocation(){
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways{
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !locations.isEmpty{
            self.realTimeData.sensorData.location = locations[0].coordinate
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    // start collect proximity staus using NotificationCenter
    private func startProximityStatus(){
        let curDevice = UIDevice.current
        let isOpend = curDevice.isProximityMonitoringEnabled
        if !isOpend{
            curDevice.isProximityMonitoringEnabled = true
        }
        let defaultCenter = NotificationCenter.default
        defaultCenter.addObserver(self, selector: #selector(self.proximityStateDidChange), name: Notification.Name.UIDeviceProximityStateDidChange, object: nil)
    }
    
    // stop collect proximity status
    private func stopProximityStatus(){
        let curDevice = UIDevice.current
        let isOpend = curDevice.isProximityMonitoringEnabled
        if isOpend{
            curDevice.isProximityMonitoringEnabled = false
        }
    }
    
    // listen the state change of proximity sensor.
    @objc func proximityStateDidChange(){
        let curDevice = UIDevice.current
        if curDevice.proximityState{
            realTimeData.sensorData.proximityStatus = "Closing."
        }
        else{
            realTimeData.sensorData.proximityStatus = "Leaving."
        }
    }
}
