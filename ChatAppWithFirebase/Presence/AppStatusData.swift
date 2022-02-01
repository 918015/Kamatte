//
//  AppStatusData.swift
//  ChatAppWithFirebase
//
//  Created by 大西玲花 on 2021/10/08.
//

import Foundation
import Firebase
import FirebaseFirestore

class AppStatusData {
    
    let appStatus: String
    let createdAt: Timestamp
    
    init(dic: [String: Any]) {
        self.appStatus = dic["appStatus"] as? String ?? ""
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
    }
    
}
