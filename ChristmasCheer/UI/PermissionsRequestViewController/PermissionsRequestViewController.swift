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
    func shouldDismissPermissionsRequestViewController(_ prvc: PermissionsRequestViewController)
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

/*
Remove namespacing for iOS 8, otherwise, nibs don't load properly
*/
@objc(PermissionsRequestViewController)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMessagingLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        ensurePermissionsRequired()
    }
    
    // MARK: Setup
    
    private func setup() {
        setupTitle()
        setupPermissionCallbacks()

        self.cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        self.confirmationButton.addTarget(self, action: #selector(confirmationButtonPressed), for: .touchUpInside)
    }
    
    private func setupTitle() {
        title = purpose.title
    }
    
    private func setupPermissionCallbacks() {
        let callback: (Bool) -> Void = { [weak self] _ in
            self?.performActionForCurrentPurpose()
        }
        
        switch purpose {
        case .LocationServices:
            LocationManager.sharedManager.locationStatusUpdated = callback
        case .Notifications:
            break // Doing later w/ completion, move location to this style
//            NotificationManager.authorizationStatusUpdated = callback
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
        labelBackgroundView.backgroundColor = UIColor.clear
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
    
    private func styleButtons(_ btns: UIButton...) {
        let buttonFont = ChristmasCrackFont.Regular(42.0).font
        let buttonTitleInsets = UIEdgeInsets(top: 6.0, left: 0, bottom: 0, right: 0)
        btns.forEach { btn in
            btn.backgroundColor = ColorPalette.SparklyRed.color
            btn.setTitleColor(ColorPalette.SparklyWhite.color, for: .normal)
            btn.titleLabel?.font = buttonFont
            btn.contentEdgeInsets = buttonTitleInsets
            btn.layer.cornerRadius = self.cancelButton.bounds.height / 4.0
        }
    }
    
    // MARK: Updates
    
    // Make sure something hasn't changed -- app did become active or viewDidAppear
    func ensurePermissionsRequired() {
        switch purpose {
        case .LocationServices
            where LocationManager.locationServicesEnabled:
            saveOrDismissInstallation()
        case .Notifications
            where NotificationManager.notificationsAuthorized:
            saveOrDismissInstallation()
        default:
            break
        }
    }
    
    private func saveOrDismissInstallation() {
        let installation = PFInstallation.current()
        if let installation = installation, !installation.isDirty {
            dismiss()
        } else {
            // We've approved location, but the installation hasn't been saved yet.
            registerInstallationWithServer()
        }
    }
    
    private func dismiss() {
        delegate?.shouldDismissPermissionsRequestViewController(self)
    }
    
    private func updateMessagingLabel() {
        messageLabel.text = purpose.requestDescription
    }
    
    // MARK: Button Presses
    
    @objc func cancelButtonPressed(_ sender: UIButton) {
        guard !isRegistering else { return }
        dismiss()
    }
    
    @objc func confirmationButtonPressed(_ sender: UIButton) {
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
        case .notDetermined:
            LocationManager.requestPermissions()
        case .authorizedAlways, .authorizedWhenInUse:
            saveOrDismissInstallation()
        case .denied, .restricted:
            showPermissionsDeniedAlert()
        }
    }
    
    private func performNotificationsPermissionAction() {
        switch NotificationManager.authorizationStatus {
        case .NotYetDetermined:
            requestNotificationPermissions()
        case .Authorized:
            saveOrDismissInstallation()
        case .Denied:
            showPermissionsDeniedAlert()
        }
    }
    
    private func requestNotificationPermissions() {
        PJProgressHUD.show(withStatus: "Registering your device with Apple. (Requires Internet)")
        NotificationManager.requestRemoteNotificationAuthorization { [weak self] auth in
            PJProgressHUD.hide()
            // If auth still isn't determined, then the request failed, usually due to no internet, or simulator
            guard auth != .NotYetDetermined else { return }
            self?.performActionForCurrentPurpose()
        }
    }
    
    // MARK: Register Installation
    
    private func registerInstallationWithServer() {
        guard !self.isRegistering else { return }
        PJProgressHUD.show(withStatus: "Registering With North Pole.")
        self.isRegistering = true
        PFInstallation.current()?.register { [weak self] result in
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
        present(alert, animated: true, completion: nil)
    }
    
    private func showPermissionsDeniedAlert(_ completion: @escaping () -> Void = {}) {
        let title = purpose.alertTitle
        let message = purpose.permissionDeniedMessage
        
        let alert = SCLAlertView()
        alert.addButton("Go To Settings") {
            UIApplication.cc_goToSettings()
        }
        alert.showSuccess(title, subTitle: message, closeButtonTitle: "Cancel")
        alert.completion = completion
        present(alert, animated: true, completion: nil)
    }
}

extension UIApplication {
    static func cc_goToSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        shared.openURL(url)
    }
}

extension PFInstallation {
    
    var hasRegisteredWithServer: Bool {
        return objectId != nil
    }
    
    func register(completion: @escaping (OrigResult<Int>) -> Void) {
        setTokenDataIfNecessary(ApplicationSettings.deviceTokenData)
        
        PJProgressHUD.show(withStatus: "Registering With North Pole.")
        Qu.Background {
            let result: OrigResult<Int>
            do {
                try self.save()
                result = .Success(1)
            } catch {
                result = .Failure(error)
            }
            
            Qu.Main {
                completion(result)
                PJProgressHUD.hide()
            }
        }
    }
    
    func setTokenDataIfNecessary(_ tokenData: Data?) {
        // If the app quit before saving to server, we persist the data here.
        guard deviceToken == nil, let data = tokenData else { return }
        setDeviceTokenFrom(data)
    }
}

extension PermissionsRequestViewController {
    private func showFailedToCreateInstallationAlert() {
        let title = "Oh No!"
        let message = "There must be a blizzard because I can't contact the elves to sign you up!  Check your connection and try to sign up again!"
        let confirmation = "Ok"
        let alert = SCLAlertView()
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
        present(alert, animated: true, completion: nil)
    }
}

class MarginLabel : UILabel {
    var marginInsets = UIEdgeInsets.zero
    override func drawText(in rect: CGRect) {
        let insetRect = rect.inset(by: marginInsets)
        super.drawText(in: insetRect)
    }
}
