//
//  SensorInformation.swift
//  SensorInfo
//
//  Created by utrc on 28/08/2017.
//  Copyright © 2017 utrc. All rights reserved.
//

import UIKit
import Foundation
import CoreMotion

enum Frequency : String {
    case HZ_1 = "1 HZ"
    case HZ_10 = "10 HZ"
    case HZ_20 = "20 HZ"
    case HZ_50 = "50 HZ"
    case HZ_100 = "100 HZ"
}

class SensorDataCollector: UIResponder{
    
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

    private let motionManager = CMMotionManager.init()
    private let motionActivityManager = CMMotionActivityManager.init()
    private let pedometer = CMPedometer.init()
    private let altitudeSensor = CMAltimeter.init()
    private let mediaRecorder = MediaRecorder.init()
    private let bluetoothMonitor = BluetoothMonitor.init()
    
    private var timeIntervalUpdate = 1.0 / 10.0
    private var refreshTimer : Timer!
    
    //init setting
    private func initSetting(){
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
        mediaRecorder.updateAmbientLight()
        mediaRecorder.startRecordAudio()
        bluetoothMonitor.startScanPeripheral()
        startProximityStatus()
        
        if refreshTimer != nil{
            refreshTimer.fire()
        }
        else{
            //new refresh timer
            self.refreshTimer = Timer.init(fire: Date.init(), interval: timeIntervalUpdate, repeats: true, block: { (freshTimer) in
                self.fillRealtimeData()
            })
            RunLoop.main.add(refreshTimer, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    public func stopCollectSensorData(){
        endTime = Date.init()
        
        stopUpdateMotionSensor()
        stopPedometerData()
        stopAltitudeData()
        mediaRecorder.stopCaptureSession()
        mediaRecorder.stopRecordAudio()
        stopProximityStatus()
        bluetoothMonitor.stopScanPeripheral()
        if refreshTimer != nil{
            refreshTimer.invalidate()
            refreshTimer = nil
        }
        
        isRunning = false
    }
    
    private func fillRealtimeData(){
        self.realTimeData.recordTime = Date.init()
        self.realTimeData.sensorData.wifiSSID = self.getWifiSSID()
        self.realTimeData.sensorData.wifiStrength = self.getWifiStrength()
        
        //get the motion sensor data
        /*
         if let data = self.motionManager.accelerometerData{
         self.realTimeData.sensorData.accelerometerData = data.acceleration
         }
         if let data = self.motionManager.gyroData{
         self.realTimeData.sensorData.gyroscopeData = data.rotationRate
         }*/
        if let data = self.motionManager.magnetometerData{
            self.realTimeData.sensorData.magnetometerData = data.magneticField
        }
        
        if let motionData = motionManager.deviceMotion{
            self.realTimeData.sensorData.accelerometerData = motionData.userAcceleration
            self.realTimeData.sensorData.gyroscopeData = motionData.rotationRate
        }
        //bluetooth data
        self.realTimeData.sensorData.bleState = bluetoothMonitor.bleState
        self.realTimeData.sensorData.bleDevicesData = bluetoothMonitor.bleDevicesData
        
        //fill media data
        self.realTimeData.sensorData.ambientLight = mediaRecorder.ambientLight
        self.realTimeData.sensorData.audioData = mediaRecorder.getAudiodecibel()
    }
    
    public func getRealtimeSensorData() -> ([String], [String]){
        return self.realTimeData.printRealtimeDataWithFormat()
    }
    
    //start/stop collecting data of motion sensor
    private func startUpdateMotionSensor(){
        //usage of core motion manager
        /*
         if self.motionManager.isAccelerometerAvailable{
         self.motionManager.accelerometerUpdateInterval = timeIntervalUpdate
         self.motionManager.startAccelerometerUpdates()
         }
         if self.motionManager.isGyroAvailable {
         self.motionManager.gyroUpdateInterval = timeIntervalUpdate
         self.motionManager.startGyroUpdates()
         }*/
        if self.motionManager.isMagnetometerAvailable{
            self.motionManager.magnetometerUpdateInterval = timeIntervalUpdate
            self.motionManager.startMagnetometerUpdates()
        }
        
        if self.motionManager.isDeviceMotionAvailable{
            self.motionManager.deviceMotionUpdateInterval = timeIntervalUpdate
            self.motionManager.startDeviceMotionUpdates()
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
        if CMPedometer.isStepCountingAvailable() && CMPedometer.isPaceAvailable(){
            self.pedometer.startUpdates(from: Date.init(), withHandler: { data, error in
                if (error != nil){
                    print(error.debugDescription)
                }
                if let tempData = data{
                    self.realTimeData.sensorData.pedometerData = tempData
                }
            })
        }
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
                    return
                }
                if let dataTemp = data{
                    self.realTimeData.sensorData.altitudeData = dataTemp
                }
            })
        }
        else{
            let infoStr = "Altitude sensor is not available."
            print(infoStr)
        }
    }
    
    private func stopAltitudeData(){
        if CMAltimeter.isRelativeAltitudeAvailable(){
            CMAltimeter.init().stopRelativeAltitudeUpdates()
        }
    }
    
    public func getWifiSSID() -> String{
        var result : String = "NoWifi"
        let network = NetworkInfo()
        
        if let wifiSSID = network.getWifiSSID(){
            result = wifiSSID
        }else{
            //NSLog("No wifi connected.")
        }
        
        return result
    }
    
    public func getWifiStrength() -> Int{
        return Int(NetworkInfo.getWifiStrength())
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
