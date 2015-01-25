//
//  CommunicationCore.swift
//  Server
//
//  Created by Khaos Tian on 1/24/15.
//  Copyright (c) 2015 Khaos Tian. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol CommunicationCoreProtocol: class {
    func didGetNewUpdate([Transaction])
    func didEstablishTheConnection()
}

class Transaction {
    enum Type: Int {
        case UI = 0
        case Action
        case List
        case Unknown
    }
    
    var type: Type
    
    var actionSelector: String?
    var actionValue: Float?
    
    var viewName: String?
    var viewProperty: String?
    var viewValue: String?
    
    var listItems: [String]?
    
    init(tp: Type) {
        self.type = tp
    }
    
    init(data: NSData) {
        var dict: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: nil)!
        self.type = .Unknown
        if let info = dict as? [String: NSObject] {
            if let infoT = info["t"] {
                switch infoT {
                case "A":
                    self.type = .Action
                    self.actionSelector = info["a"] as? String
                    self.actionValue = info["av"] as? Float
                case "I":
                    self.type = .UI
                    self.viewName = info["n"] as? String
                    self.viewProperty = info["p"] as? String
                    self.viewValue = info["v"] as? String
                case "L":
                    self.type = .List
                    if let items = info["li"]{
                        self.listItems = items as? [String]
                    }
                default:
                    self.type = .Unknown
                }
            }
        }
        
    }
    
    func dataPresentation() -> NSData {
        var pendingDict = [String: AnyObject]()
        switch self.type {
        case .Action:
            pendingDict["t"] = "A"
            pendingDict["a"] = actionSelector!
            if let value = self.actionValue {
                pendingDict["av"] = actionValue
            }
        case .UI:
            pendingDict["t"] = "I"
            pendingDict["n"] = viewName!
            pendingDict["p"] = viewProperty!
            pendingDict["v"] = viewValue!
        case .List:
            pendingDict["t"] = "L"
            pendingDict["li"] = listItems!
        default:
            pendingDict["t"] = "U"
        }
        return NSJSONSerialization.dataWithJSONObject(pendingDict, options: NSJSONWritingOptions.allZeros, error: nil)!
    }
}

class TransmitSession {
    var pendingData: NSData
    var offset: Int
    var maxSize: Int
    
    init(data: NSData, maxSize: Int = 18) {
        self.offset = 0
        self.pendingData = data.copy() as NSData
        self.maxSize = maxSize
    }
    
    func nextChunck() -> NSData? {
        if offset < pendingData.length {
            let nextChunckSize = pendingData.length - offset > maxSize ? maxSize : pendingData.length - offset
            let transmitData = pendingData.subdataWithRange(NSRange(location: self.offset,length: nextChunckSize))
            return transmitData
        } else {
            return nil
        }
    }
    
    func updateOffset() {
        self.offset += self.maxSize
    }
}

class CommunicationCore: NSObject, CBPeripheralManagerDelegate {
    weak var delegate: CommunicationCoreProtocol?
    var peripheralManager: CBPeripheralManager?
    
    var readyToAdvertise: Bool = false
    var isAdvertising: Bool = false
    
    var dataCharacteristic: CBMutableCharacteristic?
    var actionCharacteristic: CBMutableCharacteristic?
    var watchService: CBMutableService?
    
    var transmitSession: TransmitSession?
    
    var newData: Bool = false
    
    var centralMTU: Int = 18
    var beginData = NSData(bytes: [0x40,0x4E,0x44,0x56,0x41,0x4C] as [Byte], length: 6)
    var endData = NSData(bytes: [0x45,0x4E,0x44,0x56,0x41,0x4C] as [Byte], length: 6)
    
    class var sharedInstance: CommunicationCore {
        struct Singleton {
            static let instance = CommunicationCore()
        }
        
        return Singleton.instance
    }
    
