//
//  LoginViewController.swift
//  ChatAppWithFirebase
//
//  Created by 大西玲花 on 2021/08/14.
//

import UIKit
import Firebase
import FirebaseDatabase
import PKHUD

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var dontHaveAccountButton: UIButton!
    
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.layer.cornerRadius = 8
        
        dontHaveAccountButton.addTarget(self, action: #selector(tappedDontHaveAccountButton), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(tappedLoginButton), for: .touchUpInside)
    }
    
    @objc private func tappedDontHaveAccountButton() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func tappedLoginButton() {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        HUD.show(.progress)
        
        Auth.auth().signIn(withEmail: email, password: password) { (res, err) in
            if let err = err {
                print("ログインに失敗しました。\(err)")
                HUD.hide()
                return
            }
            
            HUD.hide()
            print("ログインに成功しました。")
            let nav = self.presentingViewController as! UINavigationController
            let chatListviewController = nav.viewControllers[nav.viewControllers.count-1] as? ChatListViewController
            chatListviewController?.fetchChatroomsInfoFromFirestore()
            
            self.dismiss(animated: true, completion: nil)
            
            let database = Database.database()
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let statusRef = database.reference().child("status").child(uid)
            statusRef.setValue([
                "state": "online",
                "lastChanged": ServerValue.timestamp()
            ])
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
}
