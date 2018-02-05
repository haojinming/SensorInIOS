//
//  NFCReader.swift
//  SeamlessDemo
//
//  Created by utrc on 19/01/2018.
//  Copyright © 2018 utrc. All rights reserved.
//

import Foundation
import CoreNFC

struct NDEFData {
    var identifier : String
    var payload : String
    var type : String
    var typeNameFormat : String
}

class NFCReader: NSObject, NFCNDEFReaderSessionDelegate {
    
    static let shared = NFCReader.init()
    
    private var messages = [NDEFData]()
    private var session : NFCNDEFReaderSession!
    var valid : Bool
    override init() {
        valid = false
        super.init()
    }
    
    public func startReadNFCTag(){
        if NFCNDEFReaderSession.readingAvailable {
            session = NFCNDEFReaderSession.init(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: false)
            session.begin()
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        valid = false
        print(error)
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        valid = true
        self.messages.removeAll()
        for message in messages {
            for item in message.records{
                var prefix = 0
                let identifier = String.init(data: item.identifier, encoding: .utf8)!
                let type = String(data: item.type, encoding: .utf8)!
                if type == "U" {
                    prefix = 1
                }else if type == "T" {
                    prefix = 3
                }
                let payload = String(data: item.payload.advanced(by: prefix), encoding: .utf8)!
                let typeNameFormat = String(item.typeNameFormat.rawValue)
                
                let ndefData = NDEFData.init(identifier: identifier, payload: payload, type: type, typeNameFormat: typeNameFormat)
                self.messages.append(ndefData)
            }
        }
    }
    
    public func getNFCData() -> [NDEFData]{
        return self.messages;
    }
}
