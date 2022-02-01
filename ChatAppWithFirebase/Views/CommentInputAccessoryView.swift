//
//  CommentInputAccessoryView.swift
//  ChatAppWithFirebase
//
//  Created by 大西玲花 on 2021/09/09.
//

import UIKit

protocol CommentInputAccessoryViewDelegate: AnyObject {
    func tappedSaveButton(text: String)
}

class CommentInputAccessoryView: UIView {
    
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var seveButton: UIButton!
    
    @IBAction func tappedSaveButton(_ sender: Any) {
        guard let text = commentTextView.text else { return }
        delegate?.tappedSaveButton(text: text)
    }
    
    weak var delegate: CommentInputAccessoryViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        nibInit()
        setupViews()
        autoresizingMask = .flexibleHeight
    }
    
    private func setupViews() {
        commentTextView.layer.cornerRadius = 15
        commentTextView.layer.borderColor = UIColor.rgb(red: 230, green: 230, blue: 230).cgColor
        commentTextView.layer.borderWidth = 1
        
        seveButton.layer.cornerRadius = 15
        seveButton.imageView?.contentMode = .scaleAspectFill
        seveButton.contentHorizontalAlignment = .fill
        seveButton.contentVerticalAlignment = .fill
        seveButton.isEnabled = false
        
        commentTextView.text = ""
        commentTextView.delegate = self
    }
    
    func removeText() {
        commentTextView.text = ""
        seveButton.isEnabled = false
    }
    
    override var intrinsicContentSize: CGSize {
        return .zero
    }
       
    private func nibInit() {
        let nib = UINib(nibName: "CommentInputAccessoryView", bundle: nil)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CommentInputAccessoryView: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty {
            seveButton.isEnabled = false
        } else {
            seveButton.isEnabled = true
        }
    }
    
}
