//
//  ChatRoomViewController.swift
//  ChatAppWithFirebase
//
//  Created by 大西玲花 on 2021/07/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseDatabase

class ChatRoomViewController: UIViewController {
    
    // ログインしているユーザー
    var user: User?
    var chatroom: ChatRoom?{
        didSet {
            navigationItem.title = chatroom?.partnerUser?.username
        }
    }
    var refHandle: DatabaseHandle?
    var rightBarButton: UIViewController!
        
    private let cellId = "cellId"
    private var messages = [Message]()
    private let accessoryHeight: CGFloat = 100
    private let tableViewContetInset: UIEdgeInsets = .init(top: 0, left: 0, bottom: 60, right: 0)
    private let tableVIewIndicatorInset: UIEdgeInsets = .init(top: 0, left: 0, bottom: 60, right: 0)
    private var safeAreaBottom: CGFloat {
        self.view.safeAreaInsets.bottom
    }
    private var selectedUser: User?
    
    private lazy var chatInputAccessoryView: ChatInputAccessoryView = {
        let view = ChatInputAccessoryView()
        // アクセサリービューの大きさ
        view.frame = .init(x: 0, y: 0, width: view.frame.width, height: accessoryHeight)
        view.delegate = self
        return view
    }()
    
    
        
    @IBOutlet weak var chatRoomTabelView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNotification()
        setupChatRoomTableView()
        fetchMessages()
        fetchPartnerStatus()
    }
    
    private func setupNotification() {
        // キーボードが出てきたことを通知する
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        // キーボードが消えたことを通知する
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupChatRoomTableView() {
        chatRoomTabelView.delegate = self
        chatRoomTabelView.dataSource = self
        chatRoomTabelView.register(UINib(nibName: "ChatRoomTableViewCell", bundle: nil), forCellReuseIdentifier: cellId)
        chatRoomTabelView.backgroundColor = .rgb(red: 118, green: 140, blue: 180)
        chatRoomTabelView.contentInset = tableViewContetInset
        chatRoomTabelView.scrollIndicatorInsets = tableVIewIndicatorInset
        // スクロールしたらキーボードが閉じる
        chatRoomTabelView.keyboardDismissMode = .interactive
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
//        print("keyboardWillShow")
        guard let userInfo = notification.userInfo else { return }
        
        if let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue {
            
            if keyboardFrame.height <= accessoryHeight { return }
//            print("keyboardFrame: ", keyboardFrame)
            
            let bottom = keyboardFrame.height + safeAreaBottom
            var moveY = bottom + chatRoomTabelView.contentOffset.y
            // 最下部以外の時は少しズレるので微調整
            if chatRoomTabelView.contentOffset.y != 60 { moveY += 60 }
//            print("chatRoomTableView.contentOffset.y: ", chatRoomTabelView.contentOffset.y)
            let contentInsent = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
            
            chatRoomTabelView.contentInset = contentInsent
            chatRoomTabelView.scrollIndicatorInsets = contentInsent
            chatRoomTabelView.contentOffset = CGPoint(x: 0, y: moveY)
        }
    }
    
    @objc func keyboardWillHide() {
//        print("keyboardWillHide")
        chatRoomTabelView.contentInset = tableViewContetInset
        chatRoomTabelView.scrollIndicatorInsets = tableViewContetInset
    }
    
    override var inputAccessoryView: UIView?{
        get{
            return chatInputAccessoryView
        }
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    private func fetchMessages() {
        guard let chatroomDocId = chatroom?.chatRoomDocumentId else { return }
        
        Firestore.firestore().collection("chatRooms").document(chatroomDocId).collection("messages").addSnapshotListener { (snapshots, err) in
            if let err = err {
                print("メッセージ情報の取得に失敗しました。\(err)")
                return
            }
            snapshots?.documentChanges.forEach({ (documentChange) in
                switch documentChange.type {
                case .added:
                    let dic = documentChange.document.data()
                    let message = Message(dic: dic)
                    message.partnerUser = self.chatroom?.partnerUser
                    
                    self.messages.append(message)
                    // メッセージを時間順に並び替える
                    self.messages.sort { (m1, m2) -> Bool in
                        let m1Date = m1.createdAt.dateValue()
                        let m2Date = m2.createdAt.dateValue()
                        return m1Date < m2Date
                    }
                    
                    self.chatRoomTabelView.reloadData()
//                    print("message dic: ", dic)
                    //チャット画面を開いた時に一番下を表示する、animatedをfalseにしてトーク画面を開いた時にスクロールされるアニメーションを消す
                    self.chatRoomTabelView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .bottom, animated: false)
                    
                case .modified, .removed:
                    print("nothing to do")
                }
            })
        }
    }
        
    private func fetchPartnerStatus() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        chatroom?.members.forEach({ (memberUid) in
            if memberUid != uid {
                let database = Database.database()
                let statusRef = database.reference().child("status").child(memberUid)
                refHandle = statusRef.observe(DataEventType.value, with: { [self] snapshot in
                    let partnerStatus1 = snapshot.value as AnyObject
                    guard let state = partnerStatus1.value(forKeyPath: "state") as? String else { return }
  
                    let rightBarButton = UIBarButtonItem(title: state, style: .plain, target: nil, action: nil)
                    self.navigationItem.rightBarButtonItem = rightBarButton
                    self.navigationItem.rightBarButtonItem?.tintColor = .white
                    rightBarButton.isEnabled = false
                
                })
            }
        })
    }
}

extension ChatRoomViewController: ChatInputAccessoryViewDelegate{
    
    func tappedSendButton(text: String) {
        addMessageToFirestore(text: text)
    }
    
    private func addMessageToFirestore(text: String) {
        guard let chatroomDocId = chatroom?.chatRoomDocumentId else { return }
        guard let name = user?.username else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        chatInputAccessoryView.removeText()
        let messageId = randomString(length: 20)

        let docData = [
            "name": name,
            "createdAt": Timestamp(),
            "uid": uid,
            "message": text
        ] as [String : Any]
        
        Firestore.firestore().collection("chatRooms").document(chatroomDocId).collection("messages").document(messageId).setData(docData) { (err) in
            if let err = err {
                print("メッセージ情報の保存に失敗しました。\(err)")
                return
            }
            
            let latestMessageDate = [
                "latestMessageId": messageId
            ]
            
            Firestore.firestore().collection("chatRooms").document(chatroomDocId).updateData(latestMessageDate) { (err) in
                if let err = err {
                    print("最新メッセージの保存に失敗しました。 \(err)")
                    return
                }
                print("メッセージの保存に成功しました。")
            
            }
        }
    }
    
    func randomString(length: Int) -> String {
            let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            let len = UInt32(letters.length)

            var randomString = ""
            for _ in 0 ..< length {
                let rand = arc4random_uniform(len)
                var nextChar = letters.character(at: Int(rand))
                randomString += NSString(characters: &nextChar, length: 1) as String
            }
            return randomString
    }

    
}

extension ChatRoomViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // tableview cellの高さを可変にする
        chatRoomTabelView.estimatedRowHeight = 20
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = chatRoomTabelView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ChatRoomTableViewCell
//        cell.messageTextView.text = messages[indexPath.row]
        cell.message = messages[indexPath.row]
        return cell
    }
    
    
}

