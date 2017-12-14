//
//  RealTimeDate.swift
//  SensorInfo
//
//  Created by utrc on 13/10/2017.
//  Copyright © 2017 utrc. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation

enum MotionActivity : String{
    case Stationary = "Stationary"
    case Walking = "Walking"
    case Cycling = "Cycling"
    case Running = "Running"
    case Automotive = "Automotive"
    case Unkown = "Unkown"
}

struct BLEDeviceData{
    var name : String
    var uuid : String
    var state : String
    var rssi : Int
}

class SensorData{
    init() {
        accelerometerData = CMAcceleration.init()
        gyroscopeData = CMRotationRate.init()
        magnetometerData = CMMagneticField.init()
        pedometerData = CMPedometerData.init()
        location = CLLocationCoordinate2D.init()
        altitudeData = nil
        shakeStatus  = "No Shake"
        shakeTimes = 0
        activity = MotionActivity.Unkown
        confidence = "Low"
        proximityStatus  = "Leaving"
        ambientLight = 0.0
        audioData = 0.0
        wifiSSID = ""
        wifiStrength = 0
        bleState = "Power Off"
        bleDevicesData = []
    }
    
    init(another : SensorData) {
        self.accelerometerData = another.accelerometerData
        self.gyroscopeData = another.gyroscopeData
        self.magnetometerData = another.magnetometerData
        self.pedometerData = another.pedometerData.copy() as! CMPedometerData
        self.altitudeData = another.altitudeData?.copy() as? CMAltitudeData
        self.location = another.location
        self.shakeStatus = another.shakeStatus
        self.shakeTimes = another.shakeTimes
        self.activity = another.activity
        self.confidence = another.confidence
        self.proximityStatus = another.proximityStatus
        self.ambientLight = another.ambientLight
        self.audioData = another.audioData
        self.wifiSSID = another.wifiSSID
        self.wifiStrength = another.wifiStrength
        self.bleState = another.bleState
        self.bleDevicesData = another.bleDevicesData
    }
    
    var accelerometerData : CMAcceleration
    var gyroscopeData : CMRotationRate
    var magnetometerData : CMMagneticField
    var pedometerData : CMPedometerData
    var altitudeData : CMAltitudeData?
    var location : CLLocationCoordinate2D
    var shakeStatus : String
    var shakeTimes : Int
    var activity : MotionActivity
    var confidence : String
    var proximityStatus : String
    var ambientLight : Double
    var audioData : Double
    var wifiSSID : String
    var wifiStrength : Int
    var bleState : String
    var bleDevicesData : [BLEDeviceData]
    
