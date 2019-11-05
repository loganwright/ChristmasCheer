//
//  ContactViewController.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/27/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import Cartography

// MARK: ContactViewController

/*
Remove namespacing for iOS 8, otherwise, nibs don't load properly
*/
@objc(ContactViewController)
class ContactViewController: UIViewController, UITextViewDelegate {

    private var bottomTextViewConstraint: NSLayoutConstraint!
    private let textView = UITextView()
    private let sendButton = UIButton(type: .system)
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listenForKeyboardChanges()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardObservers()
    }

    // MARK: Setup
    
    private func setup() {
        title = "Support / Feedback"
        setupCancelButton()
        setupSendButton()
        setupTextView()
    }
    
    private func setupCancelButton() {
        let cancelButton = UIButton(type: .system) as UIButton
        cancelButton.setTitleColor(ColorPalette.SparklyWhite.color, for: .normal)
        cancelButton.bounds = CGRect(x: 0, y: 0, width: 44, height: 44)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = ChristmasCrackFont.Regular(32.0).font
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
    }
    
    private func setupSendButton() {
        sendButton.setTitleColor(ColorPalette.SparklyWhite.color, for: .normal)
        sendButton.frame = CGRect(x: 10, y: 0, width: 44, height: 44)
        sendButton.setTitle("Send", for: .normal)
        sendButton.titleLabel?.font = ChristmasCrackFont.Regular(32.0).font
        sendButton.addTarget(self, action: #selector(sendButtonPressed), for: .touchUpInside)
        sendButton.isHidden = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: sendButton)
    }
    
    private func setupTextView() {
        textView.tintColor = ColorPalette.Green.color
        textView.font = ChristmasCrackFont.Regular(42.0).font
        textView.backgroundColor = ColorPalette.TexturedBackground.color
        textView.textColor = ColorPalette.DarkGray.color
        textView.delegate = self
        view.addSubview(textView)
        setupTextViewConstraints()
    }
    
    private func setupTextViewConstraints() {
        constrain(textView, view) { textView, view in
            textView.top == view.top
            textView.left == view.left
            textView.right == view.right
        }
        bottomTextViewConstraint = NSLayoutConstraint(item: self.textView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        view.addConstraint(bottomTextViewConstraint)
    }
    
    // MARK: Button Presses

    @objc
    func cancelButtonPressed(sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    @objc
    func sendButtonPressed(sender: UIBarButtonItem) {
        textView.resignFirstResponder()
        PJProgressHUD.show(withStatus: "Contacting the North Pole ...")
        ParseHelper.sendFeedback(textView.text) { [weak self] result in
            switch result {
            case .Success(_):
                self?.showSubmissionSuccessAlert()
            case .Failure(_):
                self?.showSubmissionFailureAlert()
            }
            PJProgressHUD.hide()
        }
    }
    
    // MARK: Success / Failure Alert
    
    private func showSubmissionSuccessAlert() {
        let title = "Thanks!"
        let message = "Thanks for taking the time to let us know how we're doing.  We'll make sure a team of elves check it out ASAP!"
        let confirmation = "Merry Christmas!"
        let alert = SCLAlertView()
        alert.completion = {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
        FeedbackSounds.SuccessSound.play()
    }
    
    private func showSubmissionFailureAlert() {
        let title = "Uh Oh!"
        let message = "It looks like some reindeer might have gotten lost. Check your connection to make sure we can find them!"
        let confirmation = "Balderdash!"
        let alert = SCLAlertView()
        alert.showError(title, subTitle: message, closeButtonTitle: confirmation)
        FeedbackSounds.ErrorSound.play()
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        sendButton.isHidden = textView.text.isEmpty
    }
    
    // MARK: Keyboard Notifications
    
    private func listenForKeyboardChanges() {
        let defaultCenter = NotificationCenter.default
        defaultCenter.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        defaultCenter.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func unregisterKeyboardObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Keyboard Listeners

    @objc
    func keyboardWillShow(note: NSNotification) {
        guard let animation = note.animationDetail else { return }
        view.layoutIfNeeded()
        bottomTextViewConstraint.constant = -animation.keyboardHeight
        UIView.animateWithKeyboard(animation) {
            self.view.layoutIfNeeded()
        }
    }

    @objc
    func keyboardWillHide(note: NSNotification) {
        guard let animation = note.animationDetail else { return }
        view.layoutIfNeeded()
        bottomTextViewConstraint.constant = 0.0
        UIView.animateWithKeyboard(animation) {
            self.view.layoutIfNeeded()
        }
    }
}

struct KeyboardAnimationDetail {
    let duration: TimeInterval
    let animationCurve: UIView.AnimationOptions
    let keyboardHeight: CGFloat
    let keyboardFrame: CGRect
}

extension NSNotification {
    var animationDetail: KeyboardAnimationDetail? {
        guard
        let keyboardAnimationDetail = userInfo,
            let duration = keyboardAnimationDetail[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let keyboardFrame = (keyboardAnimationDetail[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
        let animationCurve = keyboardAnimationDetail[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return nil }
        
        let keyboardHeight = UIApplication.shared.statusBarOrientation.isPortrait
            ? keyboardFrame.height : keyboardFrame.width
        return KeyboardAnimationDetail(
            duration: duration,
            animationCurve: UIView.AnimationOptions(rawValue: animationCurve),
            keyboardHeight: keyboardHeight,
            keyboardFrame: keyboardFrame
        )
    }
}

extension UIView {
    static func animateWithKeyboard(_ keyboardAnimationDetail: KeyboardAnimationDetail, animations: @escaping () -> Void) {
        UIView.animate(
            withDuration: keyboardAnimationDetail.duration,
            delay: 0.0,
            options: keyboardAnimationDetail.animationCurve,
            animations: animations,
            completion: { _ in }
        )
    }
}
