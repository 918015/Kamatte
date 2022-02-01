//
//  SceneDelegate.swift
//  ChatAppWithFirebase
//
//  Created by 大西玲花 on 2021/07/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseDatabase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        let window = UIWindow(windowScene: scene as! UIWindowScene)
        self.window = window
        window.makeKeyAndVisible()
        
        let storyboard = UIStoryboard(name: "ChatList", bundle: nil)
        let chatListViewController = storyboard.instantiateViewController(identifier: "ChatListViewController")
        let nav = UINavigationController(rootViewController: chatListViewController)
        
        window.rootViewController = nav
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    var ref: DatabaseReference!
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
      
        ref = Database.database().reference()
        ref.child("status").child(uid).setValue([
            "state": "online",
            "lastChanged": ServerValue.timestamp()
        ])

    }

    func sceneWillResignActive(_ scene: UIScene) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        ref = Database.database().reference()
        ref.child("status").child(uid).setValue([
            "state": "background",
            "lastChanged": ServerValue.timestamp()
        ])
    }

    func changeOffline() {
        NotificationCenter.default.addObserver(self, selector: #selector(changedAppStatus(_:)), name: UIApplication.protectedDataWillBecomeUnavailableNotification, object: nil)
    }

    @objc func changedAppStatus(_ notification: Notification) {
        if notification.name == UIApplication.protectedDataWillBecomeUnavailableNotification {
            let database = Database.database()
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let statusRef = database.reference().child("status").child(uid)
            statusRef.setValue([
                "state": "offline",
                "lastChanged": ServerValue.timestamp()
            ])
        }
    }


}

