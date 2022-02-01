//
//  ChatRoom.swift
//  ChatAppWithFirebase
//
//  Created by 大西玲花 on 2021/08/06.
//

import Foundation
import Firebase


class ChatRoom {
    
    let latestMessageId: String
    let members: [String]
    let createdAt: Timestamp
    
    var latestMessage: Message?
    var chatRoomDocumentId: String?
    var partnerUser: User?
    var partherLatestComment: CommentRoom?
    var partnerState: OnlineStatus?
    var state: OnlineStatus?
    
    init(dic: [String: Any]) {
        self.latestMessageId = dic["latestMessageId"] as? String ?? ""
        self.members = dic["members"] as? [String] ?? [String]()
        self.createdAt = dic["createdAt"] as? Timestamp ?? Timestamp()
    }
}
