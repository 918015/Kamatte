//
//  OnlineStatus.swift
//  ChatAppWithFirebase
//
//  Created by 大西玲花 on 2021/10/28.
//

import Foundation
import Firebase
import FirebaseDatabase

class OnlineStatus {
    
    let lastChanged: Timestamp
    let state: String
    
    init(dic: [String : Any]) {
        self.lastChanged = dic["lastChanged"] as? Timestamp ?? Timestamp()
        self.state = dic["state"] as? String ?? ""
    }
}
