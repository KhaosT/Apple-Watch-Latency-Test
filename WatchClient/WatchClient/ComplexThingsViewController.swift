//
//  ComplexThingsViewController.swift
//  WatchClient
//
//  Created by Khaos Tian on 1/24/15.
//  Copyright (c) 2015 Khaos Tian. All rights reserved.
//

import UIKit

class ComplexThingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CommunicationCoreProtocol {
    
    var items = [String]()
    @IBOutlet weak var numberField: UITextField!
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        CommunicationCore.sharedInstance.activeVCDelegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func handleKeyboardWillShow(aNote: NSNotification) {
        if let info = aNote.userInfo as? [String:AnyObject] {
            var frame = info[UIKeyboardFrameEndUserInfoKey] as NSValue
            self.bottomConstraint.constant = frame.CGRectValue().height + 20
        }
    }
    
    func handleKeyboardWillHide(aNote: NSNotification) {
        self.bottomConstraint.constant = 0
    }
    
    @IBAction func updateValue(sender: AnyObject) {
        var trans = Transaction(tp: .Action)
        trans.actionSelector = "updateCells:"
        let f = NSNumberFormatter()
        f.numberStyle = NSNumberFormatterStyle.DecimalStyle
        trans.actionValue = f.numberFromString(self.numberField.text)?.floatValue
        CommunicationCore.sharedInstance.emitTransaction(trans)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        
        cell.textLabel?.text = self.items[indexPath.row]
        
        return cell
    }
    
    func didGetNewUpdate(updates: [Transaction]) {
        for trans in updates {
            if trans.type == .List {
                dispatch_async(dispatch_get_main_queue()) {
                    if let items = trans.listItems {
                        self.items = items
                        self.tableView.reloadData()
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
