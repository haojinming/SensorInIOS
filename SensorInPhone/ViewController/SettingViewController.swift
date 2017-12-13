//
//  SettingViewController.swift
//  SensorInPhone
//
//  Created by utrc on 13/12/2017.
//  Copyright © 2017 utrc. All rights reserved.
//

import UIKit

class SettingViewController: UITableViewController {
    
    let userDefault = UserDefaults.init()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func updateUI(){
        var frequency = "10_HZ"
        if let fre = self.userDefault.string(forKey: SettingKey.Frequency.rawValue){
            frequency = fre
        }
        if let frequencyCell = tableView.cellForRow(at: IndexPath.init(row: 0, section: 0)){
            frequencyCell.detailTextLabel?.text = frequency
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.endEditing(true)
        if let cell = tableView.cellForRow(at: indexPath){
            if cell.tag == 0{
                let alertController = UIAlertController.init(title: SettingKey.Frequency.rawValue, message: "Set the frequence.", preferredStyle: .actionSheet)
                let frequencyList = [Frequency.HZ_1, .HZ_10, .HZ_20, .HZ_50, .HZ_100]
                for item in frequencyList{
                    let action = UIAlertAction.init(title: item.rawValue, style: .default, handler: { (action) in
                        self.userDefault.set(action.title, forKey: SettingKey.Frequency.rawValue)
                        cell.detailTextLabel?.text = action.title
                    })
                    alertController.addAction(action)
                }
                let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in
                })
                alertController.addAction(cancelAction)
                self.showDetailViewController(alertController, sender: self)
            }
        }
    }
    
    
}
