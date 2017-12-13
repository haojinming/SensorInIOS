//
//  ViewController.swift
//  SensorInPhone
//
//  Created by utrc on 13/12/2017.
//  Copyright © 2017 utrc. All rights reserved.
//

import UIKit

class DataViewController: UITableViewController {

    let sensorDataCollector = SensorDataCollector.shared
    var sensorNameList : [String] = []
    var sensorValueList : [String] = []
    var refreshTimer : Timer!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if self.canBecomeFirstResponder{
            self.becomeFirstResponder()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startUpdateSensorData(){
        sensorDataCollector.startCollectSensorData()
        if refreshTimer != nil{
            refreshTimer.fire()
        }else{
            refreshTimer = Timer.init(timeInterval: 0.1, repeats: true, block: { (refreshTimer) in
                (self.sensorNameList, self.sensorValueList) = self.sensorDataCollector.getRealtimeSensorData()
                if self.sensorNameList.count != self.sensorValueList.count{
                    print("Error occurs.")
                    self.sensorNameList = []
                    self.sensorValueList = []
                }
                self.tableView.reloadData()
            })
            RunLoop.main.add(refreshTimer, forMode: RunLoopMode.defaultRunLoopMode)
        }
    }
    
    @IBAction func stopUpdateSensorData(){
        if refreshTimer != nil{
            refreshTimer.invalidate()
            refreshTimer = nil
        }
        sensorDataCollector.stopCollectSensorData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sensorNameList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: .value1, reuseIdentifier: "SensorDataCell")
        if indexPath.row < sensorNameList.count{
            cell.textLabel?.text = sensorNameList[indexPath.row]
            cell.detailTextLabel?.text = sensorValueList[indexPath.row]
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.endEditing(true)
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        sensorDataCollector.setShakeStatus(status: "ShakeBegan")
    }
    
    override func motionCancelled(_ motion: UIEventSubtype, with event: UIEvent?) {
        sensorDataCollector.setShakeStatus(status: "ShakeCancelled")
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        sensorDataCollector.setShakeStatus(status: "ShakeEnded")
        sensorDataCollector.setShakeTimes(times: sensorDataCollector.getShakeTimes() + 1)
    }
}

