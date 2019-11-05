//
//  NameEntryViewController.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/22/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
//import Parse

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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listenForKeyboardChanges()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardObservers()
    }
    
    // MARK: Button Presses
    
    @IBAction func letsGoButtonPressed(_ sender: UIButton) {
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
    
    private func showNameConfirmationAlertForName(_ name: String) {
        guard let name = nameEntryTextField.text else { return }
        let title = "Are You Sure?"
        let message = "Once you've chosen a name, you won't be able to go back and change it.  Are you sure you want to be called \(name)?"
        let confirmation = "Wait, go back!"
        let alert = SCLAlertView()
        alert.addButton("Yup, I'm Sure!") { [weak self] in
            ApplicationSettings.displayName = name
            FeedbackSounds.SuccessSound.play()
//            self?.dismiss(animated: true, completion: nil)
        }
        alert.completion = { [weak self] in
            if ApplicationSettings.hasEnteredName {
                self?.dismiss(animated: true, completion: nil)
            }
        }
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
        present(alert, animated: true, completion: nil)
    }
    
    private func showProfanityFailureAlert() {
        let title = "Psst!"
        let message = "I just checked and it looks like that name is on our Naughty List. Are you sure you wouldn't prefer another name?"
        let confirmation = "Thanks!"
        let alert = SCLAlertView()
        alert.showError(title, subTitle: message, closeButtonTitle: confirmation)
        present(alert, animated: true, completion: nil)
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
        nameEntryTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        nameEntryTextField.delegate = self
    }
    
    private func setupChristmasTreeButton() {
        christmasTreeButton.imageView?.contentMode = .scaleAspectFit
        christmasTreeButton.isUserInteractionEnabled = false
        christmasTreeButton.tintColor = ColorPalette.SparklyRed.color
    }
    
    private func setupLetsGoButton() {
        letsGoButton.backgroundColor = ColorPalette.SparklyRed.color
        letsGoButton.titleLabel?.font = ChristmasCrackFont.Regular(42.0).font
    }
    
    // MARK: Keyboard Notifications
    
    private func listenForKeyboardChanges() {
        let defaultCenter = NotificationCenter.default
        defaultCenter.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    private func unregisterKeyboardObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: iOS 8 Keyboard Animations
    
    @objc dynamic private func keyboardWillChangeFrame(note: NSNotification) {
        guard let animation = note.animationDetail else { return }
        let viewHeight = view.bounds.height
        let minY = animation.keyboardFrame.minY
        let offset = viewHeight - minY
        let padding = CGFloat(8.0)
        view.layoutIfNeeded()
        bottomConstraint.constant = offset + padding
        UIView.animateWithKeyboard(animation) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: TextField Listeners

    @objc
    dynamic private func textFieldDidChange(textField: UITextField) {
        textField.clean()
        updateLetsGoButtonEnabled()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Let's Go Button
    
    private func updateLetsGoButtonEnabled() {
        let count = nameEntryTextField.text?.count ?? -1
        if (count > 2 && count < 18) {
            enableLetsGoButton()
        } else {
            disableLetsGoButton()
        }
    }
    
    private func enableLetsGoButton() {
        self.letsGoButton.isEnabled = true
        self.letsGoButton.alpha = 1.0
    }
    
    private func disableLetsGoButton() {
        self.letsGoButton.isEnabled = false
        self.letsGoButton.alpha = 0.5
    }
    
    // MARK: Status Bar
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension UITextField {
    func clean() {
        guard let text = text else { return }
        let charactersToRemove = CharacterSet.alphanumerics.inverted
        let trimmedReplacement = text.components(separatedBy: charactersToRemove)
        let replacementText = trimmedReplacement.reduce("") { $0 + $1 }
        self.text = replacementText
    }
}
