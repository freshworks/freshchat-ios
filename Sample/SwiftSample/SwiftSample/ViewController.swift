//
//  ViewController.swift
//  SwiftSample
//
//  Created by Pramit Tewari on 17/01/25.
//

import UIKit
import FreshchatSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func showConversations() {
        Freshchat.sharedInstance().showConversations(self)
    }
    
    @IBAction func showFAQs() {
        Freshchat.sharedInstance().showFAQs(self)
    }
}

