//
//  SimpleThingsController.swift
//  Server
//
//  Created by Khaos Tian on 1/24/15.
//  Copyright (c) 2015 Khaos Tian. All rights reserved.
//

import Foundation

class SimpleThingsController: NSObject {
    
    var selectorTable = ["pressButton": pressButton]
    
    var strings = ["Hello Meow~", "Woof!", "Such Wow!"]
    var currentIndex: Int = 0;
    
    func didGetNewUpdate([Transaction]) {
        
    }
    
    func pressButton() {
        NSLog("Did Press Button")
        var trans = Transaction(tp: .UI)
        trans.viewName = "textLabel"
        trans.viewProperty = "text"
        trans.viewValue = strings[currentIndex]
        currentIndex += 1
        if currentIndex > 2 {
            currentIndex = 0
        }
        CommunicationCore.sharedInstance.emitTransaction(trans)
    }
    
    func updateCells(value: Float?) {
        NSLog("updateCells")
        if let value = value {
            if value > 0 {
                var trans = Transaction(tp: .List)
                var items = [String]()
                for index in 1...Int(value) {
                    items.append("Item \(index)")
                }
                trans.listItems = items
                CommunicationCore.sharedInstance.emitTransaction(trans)
            }
        }
    }
}