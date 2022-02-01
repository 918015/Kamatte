//
//  User.swift
//  ChatAppWithFirebase
//
//  Created by 大西玲花 on 2021/07/30.
//

import Foundation
import Firebase

class User {
    
    let email: String
    let username: String
    let createdAt: Timestamp
    let profileImageUrl: String
    let latestCommentId: String

    var partnerUid: User?
    var uid: String?
    
    var documentId: String?
    var latestComment: CommentRoom?
    
    init(dic: [String: Any]) {
        self.email = dic["email"] as? String ?? ""
        self.username = dic["username"] as? String ?? ""
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
        self.profileImageUrl = dic["profileImageUrl"] as? String ?? ""
        self.latestCommentId = dic["latestCommentId"] as? String ?? ""
    }
    
}
