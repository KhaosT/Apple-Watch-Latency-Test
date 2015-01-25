//
//  ViewController.swift
//  Server
//
//  Created by Khaos Tian on 1/24/15.
//  Copyright (c) 2015 Khaos Tian. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CommunicationCoreProtocol {
    
    var communicationCore: CommunicationCore!
    var activeController: SimpleThingsController!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.communicationCore = CommunicationCore.sharedInstance
        self.communicationCore.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func didEstablishTheConnection() {
        self.activeController = SimpleThingsController()
    }
    
    func didGetNewUpdate(updates: [Transaction]) {
        NSLog("New Updates:\(updates)")
        for trans in updates {
            if trans.type == .Action {
                if let selectorName = trans.actionSelector {
                    if selectorName == "updateCells:" {
                        self.activeController.updateCells(trans.actionValue)
                        return
                    }
                    if let function = self.activeController.selectorTable[selectorName] {
                        function(self.activeController)()
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

