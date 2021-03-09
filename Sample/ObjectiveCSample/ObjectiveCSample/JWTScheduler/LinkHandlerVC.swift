//
//  LinkHandlerVC.swift
//  Hotline Demo
//
//  Created by Sanjith Kanagavel on 27/11/18.
//  Copyright © 2018 Freshdesk. All rights reserved.
//

import Foundation
import UIKit

class LinkHandlerVC: UIViewController {
    @IBOutlet weak var deeplinkSpace: UITextView!
    @IBOutlet weak var interceptNotification: UISwitch!
    @IBOutlet weak var browserHandling: UISwitch!
    @IBOutlet weak var interceptNotificationTxtView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapRecognizer)
        self.checkInAppHandlingState()
    }
    
    @IBAction func tapLink(_ sender: Any) {
        if(self.deeplinkSpace.text.count > 0) {
            Freshchat.sharedInstance()?.openDeeplink(self.deeplinkSpace.text, viewController: self)
        }
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    @IBAction func showConversations(_ sender: Any) {
        Freshchat.sharedInstance()?.showConversations(self)
    }
    
    @IBAction func showFAQs(_ sender: Any) {
        Freshchat.sharedInstance()?.showFAQs(self)
    }
    
    
    @IBAction func interceptNotificationChanged(_ sender: Any) {
        if(self.interceptNotification.isOn) {
            Freshchat.sharedInstance()?.onNotificationClicked =  ({ (url) in
                    self.interceptNotificationTxtView.text = url
                        return false
                })
        } else {
            Freshchat.sharedInstance()?.onNotificationClicked =  ({ (url) in
                self.interceptNotificationTxtView.text = url
                return true
            })
        }
    }
    @IBAction func clearData(_ sender: Any) {
        Freshchat.sharedInstance()?.resetUser(completion: nil)
    }
        
    @IBAction func valueChanged(_ sender: Any) {
        self.checkInAppHandlingState()
    }
    
    func checkInAppHandlingState() {
        if(self.browserHandling.isOn) {
            let storyboard = UIStoryboard(name: IN_APP_BROWSER_STORYBOARD_CONTROLLER, bundle: nil)
            Freshchat.sharedInstance()?.customLinkHandler = ({ (url) in
                if let inAppBrowser = storyboard.instantiateViewController(withIdentifier: IN_APP_BROWSER_STORYBOARD_CONTROLLER) as? InAppBrowser {
                    inAppBrowser.url = url
                    if let viewController = self.navigationController?.visibleViewController {
                        viewController.present(inAppBrowser, animated: true, completion: nil)
                    }
                }
                return true
            })
        } else {
            Freshchat.sharedInstance()?.customLinkHandler = ({ (url) in
                return false
            })
        }
    }
}