    public func printSensorData(givenOrder : [String]? = nil) -> ([String], [String]){
        var resultSensorList : [String] = []
        var resultSensorData : [String] = []
        var sensorValue = "No Value"
        
        //AccelerometerX
        resultSensorList.append("AccelerometerX")
        sensorValue = String(self.accelerometerData.x)
        resultSensorData.append(sensorValue)
        //AccelerometerY
        resultSensorList.append("AccelerometerY")
        sensorValue = String(self.accelerometerData.y)
        resultSensorData.append(sensorValue)
        //AccelerometerZ
        resultSensorList.append("AccelerometerZ")
        sensorValue = String(self.accelerometerData.z)
        resultSensorData.append(sensorValue)
        //GyroscopeX
        resultSensorList.append("GyroscopeX")
        sensorValue = String(self.gyroscopeData.x)
        resultSensorData.append(sensorValue)
        //GyroscopeY
        resultSensorList.append("GyroscopeY")
        sensorValue = String(self.gyroscopeData.y)
        resultSensorData.append(sensorValue)
        //GyroscopeZ
        resultSensorList.append("GyroscopeZ")
        sensorValue = String(self.gyroscopeData.z)
        resultSensorData.append(sensorValue)
        //MegnetometerX
        resultSensorList.append("MagnetometerX")
        sensorValue = String(self.magnetometerData.x)
        resultSensorData.append(sensorValue)
        //MegnetometerY
        resultSensorList.append("MagnetometerY")
        sensorValue = String(self.magnetometerData.y)
        resultSensorData.append(sensorValue)
        //MegnetometerZ
        resultSensorList.append("MagnetometerZ")
        sensorValue = String(self.magnetometerData.z)
        resultSensorData.append(sensorValue)
        //Location
        resultSensorList.append("Location")
        sensorValue = "(" + String(location.longitude) + "," + String(location.latitude) + ")"
        resultSensorData.append(sensorValue)
        //Steps
        resultSensorList.append("Steps")
        sensorValue = String(self.pedometerData.numberOfSteps.intValue)
        resultSensorData.append(sensorValue)
        //Distance
        resultSensorList.append("Distance")
        if let distance = self.pedometerData.distance{
            sensorValue = distance.stringValue
        }else{
            sensorValue = "No Value"
        }
        resultSensorData.append(sensorValue)
        //CurrentPace
        resultSensorList.append("CurrentPace")
        if let currentPace = self.pedometerData.currentPace{
            sensorValue = currentPace.stringValue
        }else{
            sensorValue = "No Value"
        }
        resultSensorData.append(sensorValue)
        //Motion activity
        resultSensorList.append("Activity")
        resultSensorData.append(self.activity.rawValue)
        resultSensorList.append("Confidence")
        resultSensorData.append(self.confidence)
        //ShakeStatus
        resultSensorList.append("ShakeStatus")
        sensorValue = self.shakeStatus
        resultSensorData.append(sensorValue)
        //ShakeTimes
        resultSensorList.append("ShakeTimes")
        sensorValue = String(self.shakeTimes)
        resultSensorData.append(sensorValue)
        //ProximityStatus
        resultSensorList.append("ProximityStatus")
        sensorValue = self.proximityStatus
        resultSensorData.append(sensorValue)
        //AmbientLight
        resultSensorList.append("AmbientLight")
        sensorValue = String(self.ambientLight)
        resultSensorData.append(sensorValue)
        //RelativeAltitude
        resultSensorList.append("RelativeAltitude")
        if let altitudeData = self.altitudeData{
            sensorValue = altitudeData.relativeAltitude.stringValue
        }else{
            sensorValue = "No Value"
        }
        resultSensorData.append(sensorValue)
        //Pressure
        resultSensorList.append("Pressure")
        if let altitudeData = self.altitudeData{
            sensorValue = altitudeData.pressure.stringValue
        }
        resultSensorData.append(sensorValue)
        //Audio decibel data
        resultSensorList.append("Audio Decibel")
        resultSensorData.append(String(audioData))
        //WifiSSID
        resultSensorList.append("WifiSSID")
        sensorValue = self.wifiSSID
        resultSensorData.append(sensorValue)
        //WifiStrength
        resultSensorList.append("WifiStrength")
        sensorValue = String(self.wifiStrength)
        resultSensorData.append(sensorValue)
        //BLEStatus
        resultSensorList.append("BLEStatus")
        sensorValue = String(self.bleState)
        resultSensorData.append(sensorValue)
        //BLEDevice data
        bleDevicesData.sort { (first, second) -> Bool in
            if first.uuid < second.uuid{
                return true
            }else{
                return false
            }
        }
        for bleDevice in bleDevicesData{
            resultSensorList.append(bleDevice.uuid)
            resultSensorData.append(String(bleDevice.rssi))
        }
        
        return (resultSensorList, resultSensorData)
    }
}

class RealTimeData{
    init() {
        recordTime = Date.init()
        sensorData = SensorData.init()
    }
    
    init(another : RealTimeData) {
        self.recordTime = Date.init()
        self.sensorData = SensorData.init(another: another.sensorData)
    }
    var recordTime : Date
    var sensorData : SensorData
    
    public func printRealtimeData() -> ([String], [String]){
        var resultName : [String] = []
        var resultValue : [String] = []
        //Add record time information
        resultName.append("TimeStamp")
        resultValue.append(String(recordTime.timeIntervalSince1970 * 1000))
        //Add sensor data information
        let (sensorName, sensorValue) = sensorData.printSensorData()
        resultName.append(contentsOf: sensorName)
        resultValue.append(contentsOf: sensorValue)
        
        return (resultName, resultValue)
    }
    
    public func printRealtimeDataWithFormat() -> ([String], [String]){
        var resultName : [String] = []
        var resultValue : [String] = []
        //Add record time information
        resultName.append("TimeStamp")
        let formatter = Utils.getDataFormatter()
        resultValue.append(formatter.string(from: recordTime))
        //Add sensor data information
        let (sensorName, sensorValue) = sensorData.printSensorData()
        resultName.append(contentsOf: sensorName)
        resultValue.append(contentsOf: sensorValue)
        
        return (resultName, resultValue)
    }
}
