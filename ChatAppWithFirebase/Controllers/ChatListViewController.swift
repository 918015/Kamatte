//
//  ChatListViewController.swift
//  ChatAppWithFirebase
//
//  Created by 大西玲花 on 2021/07/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseDatabase
import Nuke
import SwiftUI

class ChatListViewController: UIViewController{
    
    private let cellId = "cellId"
    private var chatrooms = [ChatRoom]()
    private var chatRoomListener: ListenerRegistration?
    private var comments = [CommentRoom]()
    private var selectedUser: User?
    private var users = [User]()
    
    var chatroom: ChatRoom?
    var ref: DatabaseReference!
    var refHandle: DatabaseHandle?
    
    let center = NotificationCenter.default

    private var user: User? {
        didSet {
            navigationItem.title = user?.username
        }
    }
    
    
    
    @IBOutlet weak var chatListTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
        confirmLoggedInUser()
        fetchChatroomsInfoFromFirestore()
        presenceData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetuhLoginUserInfo()

    }
    

    
    func  presenceData() {
        let database = Database.database()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        // ".info/connected"という接続状況に応じて値の変わる特別なパスを監視
        database.reference(withPath: ".info/connected").observe(.value) { [self] snap in
            let connected = snap.value as? Bool ?? false
//            print("connected: \(connected)")
            if !connected {
                return
            }
            let statusRef = database.reference().child("status").child(uid)
            // 接続が確立されたら、オフラインになったタイミングで更新したい処理を予約しつつ、
            statusRef.onDisconnectSetValue([
                "state": "offline",
                "lastChanged": ServerValue.timestamp()
            ]) { (error, _) in
                // stateをonlineに変更
                statusRef.setValue([
                    "state": "online",
                    "lastChanged": ServerValue.timestamp()
                    ])
            }
            // データを１回読み取る
//            statusRef.child("state").getData { (err, snapshot) in
//                if let err = err {
//                    print("オンラインステータスの取得に失敗しました。\(err)")
//                }
//                else if snapshot.exists() {
//                    print("status: \(snapshot.value!)")
//                }
//                else {
//                    print("No data available")
//                }
//            }
            // データが更新されるたびに読み取る
//            refHandle = statusRef.child("state").observe(DataEventType.value, with: { snapshot in
//                if let statusData = snapshot.value as? String {
//                    print("status: ", statusData)
//                }
//            })
//            refHandle = statusRef.observe(DataEventType.value, with: { snapshot in
//                let partnerStatus = snapshot.value as AnyObject
//                guard let lastChanged = partnerStatus.value(forKeyPath: "lastChanged") else { return }
//                guard let state = partnerStatus.value(forKeyPath: "state") else { return }
//                print("status: ", lastChanged, state)
//            })
        }
    }

    
    // ログアウト時にデータを消し、ログイン時にリロードする
    func fetchChatroomsInfoFromFirestore() {
        chatRoomListener?.remove()
        chatrooms.removeAll()
        chatListTableView.reloadData()
        
        chatRoomListener = Firestore.firestore().collection("chatRooms")
            // リアルタイムに更新
            .addSnapshotListener { (snapshots, err) in
            
            if let err = err {
                print("ChatRooms情報の取得に失敗しました。\(err)")
                return
            }
            snapshots?.documentChanges.forEach({ (documentChange) in
                switch documentChange.type {
                    case .added:
                        self.handleAddedDocumentChange(documentChange: documentChange)
                    case .modified, .removed:
                        print("nothing to do")
                    
                }
            })
        }
    }
    

    
    private func handleAddedDocumentChange(documentChange: DocumentChange) {

        let dic = documentChange.document.data()
        let chatroom = ChatRoom(dic: dic)
        chatroom.chatRoomDocumentId = documentChange.document.documentID
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let isContain = chatroom.members.contains(uid)
        
        if !isContain { return }

        guard let uid = Auth.auth().currentUser?.uid else { return }
        chatroom.members.forEach { (memberUid) in
            if memberUid != uid {
                Firestore.firestore().collection("users").document(memberUid).getDocument { (userSnapshot, err) in
                    if let err = err{
                        print("ユーザー情報の取得に失敗しました。\(err)")
                        return
                    }
                    guard let dic = userSnapshot?.data() else { return }
                    let user = User(dic: dic)
                    user.uid = documentChange.document.documentID
                    // リストに名前を表示する
                    chatroom.partnerUser = user
                    
                    let latestCommentId = user.latestCommentId
                    if latestCommentId.isEmpty {
                        self.users.append(user)
                        self.chatListTableView.reloadData()
                        return
                    }
                    Firestore.firestore().collection("users").document(memberUid).collection("comments").document(latestCommentId).getDocument { (commentSnapshot, err) in
                        if let err = err {
                            print("最新のコメントの取得に失敗しました。 \(err)")
                            return
                        }
                        guard let dic = commentSnapshot?.data() else { return }
                        let comment = CommentRoom(dic: dic)
                        chatroom.partherLatestComment = comment
                        
                        guard let chatroomId = chatroom.chatRoomDocumentId else { return }
                        let latestMessageId = chatroom.latestMessageId
                        if latestMessageId.isEmpty {
                            self.chatrooms.append(chatroom)
                            self.chatListTableView.reloadData()
                            return
                        }
                        Firestore.firestore().collection("chatRooms").document(chatroomId).collection("messages").document(latestMessageId).getDocument { (messageSnapshot, err) in
                            if let err = err {
                                print("最新情報の取得に失敗しました。\(err)")
                                return
                            }
                            
                            guard let dic = messageSnapshot?.data() else { return }
                            let message = Message(dic: dic)
                            chatroom.latestMessage = message
                            
                            self.chatrooms.append(chatroom)
                            self.chatrooms.sort { (m1, m2) -> Bool in
                                let m1Data = m1.createdAt.dateValue()
                                let m2Data = m2.createdAt.dateValue()
                                return m1Data < m2Data
                            }
                            self.chatListTableView.reloadData()
                            
                        }
                    }
                }
            }
        }
    }
    
    
    
    private func setUpViews() {
        chatListTableView.tableFooterView = UIView()
        chatListTableView.delegate = self
        chatListTableView.dataSource = self
        
        navigationController?.navigationBar.barTintColor = .rgb(red: 39, green: 39, blue: 69)
//        navigationItem.title = "トーク"
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        let rightBarButton = UIBarButtonItem(title: "新規チャット", style: .plain, target: self, action: #selector(tappedNavRightBarButton))
        let rightBarButton2 = UIBarButtonItem(title: "編集", style: .plain, target: self, action: #selector(tappedNavRightBarButton2))
        let logoutBarButton = UIBarButtonItem(title: "ログアウト", style: .plain, target: self, action: #selector(tappedLogoutButton))
        
        self.navigationItem.rightBarButtonItems = [rightBarButton2,rightBarButton]
        // アイテムをセット
        navigationItem.rightBarButtonItem = rightBarButton2
        navigationItem.rightBarButtonItem?.tintColor = .white
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.rightBarButtonItem?.tintColor = .white
        navigationItem.leftBarButtonItem = logoutBarButton
        navigationItem.leftBarButtonItem?.tintColor = .white
        
    }
    
    @objc private func tappedNavRightBarButton2() {
        let storyboard = UIStoryboard.init(name: "comment", bundle: nil)
        let commentViewController = storyboard.instantiateViewController(withIdentifier: "CommentViewController") as! CommentViewController
        let nav = UINavigationController(rootViewController: commentViewController)
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc private func tappedLogoutButton() {
        sendOffline()
        do{
            try Auth.auth().signOut()
            pushLoginViewController()
        } catch {
            print("ログアウトに失敗しました。 \(error)")
        }
    }
    
    private func confirmLoggedInUser() {
        if Auth.auth().currentUser?.uid == nil {
            pushLoginViewController()
        }
    }
    
    private func pushLoginViewController() {
        let storybord = UIStoryboard(name: "SignUp", bundle: nil)
        let signUpViewController = storybord.instantiateViewController(withIdentifier: "SignUpViewController") as! SignUpViewController
        let nav = UINavigationController(rootViewController: signUpViewController)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }
    
    @objc private func sendOffline() {
        let database = Database.database()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let statusRef = database.reference().child("status").child(uid)
        statusRef.setValue([
            "state": "offline",
            "lastChanged": ServerValue.timestamp()
        ])
    }
    
    // ボタンの遷移を設定
    @objc private func tappedNavRightBarButton() {
        let storyboad = UIStoryboard.init(name: "UserList", bundle: nil)
        let userListViewController = storyboad.instantiateViewController(withIdentifier: "UserListViewController")
        // ナビゲーションバーを設定
        let nav = UINavigationController(rootViewController: userListViewController)
        self.present(nav, animated: true, completion: nil)
    }
    
    private func fetuhLoginUserInfo() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(uid).getDocument { (snapshot, err) in
            if let err = err{
                print("ユーザー情報の取得に失敗しました。\(err)")
                return
            }
            guard let snapshot = snapshot, let dic = snapshot.data() else { return }
            
            let user = User(dic: dic)
            self.user = user
            
        }
    }
    
}

extension ChatListViewController:UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        chatListTableView.estimatedRowHeight = 160
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatrooms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = chatListTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ChatListTableViewCell
        cell.chatroom = chatrooms[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // 各チャットルームに遷移する
//        print("tapped table view")
        let storyboad = UIStoryboard.init(name: "ChatRoom", bundle: nil)
        let chatRoomViewController = storyboad.instantiateViewController(withIdentifier: "ChatRoomViewController") as! ChatRoomViewController
        chatRoomViewController.user = user
        chatRoomViewController.chatroom = chatrooms[indexPath.row]
        navigationController?.pushViewController(chatRoomViewController, animated: true)
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem (
            title: "戻る",
            style: .plain,
            target: nil,
            action: nil
        )
        self.navigationItem.backBarButtonItem?.tintColor = .white
    }
}

class ChatListTableViewCell: UITableViewCell{
    
    
    var user: User?
    var onlineState: OnlineStatus?
    var commentRoom: CommentRoom?
    var chatroom: ChatRoom? {
        didSet {
            if let chatroom = chatroom {
                partnerLabel.text = chatroom.partnerUser?.username

                guard let url = URL(string: chatroom.partnerUser?.profileImageUrl ?? "") else { return }
                Nuke.loadImage(with: url, into: userImageView)
                commentTextView.text = chatroom.partherLatestComment?.comment
                commentDateLabel.text = dateFormatterForDateLabel(date: chatroom.partherLatestComment?.createdAt.dateValue() ?? Date())

                let latestMessageId = chatroom.latestMessageId
                if latestMessageId.isEmpty {
                    dateLabel.isHidden = true
                    latestMessageLabel.isHidden = true
                    return

                } else {
                    dateLabel.text = dateFormatterForDateLabel(date: chatroom.latestMessage?.createdAt.dateValue() ?? Date())
                    latestMessageLabel.text = chatroom.latestMessage?.message
                }

                guard let uid = Auth.auth().currentUser?.uid else { return }
                chatroom.members.forEach { (memberUid) in
                    if memberUid != uid {
                        let database = Database.database()
                        let statusRef = database.reference().child("status").child(memberUid)
                        statusRef.getData { (err, snapshot) in
                            if let err = err {
                                print("オンライン情報の取得に失敗しました。 \(err)")
                                return
                            }
                            let status = snapshot.value as AnyObject
                            guard let state = status.value(forKeyPath: "state") as? String else { return }
                            if state == "online" {
                                self.presenceImageOnline.isHidden = false
                                self.presenceImageBackground.isHidden = true
                            } else if state == "background" {
                                self.presenceImageOnline.isHidden = true
                                self.presenceImageBackground.isHidden = false
                            } else {
                                self.presenceImageOnline.isHidden = true
                                self.presenceImageBackground.isHidden = true

                            }
                        }
//                            let partnerStatus1 = snapshot.value as AnyObject
//                            guard let state = partnerStatus1.value(forKeyPath: "state") as? String else { return }
//
                    }
                }
            }
        }
    }
    
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var latestMessageLabel: UILabel!
    @IBOutlet weak var partnerLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var commentDateLabel: UILabel!
    @IBOutlet weak var statusMessage: UILabel!
    @IBOutlet weak var presenceImageOnline: UIImageView!
    @IBOutlet weak var presenceImageBackground: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        userImageView.layer.cornerRadius = 30
        commentTextView.layer.borderWidth = 1
        commentTextView.layer.borderColor = UIColor.rgb(red: 187, green: 191, blue: 194).cgColor
        commentTextView.layer.cornerRadius = 10
        commentTextView.layer.masksToBounds = true
        presenceImageOnline.layer.cornerRadius = 32
        presenceImageBackground.layer.cornerRadius = 32
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    private func dateFormatterForDateLabel(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    
}
