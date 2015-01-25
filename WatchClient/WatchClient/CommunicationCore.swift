//
//  CommunicationCore.swift
//  WatchClient
//
//  Created by Khaos Tian on 1/24/15.
//  Copyright (c) 2015 Khaos Tian. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol CommunicationCoreProtocol: class {
    func didGetNewUpdate(updates: [Transaction])
}

protocol CommunicationCoreAvailabilityProtocol: class {
    func didEstablishTheConnection()
    func didDisconnectFromServer()
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

class CommunicationCore {
    var centralManager: CBCentralManager!
    var cbDelegator: CBDelegator!
    
    weak var activeVCDelegate: CommunicationCoreProtocol?
    weak var connectionDelegate: CommunicationCoreAvailabilityProtocol?
    
    var scanning: Bool = false
    
    var serverPeripheral: CBPeripheral!
    var watchService: CBService?
    var dataChar: CBCharacteristic?
    var updateChar: CBCharacteristic?
    
    var dataBuffer = NSMutableData()
    var beginData = NSData(bytes: [0x40,0x4E,0x44,0x56,0x41,0x4C] as [Byte], length: 6)
    var endData = NSData(bytes: [0x45,0x4E,0x44,0x56,0x41,0x4C] as [Byte], length: 6)
    
    class var sharedInstance: CommunicationCore {
        struct Singleton {
            static let instance = CommunicationCore()
        }
        
        return Singleton.instance
    }
    
    class CBDelegator: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
        var delegate: CommunicationCore
        
        init(delegate: CommunicationCore) {
            self.delegate = delegate
            super.init()
        }
        
        func centralManagerDidUpdateState(central: CBCentralManager!) {
            self.delegate.centralManagerDidUpdateState(central)
        }
        
        func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
            self.delegate.centralManager(central, didDiscoverPeripheral: peripheral, advertisementData: advertisementData, RSSI: RSSI)
        }
        
        func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
            self.delegate.centralManager(central, didConnectPeripheral: peripheral)
        }
        
        func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
            self.delegate.centralManager(central, didDisconnectPeripheral: peripheral, error: error)
        }
        
        func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
            self.delegate.peripheral(peripheral, didDiscoverServices: error)
        }
        
        func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
            self.delegate.peripheral(peripheral, didDiscoverCharacteristicsForService: service, error: error)
        }
        
        func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
            self.delegate.peripheral(peripheral, didUpdateValueForCharacteristic: characteristic, error: error)
        }
        
        func peripheral(peripheral: CBPeripheral!, didWriteValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
            self.delegate.peripheral(peripheral, didWriteValueForCharacteristic: characteristic, error: error)
        }
    }
    
    init() {
        self.cbDelegator = CBDelegator(delegate: self)
        self.centralManager = CBCentralManager(delegate: self.cbDelegator, queue: dispatch_queue_create("org.oltica.CentralQueue", DISPATCH_QUEUE_SERIAL))
    }
    
    func startScan() {
        if !self.scanning {
            self.scanning = true
            var uuid = CBUUID(string: "ED488CF4-9802-4BF8-B2C9-0F46ABC80CF7")
            self.centralManager.scanForPeripheralsWithServices([uuid], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    func stopScan() {
        if self.scanning {
            self.scanning = false
            self.centralManager.stopScan()
        }
    }
    
    func emitTransaction(tran: Transaction) {
        if let updateChar = self.updateChar {
            var pendingData = tran.dataPresentation()
            self.serverPeripheral.writeValue(pendingData, forCharacteristic: updateChar, type: CBCharacteristicWriteType.WithoutResponse)
        }
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn {
            NSLog("Power On... Start Scan")
            self.startScan()
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        self.stopScan()
        NSLog("Find Periphera: \(peripheral)")
        self.serverPeripheral = peripheral
        self.centralManager.connectPeripheral(self.serverPeripheral, options: nil)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        NSLog("didConnectPeripheral:\(peripheral)")
        self.serverPeripheral.delegate = self.cbDelegator
        self.serverPeripheral.discoverServices([CBUUID(string: "ED488CF4-9802-4BF8-B2C9-0F46ABC80CF7")])
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        NSLog("didDisconnectPeripheral")
        self.connectionDelegate?.didDisconnectFromServer()
        self.startScan()
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError!) {
        NSLog("didDiscoverServices:\(error)")
        for service in peripheral.services as [CBService] {
            if service.UUID == CBUUID(string: "ED488CF4-9802-4BF8-B2C9-0F46ABC80CF7") {
                NSLog("Find Watch Service")
                self.watchService = service
                peripheral.discoverCharacteristics(nil, forService: service)
                break
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        NSLog("didDiscoverCharacteristicsForService")
        for characteristic in service.characteristics as [CBCharacteristic] {
            if characteristic.UUID == CBUUID(string: "838B5F98-B275-4722-85CF-EA0A3913246B") {
                NSLog("Find Data Char")
                self.dataChar = characteristic
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            }
            if characteristic.UUID == CBUUID(string: "EC0C4C88-3942-47B0-A102-9DC6E4E40C62") {
                NSLog("Find Update Char")
                self.updateChar = characteristic
            }
        }
        self.connectionDelegate?.didEstablishTheConnection()
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if error != nil {
            NSLog("An error encountered when updating value")
        } else {
            let newData = characteristic.value
            if newData == self.beginData {
                self.dataBuffer.length = 0
                return
            }
            if newData == self.endData{
                var trans = Transaction(data: self.dataBuffer)
                self.activeVCDelegate?.didGetNewUpdate([trans])
            } else {
                self.dataBuffer.appendData(newData)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didWriteValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        NSLog("Did Write Data")
    }
}