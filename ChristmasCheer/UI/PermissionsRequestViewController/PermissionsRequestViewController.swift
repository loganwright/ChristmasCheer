//
//  PermissionsRequestViewController.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/26/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import Parse.PFInstallation

protocol PermissionsRequestViewControllerDelegate : class {
    func shouldDismissPermissionsRequestViewController(prvc: PermissionsRequestViewController)
}

extension PermissionsRequestViewController {
    enum Purpose {
        case LocationServices
        case Notifications
        
        var requestDescription: String {
            switch self {
            case .LocationServices:
                return "Location services are necessary so that we can show other users what region of the world their Christmas Cheer is coming from.  Don't worry, we won't share your location with any third parties.\n\nWould you like to enable location services now?"
            case .Notifications:
                return "Notifications are how users send each other Christmas Cheer.  To continue using this app and sharing in the fun, please enable notification services.\n\nWould you like to enable notifications now?"
            }
        }
    }
}

extension PermissionsRequestViewController.Purpose {
    
    var title: String {
        switch self {
        case .LocationServices:
            return "Location Permissions"
        case .Notifications:
            return "Notification Permissions"
        }
    }
    
    var alertTitle: String {
        switch self {
        case .LocationServices:
            return "Location Denied"
        case .Notifications:
            return "Notifications Denied"
        }
    }
    
    var permissionDeniedMessage: String {
        switch self {
        case .LocationServices:
            return "It appears you've already denied location settings for this app.  You'll need to update this in your device's settings in order to participate."
        case .Notifications:
            return "It appears you've already denied alert notifications for this app.  You'll need to update this in your device's settings in order to participate."
        }
    }
    
}

class PermissionsRequestViewController: UIViewController {
    
    // MARK: Constants
    
    private let PermissionsRequestLabelPadding: CGFloat = 8.0
    
    // MARK: Views
    
    @IBOutlet weak var labelBackgroundView: UIView!
    @IBOutlet weak var messageLabel: MarginLabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmationButton: UIButton!
    
    // MARK: Properties
    
    let purpose: Purpose
    weak var delegate: PermissionsRequestViewControllerDelegate?
    private var isRegistering = false
    
    // MARK: Initialization
    
    init(purpose: Purpose) {
        self.purpose = purpose
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        style()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateMessagingLabel()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        ensurePermissionsRequired()
    }
    
    // MARK: Setup
    
    private func setup() {
        setupTitle()
        setupPermissionCallbacks()
    }
    
    private func setupTitle() {
        title = purpose.title
    }
    
    private func setupPermissionCallbacks() {
        let callback: Bool -> Void = { [weak self] _ in
            self?.performActionForCurrentPurpose()
        }
        
        switch purpose {
        case .LocationServices:
            LocationManager.sharedManager.locationStatusUpdated = callback
        case .Notifications:
            NotificationManager.authorizationStatusUpdated = callback
        }
    }
    
    // MARK: Style
    
    private func style() {
        styleMessageLabel()
        styleLabelBackground()
        styleButtons(cancelButton, confirmationButton)
        navigationItem.hidesBackButton = true
        view.backgroundColor = ColorPalette.Green.color
    }
    
    private func styleLabelBackground() {
        labelBackgroundView.backgroundColor = UIColor.clearColor()
    }
    
    private func styleMessageLabel() {
        messageLabel.marginInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        messageLabel.numberOfLines = 0
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.minimumScaleFactor = 0.2
        messageLabel.backgroundColor = ColorPalette.TexturedBackground.color
        messageLabel.textColor = ColorPalette.DarkGray.color
        messageLabel.font = ChristmasCrackFont.Regular(42.0).font
        messageLabel.layer.cornerRadius = 5.0
        messageLabel.layer.masksToBounds = true
        messageLabel.clipsToBounds = true
    }
    
    private func styleButtons(btns: UIButton...) {
        let buttonFont = ChristmasCrackFont.Regular(42.0).font
        let buttonTitleInsets = UIEdgeInsets(top: 6.0, left: 0, bottom: 0, right: 0)
        btns.forEach { btn in
            btn.backgroundColor = ColorPalette.SparklyRed.color
            btn.setTitleColor(ColorPalette.SparklyWhite.color, forState: .Normal)
            btn.titleLabel?.font = buttonFont
            btn.contentEdgeInsets = buttonTitleInsets
            btn.layer.cornerRadius = CGRectGetHeight(self.cancelButton.bounds) / 4.0
        }
    }
    
    // MARK: Updates
    
