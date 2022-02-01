//
//  commentViewController.swift
//  ChatAppWithFirebase
//
//  Created by 大西玲花 on 2021/09/09.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Nuke

class CommentViewController: UIViewController {
    
    private let cellId = "cellId"
    private var users = [User]()
    private var safeAreaBottom: CGFloat {
        self.view.safeAreaInsets.bottom
    }
    private var comments = [CommentRoom]()
    
    private var user: User?
    var commentroom: CommentRoom?
    
    private let accessoryHeight: CGFloat = 100
    private let tableViewContetInset: UIEdgeInsets = .init(top: 0, left: 0, bottom: 60, right: 0)
    
    private lazy var commentInputAccessoryView: CommentInputAccessoryView = {
        let view = CommentInputAccessoryView()
        view.frame = .init(x: 0, y: 0, width: view.frame.width, height: accessoryHeight)
        view.delegate = self
        return view
    }()
    
    @IBOutlet weak var commentTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        commentTableView.delegate = self
        commentTableView.dataSource = self
        
        fetchLoginUserInfo()
        setupNotification()
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return commentInputAccessoryView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    private func fetchLoginUserInfo() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { (snapshot, err) in
            if let err = err{
                print("ユーザー情報の取得に失敗しました。\(err)")
                return
            }
            guard let snapshot = snapshot, let dic = snapshot.data() else { return }
            let user = User(dic: dic)
            self.user = user
            
            self.users.append(user)
            self.commentTableView.reloadData()
            
            let latestCommentId = user.latestCommentId
            if latestCommentId == "" {
                self.users.append(user)
                self.commentTableView.reloadData()
                return
            }
            Firestore.firestore().collection("users").document(uid).collection("comments").document(latestCommentId).getDocument { (commentSnapshot, err) in
                if let err = err {
                    print("最新のコメントの取得に失敗しました。 \(err)")
                    return
                }
                guard let dic = commentSnapshot?.data() else { return }
                let comment = CommentRoom(dic: dic)
                user.latestComment = comment

                self.comments.append(comment)
                self.commentTableView.reloadData()

                
            }
        }
    }
    
    private func setupNotification() {
        // キーボードが出てきたことを通知する
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        // キーボードが消えたことを通知する
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    @objc func keyboardWillShow(notification: NSNotification) {
//        print("keyboardWillShow")
        guard let userInfo = notification.userInfo else { return }
        
        if let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue {
            
            if keyboardFrame.height <= accessoryHeight { return }
//            print("keyboardFrame: ", keyboardFrame)
            
            let bottom = keyboardFrame.height + safeAreaBottom
            var moveY = bottom + commentTableView.contentOffset.y
      
            // 最下部以外の時は少しズレるので微調整
            if commentTableView.contentOffset.y != 60 { moveY += 60 }
//            print("chatRoomTableView.contentOffset.y: ", chatRoomTabelView.contentOffset.y)
            let contentInsent = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
            
            commentTableView.contentInset = contentInsent
            commentTableView.scrollIndicatorInsets = contentInsent
            commentTableView.contentOffset = CGPoint(x: 0, y: moveY)
        }
    }
    
    @objc func keyboardWillHide() {
//        print("keyboardWillHide")
        commentTableView.contentInset = tableViewContetInset
        commentTableView.scrollIndicatorInsets = tableViewContetInset

    }


}

extension CommentViewController: CommentInputAccessoryViewDelegate {
    
    func tappedSaveButton(text: String) {
        addCommentToFirestore(text: text)
//        comment.append(text)
//        commentInputAccessoryView.commentTextView.text = ""
//        print("commentInputAccessoryViewDelegate text: ", text)
    }

    func addCommentToFirestore(text: String) {
        // firestoreにデータを保存する
        guard let name = user?.username else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let commentId = randomString(length: 20)
        commentInputAccessoryView.removeText()
        
        let docData = [
            "name": name,
            "createdAt": Timestamp(),
            "uid": uid,
            "comment": text,
        ] as [String : Any]
        
        Firestore.firestore().collection("users").document(uid).collection("comments").document(commentId).setData(docData) { (err) in
            if let err = err {
                print("コメントの保存に失敗しました。 \(err)")
                return
            }
            let latestCommentData = [
                "latestCommentId": commentId
            ]
            Firestore.firestore().collection("users").document(uid).updateData(latestCommentData) {
                (err) in
                if let err = err {
                    print("最新のコメントの保存に失敗しました。 \(err)")
                    return
                }
            }
            print("コメントの保存に成功しました。")
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

extension CommentViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        commentTableView.estimatedRowHeight = 80
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = commentTableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! CommentTableViewCell
        
        cell.user = users[indexPath.row]
//        cell.commentText = comments[indexPath.row]
        
        return cell
    }
}

class CommentTableViewCell: UITableViewCell {
    
    var user: User? {
        didSet {
            if let user = user {
                userNameLabel.text = user.username

                guard let url = URL(string: user.profileImageUrl ) else { return }
                Nuke.loadImage(with: url, into: userImageView)


                getCommentTextView.text = user.latestComment?.comment
            }
        }
    }

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var getCommentTextView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.layer.cornerRadius = 30
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
