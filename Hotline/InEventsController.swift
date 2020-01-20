//
//  InEventsController.swift
//  Hotline Demo
//
//  Created by Harish kumar on 20/11/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//

import Foundation
import UIKit

class InEventsController: UIViewController {
    
    @IBOutlet weak var eventName: UITextField!
    @IBOutlet weak var eventPropertyKeys: UITextView!
    @IBOutlet weak var eventPropertyValues: UITextView!
    @IBOutlet weak var eventTimes : UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func trackEvent(_ sender: Any) {
        
        if eventName.text?.count == 0 {
            let alert = UIAlertController(title: "Error", message: "Invalid event name",
                        preferredStyle: UIAlertControllerStyle.alert)

            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { _ in
                //Cancel Action
            }))
            self.present(alert, animated: true, completion: nil)
            return;
        }
        
        let keysArray : [String] = self.eventPropertyKeys.text.split{$0 == ","}.map(String.init)
        let valueArray : [Any] = self.eventPropertyValues.text.split{$0 == ","}.map(String.init)
        
        if keysArray.count != valueArray.count {
            let alert = UIAlertController(title: "Error", message: "Invalid properties count",
                                          preferredStyle:.alert)

            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { _ in
                //Cancel Action
            }))
            self.present(alert, animated: true, completion: nil)
            return;
        }
        
        var eventDict = [String: Any]()
        for i in 0..<min(keysArray.count,valueArray.count) {
            eventDict[keysArray[i]] = valueArray[i]
        }
        
        let t = Int(self.eventTimes.text!) ?? 0
        for _ in 0..<t {
            Freshchat.sharedInstance()?.trackEvent(eventName.text, withProperties: eventDict)
        }
    }
    
    @IBAction func closeVC(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
