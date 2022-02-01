//
//  CommentRoom.swift
//  ChatAppWithFirebase
//
//  Created by 大西玲花 on 2021/10/15.
//

import Foundation
import Firebase

class CommentRoom {
    
    let name: String
    let comment: String
    let uid: String
    let createdAt: Timestamp
    
    var latestCommentId: User?
    
    init(dic: [String: Any]) {
        self.name = dic["name"] as? String ?? ""
        self.comment = dic["comment"] as? String ?? ""
        self.uid = dic["uid"] as? String ?? ""
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
    }
}
