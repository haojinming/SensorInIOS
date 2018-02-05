//
//  LocationMonitor.swift
//  SeamlessDemo
//
//  Created by utrc on 08/01/2018.
//  Copyright © 2018 utrc. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreLocation

class LocationMonitor: NSObject, CLLocationManagerDelegate {
    static let shared = LocationMonitor.init()
    
    private let ibeaconUUID = UUID.init(uuidString: "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6")
    private let ibenconID = "UTRCCiBeacon"
    private var beaconRegion : CLBeaconRegion!
    private var gpsRegion = CLCircularRegion.init(center: CLLocationCoordinate2D.init(latitude: 31.2144306008859, longitude: 121.558803991872), radius: 5.0, identifier: "UTRCCOffice_GPS")
    
    private var monitorIBeacon = false
    private var monitorGPSLocation = false
    private var locationManager : CLLocationManager!
    
    override init() {
        super.init()
        locationManager = CLLocationManager.init()
        locationManager.delegate = self
    }
    
    public func startMonitorGPSLocation(){
        monitorIBeacon = false
        monitorGPSLocation = true
        if locationManager.allowsBackgroundLocationUpdates != true{
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
            let infoStr = "Request Authorization for monitor gps."
            print(infoStr)
        }else{
            locationManager.startMonitoring(for: gpsRegion)
        }
    }
    
    public func startMonitorBeacon(){
        monitorIBeacon = true
        monitorGPSLocation = false
        
        if beaconRegion == nil {
            beaconRegion = CLBeaconRegion.init(proximityUUID: ibeaconUUID!, identifier: ibenconID)
        }
        if locationManager.allowsBackgroundLocationUpdates != true{
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
            let infoStr = "Request authorization for monitor beacon."
            print(infoStr)
        }else{
            locationManager.startMonitoring(for: beaconRegion)
        }
    }
    
    public func stopMonitorGPSLocation(){
        if locationManager != nil{
            locationManager.stopMonitoring(for: gpsRegion)
        }
    }
    
    public func stopMonitorBeacon(){
        if locationManager != nil{
            locationManager.stopMonitoring(for: beaconRegion)
            for item in locationManager.rangedRegions{
                locationManager.stopRangingBeacons(in: item as! CLBeaconRegion)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
             print(location.altitude)
             print(location.coordinate.latitude)
             print(location.coordinate.longitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print(error)
        let infoStr = String.init(describing: error)
        print(infoStr)
    }
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print(error)
        let infoStr = String.init(describing: error)
        print(infoStr)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let infoStr = "Enter region: " + region.identifier
        print(infoStr)
        
        //locationManager.startRangingBeacons(in: self.beaconRegion)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let infoStr = "Exit region: " + region.identifier
        print(infoStr)
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        let infoStr = "StartMonitor: " + region.identifier
        print(infoStr)
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        let infoStr = "location resume loacation update."
        print(infoStr)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        for item in beacons {
            var infoStr = ""
            switch item.proximity{
            case .far:
                infoStr += "Far: "
            case .immediate:
                infoStr += "Immediate: "
            case .near:
                infoStr += "Near: "
            default:
                infoStr += "Unkown: "
            }
            infoStr += item.proximityUUID.uuidString
            infoStr += String(item.rssi)
            print(infoStr)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        var infoStr = region.identifier + ":"
        switch state {
        case .inside:
            infoStr += "Inside"
            //locationManager.startRangingBeacons(in: self.beaconRegion)
        case .outside:
            infoStr += "Outside"
        default:
            infoStr += "Unkown"
        }
        print(infoStr)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse{
            if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) && monitorGPSLocation{
                //locationManager.startUpdatingLocation()
                let infoStr = "Get authorization, start monitor gps location."
                print(infoStr)
                locationManager.startMonitoring(for: self.gpsRegion)
            }
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) && monitorIBeacon{
                let infoStr = "Get authorization, start monitor iBeacon."
                print(infoStr)
                locationManager.startMonitoring(for: self.beaconRegion)
                locationManager.startRangingBeacons(in: self.beaconRegion)
            }
        }
    }
}
