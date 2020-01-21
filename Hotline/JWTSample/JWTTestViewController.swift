//
//  JWTTestViewController.swift
//  Hotline Demo
//
//  Created by Harish kumar on 25/12/19.
//  Copyright © 2019 Freshdesk. All rights reserved.
//

import Foundation
import UIKit

class JWTTestViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView?
    @IBOutlet weak var userId: UITextField?
    @IBOutlet weak var firstName: UITextField?
    @IBOutlet weak var lastName: UITextField?
    @IBOutlet weak var emailId: UITextField?
    @IBOutlet weak var countryCode: UITextField?
    @IBOutlet weak var phoneNumber: UITextField?
    @IBOutlet weak var referenceId: UITextField?
    @IBOutlet weak var expiryTime: UITextField?
    @IBOutlet weak var properties: UITextField?
    @IBOutlet weak var jwtTokenValue: UITextView?
    @IBOutlet weak var jwtTokenState : UILabel?
    
    let bundle = Bundle.self
    var publicKeyString: String?
    var privateKeyString: String?
    var privateKey: RSAKey!
    var publicKey: RSAKey!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView?.delegate = self
        self.userId?.text = Freshchat.sharedInstance()?.getUserId()
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapRecognizer)
        
        self.jwtTokenValue?.text = UserDefaults.standard.string(forKey: "jwtToken")
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        NotificationCenter.default.addObserver(self,selector: #selector(updateJWTTokenState),name: NSNotification.Name(rawValue: FRESHCHAT_EVENTS),object: nil)
    }
    
    @objc func keyboardWillShow(notification:NSNotification){
        //give room at the bottom of the scroll view, so it doesn't cover up anything the user needs to tap
        let userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)

        var contentInset:UIEdgeInsets = self.scrollView!.contentInset
        contentInset.bottom = keyboardFrame.size.height
        scrollView?.contentInset = contentInset
    }

    @objc func keyboardWillHide(notification:NSNotification){
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        scrollView?.contentInset = contentInset
    }
    
    @objc func updateJWTTokenState()
    {
        self.jwtTokenState?.text = "\("Token State : ") + \(String(describing: Freshchat.sharedInstance()?.getUserIdTokenStatus()))"
    }
    
    @IBAction func generateSampleJWTToken (_ sender: UIButton) {
        guard let publicPath = Bundle.main.path(forResource: "public", ofType: "txt"),
            let privatePath = Bundle.main.path(forResource: "private", ofType: "txt")
            else{
                print("error")
                return;
        }
        publicKeyString = try? String(contentsOf: URL(fileURLWithPath: publicPath), encoding: .utf8)
        privateKeyString = try? String(contentsOf: URL(fileURLWithPath: privatePath), encoding: .utf8)
        
        privateKey = try! RSAKey.init(base64String: privateKeyString!, keyType: .PRIVATE)
        publicKey = try! RSAKey.init(base64String: publicKeyString!, keyType: .PUBLIC)
        
        
        var payload = JWTPayload()
        if let expiryTime = self.expiryTime?.text, Int(expiryTime) != nil {
            payload.expiration = Int(Date.init().secondsSince1970) + (Int(expiryTime)! * 60)
        }
        
        payload.issuer = "Harish"
        payload.subject = "JWTRS256"
        var animDictionary: [String: EncodableValue] = [:]
        
        animDictionary["freshchat_uuid"] = EncodableValue(value: Freshchat.sharedInstance()?.getUserId())
        
        if let fName = self.firstName?.text, fName.count > 0 {
            animDictionary["first_name"] = EncodableValue(value: fName)
        }
        
        if let lName = self.lastName?.text, lName.count > 0 {
            animDictionary["last_name"] = EncodableValue(value: lName)
        }
        
        if let email = self.emailId?.text, email.count > 0 {
            animDictionary["email"] = EncodableValue(value: email)
        }
        
        let phoneNumber = self.phoneNumber?.text
        
        let cCode = self.countryCode?.text
        
        let phone = (cCode ?? "") + (phoneNumber ?? "")
        
        if phone.count > 0 {
            animDictionary["phone_number"] = EncodableValue(value: phone )
        }
        
        if let refId = self.referenceId?.text, refId.count > 0  {
            animDictionary["reference_id"] = EncodableValue(value: refId)
        }
        
        if let props = self.properties?.text {
            var propertiesArray = props.components(separatedBy: ",")
            propertiesArray = propertiesArray.filter { $0 != "" }
            if propertiesArray.count != 0 {
                if propertiesArray.count % 2 == 0 {
                    //add properties
                    for index in stride(from: 0, to: propertiesArray.count - 1, by: 2){
                        animDictionary[propertiesArray[index]] = EncodableValue(value: (propertiesArray[index + 1]))
                    }
                }
                else{
                    let alert = UIAlertController(title: "Error", message: "Invalid properties count",
                                                  preferredStyle:.alert)
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { _ in
                        //Cancel Action
                    }))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
            }
        }
        
        payload.customFields = animDictionary
        
        let alg = JWTAlgorithm.rs256(privateKey)

        let headerWithKeyId = JWTHeader.init(keyId: "testKeyId")
        _ = try? JWT.init(payload: payload, algorithm: alg, header: headerWithKeyId)
        let simpleJwt = JWT.init(payload: payload, algorithm: alg)
        self.jwtTokenValue?.text = String(describing: (simpleJwt?.rawString)!)
        
        UserDefaults.standard.set(self.jwtTokenValue?.text, forKey: "jwtToken") //set JWT
    }
    
    @IBAction func dismissView (_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func idenfifyUser (_ sender: UIButton) {
        if let jwtStr = self.jwtTokenValue?.text {
            Freshchat.sharedInstance()?.setUserWithIdToken(jwtStr)
        }
    }
    
    @IBAction func restoreUser (_ sender: UIButton) {
        if let jwtStr = self.jwtTokenValue?.text {
            Freshchat.sharedInstance()?.restoreUser(withIdToken: jwtStr)
        }
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
}

extension Date {
 var secondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970).rounded())
    }

    init(seconds:Int) {
        self = Date(timeIntervalSince1970: TimeInterval(seconds / 1000))
    }
}