    override init() {
        super.init()
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: dispatch_queue_create("org.oltica.peripheralQueue", DISPATCH_QUEUE_SERIAL))
    }
    
    func preparePeripheralSetup() {
        if !readyToAdvertise {
            self.dataCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "838B5F98-B275-4722-85CF-EA0A3913246B"), properties: CBCharacteristicProperties.Notify, value: nil, permissions: CBAttributePermissions.Readable)
            self.actionCharacteristic = CBMutableCharacteristic(type: CBUUID(string: "EC0C4C88-3942-47B0-A102-9DC6E4E40C62"), properties: CBCharacteristicProperties.Write | CBCharacteristicProperties.WriteWithoutResponse, value: nil, permissions: CBAttributePermissions.Writeable)
            self.watchService = CBMutableService(type: CBUUID(string: "ED488CF4-9802-4BF8-B2C9-0F46ABC80CF7"), primary: true)
            self.watchService!.characteristics = [self.dataCharacteristic!,self.actionCharacteristic!]
            self.peripheralManager?.addService(self.watchService!)
        }
    }
    
    func startAdvertising() {
        if readyToAdvertise && !isAdvertising {
            self.isAdvertising = true
            let dict = [CBAdvertisementDataServiceUUIDsKey:[CBUUID(string: "ED488CF4-9802-4BF8-B2C9-0F46ABC80CF7")]]
            self.peripheralManager?.startAdvertising(dict)
        }
    }
    
    func stopAdvertising() {
        if isAdvertising {
            self.isAdvertising = false
            self.peripheralManager?.stopAdvertising()
        }
    }
    
    func emitTransaction(tran: Transaction) {
        self.newData = true
        var pendingData = tran.dataPresentation()
        self.transmitSession = TransmitSession(data: pendingData, maxSize: centralMTU)
        self.writeData()
    }
    
    func writeData() {
        if let session = self.transmitSession {
            if self.newData {
                if self.peripheralManager!.updateValue(self.beginData, forCharacteristic: self.dataCharacteristic!, onSubscribedCentrals: nil) {
                    self.newData = false
                }
            }
            while let data = session.nextChunck() {
                if let peripheralManager = self.peripheralManager {
                    if peripheralManager.updateValue(data, forCharacteristic: self.dataCharacteristic!, onSubscribedCentrals: nil) {
                        session.updateOffset()
                    } else {
                        return
                    }
                }
            }
            if self.peripheralManager!.updateValue(self.endData, forCharacteristic: self.dataCharacteristic!, onSubscribedCentrals: nil) {
                self.transmitSession = nil
                NSLog("Finished Writing Data")
            }
        }
    }
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        if peripheral.state == CBPeripheralManagerState.PoweredOn {
            NSLog("Peripheral Manager is ready!")
            self.preparePeripheralSetup()
        }
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager!, error: NSError!) {
        if error == nil {
            NSLog("Peripheral Manager started advertising")
        } else {
            self.isAdvertising = false
            NSLog("Peripheral Manager failed advertising, error: \(error)")
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didAddService service: CBService!, error: NSError!) {
        if error == nil {
            self.readyToAdvertise = true
            NSLog("Peripheral Manager did add service")
        } else {
            self.readyToAdvertise = false
            NSLog("Peripheral Manager failed adding service, error: \(error)")
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, central: CBCentral!, didSubscribeToCharacteristic characteristic: CBCharacteristic!) {
        NSLog("New Central:\(central),MTU:\(central.maximumUpdateValueLength)")
        self.centralMTU = central.maximumUpdateValueLength
        peripheral.setDesiredConnectionLatency(CBPeripheralManagerConnectionLatency.Low, forCentral: central)
        self.delegate?.didEstablishTheConnection()
    }
    
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager!) {
        self.writeData()
    }
    
    func peripheralManager(peripheral: CBPeripheralManager!, didReceiveWriteRequests requests: [AnyObject]!) {
        NSLog("didReceiveWriteRequests:")
        var transactions = [Transaction]()
        for request in requests as [CBATTRequest] {
            var trans = Transaction(data: request.value)
            transactions.append(trans)
            peripheral.respondToRequest(request, withResult: CBATTError.Success)
        }
        self.delegate?.didGetNewUpdate(transactions)
    }
}