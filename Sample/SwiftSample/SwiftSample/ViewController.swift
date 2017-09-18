//
//  ViewController.swift
//  SwiftSample
//
//  Created by user on 18/09/17.
//  Copyright © 2017 Sanjith J K. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showFAQs(_ sender: Any) {
        Freshchat.sharedInstance().showFAQs(self)
    }
    
    @IBAction func showConversations(_ sender: Any) {
        Freshchat.sharedInstance().showConversations(self)
    }

}

