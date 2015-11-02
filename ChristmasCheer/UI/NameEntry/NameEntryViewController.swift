//
//  NameEntryViewController.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/22/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import Parse

/*
Remove namespacing for iOS 8, otherwise, nibs don't load properly
*/
@objc(NameEntryViewController)
class NameEntryViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var christmasTreeButton: UIButton!
    @IBOutlet weak var letsGoButton: UIButton!
    @IBOutlet weak var nameEntryTextField: UITextField!
    
    // MARK: LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        listenForKeyboardChanges()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardObservers()
    }
    
    // MARK: Button Presses
    
    @IBAction func letsGoButtonPressed(sender: UIButton) {
        nameEntryTextField.resignFirstResponder()
        guard let text = nameEntryTextField.text else { return }
        
        let isSafe = ProfanityFilter.isWordSafe(text)
        if isSafe {
            showNameConfirmationAlertForName(text)
        } else {
            FeedbackSounds.ErrorSound.play()
            showProfanityFailureAlert()
        }
    }
    
    private func showNameConfirmationAlertForName(name: String) {
        guard let name = nameEntryTextField.text else { return }
        let title = "Are You Sure?"
        let message = "Once you've chosen a name, you won't be able to go back and change it.  Are you sure you want to be called \(name)?"
        let confirmation = "Wait, go back!"
        let alert = SCLAlertView()
        alert.addButton("Yup, I'm Sure!") { [weak self] in
            ApplicationSettings.displayName = name
            FeedbackSounds.SuccessSound.play()
            self?.dismissViewControllerAnimated(true, completion: nil)
        }
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
    }
    
    private func showProfanityFailureAlert() {
        let title = "Psst!"
        let message = "I just checked and it looks like that name is on our Naughty List. Are you sure you wouldn't prefer another name?"
        let confirmation = "Thanks!"
        let alert = SCLAlertView()
        alert.showError(title, subTitle: message, closeButtonTitle: confirmation)
    }

    // MARK: Setup
    
    private func setup() {
        disableLetsGoButton()
        setupTextField()
        setupChristmasTreeButton()
        setupLetsGoButton()
        
        view.backgroundColor = ColorPalette.Green.color
    }
    
    private func setupTextField() {
        nameEntryTextField.font = ChristmasCrackFont.Regular(42.0).font
        nameEntryTextField.tintColor = ColorPalette.Green.color
        nameEntryTextField.textColor = ColorPalette.DarkGray.color
        nameEntryTextField.backgroundColor = ColorPalette.TexturedBackground.color
        nameEntryTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        nameEntryTextField.delegate = self
    }
    
    private func setupChristmasTreeButton() {
        christmasTreeButton.imageView?.contentMode = .ScaleAspectFit
        christmasTreeButton.userInteractionEnabled = false
        christmasTreeButton.tintColor = ColorPalette.SparklyRed.color
    }
    
    private func setupLetsGoButton() {
        letsGoButton.backgroundColor = ColorPalette.SparklyRed.color
        letsGoButton.titleLabel?.font = ChristmasCrackFont.Regular(42.0).font
    }
    
    // MARK: Keyboard Notifications
    
    private func listenForKeyboardChanges() {
        let defaultCenter = NSNotificationCenter.defaultCenter()
        defaultCenter.addObserver(self, selector: "keyboardWillChangeFrame:", name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    private func unregisterKeyboardObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: iOS 8 Keyboard Animations
    
    dynamic private func keyboardWillChangeFrame(note: NSNotification) {
        guard let animation = note.animationDetail else { return }
        let viewHeight = CGRectGetHeight(view.bounds)
        let minY = CGRectGetMinY(animation.keyboardFrame)
        let offset = viewHeight - minY
        let padding = CGFloat(8.0)
        view.layoutIfNeeded()
        bottomConstraint.constant = offset + padding
        UIView.animateWithKeyboard(animation) { 
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: TextField Listeners
    
    dynamic private func textFieldDidChange(textField: UITextField) {
        textField.clean()
        updateLetsGoButtonEnabled()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Let's Go Button
    
    private func updateLetsGoButtonEnabled() {
        let count = nameEntryTextField.text?.characters.count
        if count > 2 && count < 18 {
            enableLetsGoButton()
        } else {
            disableLetsGoButton()
        }
    }
    
    private func enableLetsGoButton() {
        self.letsGoButton.enabled = true
        self.letsGoButton.alpha = 1.0
    }
    
    private func disableLetsGoButton() {
        self.letsGoButton.enabled = false
        self.letsGoButton.alpha = 0.5
    }
    
    // MARK: Status Bar
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

extension UITextField {
    func clean() {
        guard let text = text else { return }
        let charactersToRemove = NSCharacterSet.alphanumericCharacterSet().invertedSet
        let trimmedReplacement = text.componentsSeparatedByCharactersInSet(charactersToRemove)
        let replacementText = trimmedReplacement.reduce("") { $0 + $1 }
        self.text = replacementText
    }
}
