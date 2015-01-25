//
//  SimpleThingsViewController.swift
//  WatchClient
//
//  Created by Khaos Tian on 1/24/15.
//  Copyright (c) 2015 Khaos Tian. All rights reserved.
//

import UIKit

class SimpleThingsViewController: UIViewController,CommunicationCoreProtocol {
    
    @IBOutlet weak var textLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        CommunicationCore.sharedInstance.activeVCDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pressButton(sender: AnyObject) {
        var trans = Transaction(tp: .Action)
        trans.actionSelector = "pressButton"
        CommunicationCore.sharedInstance.emitTransaction(trans)
    }
    
    func didGetNewUpdate(updates: [Transaction]) {
        var objectLists = ["textLabel" : textLabel]
        for trans in updates {
            if trans.type == .UI {
                dispatch_async(dispatch_get_main_queue()) {
                    if let viewName = trans.viewName {
                        var selector = "set"+trans.viewProperty!.capitalizedString+":"
                        var object = objectLists[viewName]
                        MethodHelper.performActionForObject(object, selector: Selector(selector), withParm: trans.viewValue!)
                    }
                }
            }
        }
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
