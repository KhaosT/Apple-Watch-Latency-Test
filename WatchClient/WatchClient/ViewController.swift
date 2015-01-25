//
//  ViewController.swift
//  WatchClient
//
//  Created by Khaos Tian on 1/24/15.
//  Copyright (c) 2015 Khaos Tian. All rights reserved.
//

import UIKit

class ViewController: UIViewController,CommunicationCoreAvailabilityProtocol {
    
    var activeController: UIViewController!
    @IBOutlet weak var buttonTestButton: UIButton!
    @IBOutlet weak var listTestButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        CommunicationCore.sharedInstance.connectionDelegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func didEstablishTheConnection() {
        dispatch_async(dispatch_get_main_queue()) {
            self.buttonTestButton.enabled = true
            self.listTestButton.enabled = true
        }
    }
    
    @IBAction func startButtonTest(sender: AnyObject) {
        var appStoryboard = UIStoryboard(name: "WatchApp", bundle: NSBundle.mainBundle())
        self.activeController = appStoryboard.instantiateViewControllerWithIdentifier("SimpleVC") as UIViewController
        self.presentViewController(self.activeController, animated: true, completion: nil)
    }
    
    @IBAction func startListTest(sender: AnyObject) {
        var appStoryboard = UIStoryboard(name: "WatchApp", bundle: NSBundle.mainBundle())
        self.activeController = appStoryboard.instantiateViewControllerWithIdentifier("ListVC") as UIViewController
        self.presentViewController(self.activeController, animated: true, completion: nil)
    }
    
    func didDisconnectFromServer() {
        dispatch_async(dispatch_get_main_queue()) {
            self.dismissViewControllerAnimated(true, completion: nil)
            self.activeController = nil
            self.buttonTestButton.enabled = false
            self.listTestButton.enabled = false
        }
    }

}

