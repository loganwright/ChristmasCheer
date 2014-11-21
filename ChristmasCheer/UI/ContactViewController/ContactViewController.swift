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

class ContactViewController: UIViewController, UITextViewDelegate {

    private var bottomTextViewConstraint: NSLayoutConstraint!
    private let textView = UITextView()
    private let sendButton = UIButton(type: .System)
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        listenForKeyboardChanges()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    override func viewWillDisappear(animated: Bool) {
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
        let cancelButton = UIButton(type: .System) as UIButton
        cancelButton.setTitleColor(ColorPalette.SparklyWhite.color, forState: .Normal)
        cancelButton.bounds = CGRect(x: 0, y: 0, width: 44, height: 44)
        cancelButton.setTitle("Cancel", forState: .Normal)
        cancelButton.titleLabel?.font = ChristmasCrackFont.Regular(32.0).font
        cancelButton.addTarget(self, action: "cancelButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
    }
    
    private func setupSendButton() {
        sendButton.setTitleColor(ColorPalette.SparklyWhite.color, forState: .Normal)
        sendButton.frame = CGRect(x: 10, y: 0, width: 44, height: 44)
        sendButton.setTitle("Send", forState: .Normal)
        sendButton.titleLabel?.font = ChristmasCrackFont.Regular(32.0).font
        sendButton.addTarget(self, action: "sendButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        sendButton.hidden = true
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
        bottomTextViewConstraint = NSLayoutConstraint(item: self.textView, attribute: .Bottom, relatedBy: .Equal, toItem: self.view, attribute: .Bottom, multiplier: 1.0, constant: 0.0)
        view.addConstraint(bottomTextViewConstraint)
    }
    
    // MARK: Button Presses
    
    func cancelButtonPressed(sender: UIBarButtonItem) {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func sendButtonPressed(sender: UIBarButtonItem) {
        textView.resignFirstResponder()
        PJProgressHUD.showWithStatus("Contacting the North Pole ...")
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
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
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
        sendButton.hidden = textView.text.isEmpty
    }
    
    // MARK: Keyboard Notifications
    
    private func listenForKeyboardChanges() {
        let defaultCenter = NSNotificationCenter.defaultCenter()
        defaultCenter.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        defaultCenter.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    private func unregisterKeyboardObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Keyboard Listeners
    
    func keyboardWillShow(note: NSNotification) {
        guard let animation = note.animationDetail else { return }
        view.layoutIfNeeded()
        bottomTextViewConstraint.constant = -animation.keyboardHeight
        UIView.animateWithKeyboard(animation) {
            self.view.layoutIfNeeded()
        }
    }
    
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
    let duration: NSTimeInterval
    let animationCurve: UIViewAnimationOptions
    let keyboardHeight: CGFloat
    let keyboardFrame: CGRect
}

extension NSNotification {
    var animationDetail: KeyboardAnimationDetail? {
        guard
        let keyboardAnimationDetail = userInfo,
        let duration = keyboardAnimationDetail[UIKeyboardAnimationDurationUserInfoKey] as? NSTimeInterval,
        let keyboardFrame = (keyboardAnimationDetail[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue(),
        let animationCurve = keyboardAnimationDetail[UIKeyboardAnimationCurveUserInfoKey] as? UInt
        else { return nil }
        
        let keyboardHeight = UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication().statusBarOrientation)
            ? CGRectGetHeight(keyboardFrame) : CGRectGetWidth(keyboardFrame)
        return KeyboardAnimationDetail(
            duration: duration,
            animationCurve: UIViewAnimationOptions(rawValue: animationCurve),
            keyboardHeight: keyboardHeight,
            keyboardFrame: keyboardFrame
        )
    }
}

extension UIView {
    static func animateWithKeyboard(keyboardAnimationDetail: KeyboardAnimationDetail, animations: Void -> Void) {
        UIView.animateWithDuration(
            keyboardAnimationDetail.duration,
            delay: 0.0,
            options: keyboardAnimationDetail.animationCurve,
            animations: animations,
            completion: { _ in }
        )
    }
}
