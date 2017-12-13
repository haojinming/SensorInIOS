//
//  Utils.swift
//  SensorInfo
//
//  Created by utrc on 29/08/2017.
//  Copyright © 2017 utrc. All rights reserved.
//

import Foundation

enum SettingKey : String{
    case Frequency = "Frequency"
}
class Utils: NSObject {
    override init() {
    }

    class public func getDocumentURL() -> URL?{
        var result : URL?
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        if urls.count > 0 {
            result = urls[0]
        }else{
            result = nil
        }
        return result
    }
    
    class public func createFolderInDocument(folderName : String) -> URL?{
        var result : URL?
        let fileManager = FileManager.default
        if let docURL = getDocumentURL(){
            let newFolder = docURL.appendingPathComponent(folderName)
            do{
                try fileManager.createDirectory(at: newFolder, withIntermediateDirectories: true, attributes: nil)
                result = newFolder
            }catch{
                result = nil
            }
        }
        return result
    }
    
    class public func getDataFormatter() -> DateFormatter{
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        return formatter
    }
    
    class func deleteFile(file : URL){
        if !file.isFileURL{
            return
        }
        let manager = FileManager.default
        do{
            try manager.removeItem(at: file)
        }catch{
            print("Given file or folder cannot be deleted.")
        }
    }
}