    // Make sure something hasn't changed -- app did become active or viewDidAppear
    func ensurePermissionsRequired() {
        switch purpose {
        case .LocationServices
            where LocationManager.locationServicesEnabled:
            dismiss()
        case .Notifications
            where NotificationManager.notificationsAuthorized:
            handleNotificationsAlreadyAuthorized()
        default:
            break
        }
    }
    
    private func handleNotificationsAlreadyAuthorized() {
        let installation = PFInstallation.currentInstallation()
        if installation.hasRegisteredWithServer {
            dismiss()
        } else {
            // We've approved notifications, but we haven't set the installation up serverside. Save it.
            registerInstallationWithServer()
        }
    }
    
    private func dismiss() {
        delegate?.shouldDismissPermissionsRequestViewController(self)
    }
    
    private func updateMessagingLabel() {
        messageLabel.text = purpose.requestDescription
    }
    
    // MARK: Back Button Pressed
    
    func backButtonPressed(sender: UIBarButtonItem) {
        dismiss()
    }
    
    // MARK: Button Presses
    
    @IBAction func cancelButtonPressed(sender: UIButton) {
        guard !isRegistering else { return }
        dismiss()
    }
    
    @IBAction func confirmationButtonPressed(sender: UIButton) {
        guard !isRegistering else { return }
        performActionForCurrentPurpose()
    }
    
    // MARK: Action
    
    private func performActionForCurrentPurpose() {
        switch purpose {
        case .LocationServices:
            performLocationPermissionAction()
        case .Notifications:
            performNotificationsPermissionAction()
        }
    }
    
    private func performLocationPermissionAction() {
        switch CLLocationManager.authorizationStatus() {
        case .NotDetermined:
            LocationManager.requestPermissions()
        case .Authorized, .AuthorizedWhenInUse:
            dismiss()
        case .Denied, .Restricted:
            showPermissionsDeniedAlert()
        }
    }
    
    private func performNotificationsPermissionAction() {
        switch NotificationManager.authorizationStatus {
        case .NotYetDetermined:
            NotificationManager.requestRemoteNotificationAuthorization()
        case .Authorized:
            handleNotificationsAlreadyAuthorized()
        case .Denied:
            showPermissionsDeniedAlert()
        }
    }
    
    // MARK: Register Installation
    
    private func registerInstallationWithServer() {
        guard !self.isRegistering else { return }
        PJProgressHUD.showWithStatus("Registering With North Pole.")
        self.isRegistering = true
        PFInstallation.currentInstallation().register { [weak self] result in
            self?.isRegistering = false
            PJProgressHUD.hide()
            switch result {
            case .Success(_):
                self?.performActionForCurrentPurpose()
            case .Failure(_):
                self?.notifyFailureToSaveInstallationAlert()
            }
        }
    }
    
    private func notifyFailureToSaveInstallationAlert() {
        let title = "Uh Oh!"
        let message = "It looks like we were unable to register your device with the North Pole.  Please check your connection and try again in a little bit."
        let confirmation = "Ok"
        let alert = SCLAlertView()
        alert.showError(title, subTitle: message, closeButtonTitle: confirmation)
    }
    
    private func showPermissionsDeniedAlert(completion: Void -> Void = {}) {
        let title = purpose.alertTitle
        let message = purpose.permissionDeniedMessage
        
        let alert = SCLAlertView()
        alert.addButton("Go To Settings") {
            UIApplication.cc_goToSettings()
        }
        alert.showSuccess(title, subTitle: message, closeButtonTitle: "Cancel")
        alert.completion = completion
    }
}

extension UIApplication {
    static func cc_goToSettings() {
        guard let url = NSURL(string: UIApplicationOpenSettingsURLString) else { return }
        sharedApplication().openURL(url)
    }
}

extension PFInstallation {
    
    var hasRegisteredWithServer: Bool {
        return objectId != nil
    }
    
    func register(completion: Result<Void> -> Void) {
        setTokenDataIfNecessary(ApplicationSettings.deviceTokenData)
        
        PJProgressHUD.showWithStatus("Registering With North Pole.")
        Qu.Background {
            let result: Result<Void>
            do {
                try self.save()
                result = .Success()
            } catch {
                result = .Failure(error)
            }
            
            Qu.Main {
                completion(result)
                PJProgressHUD.hide()
            }
        }
    }
    
    func setTokenDataIfNecessary(tokenData: NSData?) {
        // If the app quit before saving to server, we persist the data here.
        guard deviceToken == nil, let data = tokenData else { return }
        setDeviceTokenFromData(data)
    }
}

class MarginLabel : UILabel {
    var marginInsets = UIEdgeInsetsZero
    override func drawTextInRect(rect: CGRect) {
        let insetRect = UIEdgeInsetsInsetRect(rect, marginInsets)
        super.drawTextInRect(insetRect)
    }
}