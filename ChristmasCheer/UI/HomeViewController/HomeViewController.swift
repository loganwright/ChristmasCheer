//
//  ViewController.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/21/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import CoreLocation
import Parse
import Cartography

class HomeViewController: UIViewController, PermissionsRequestViewControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: Views
    
    @IBOutlet weak var christmasCheerButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    
    // MARK: Private Properties
    private var isPermissionsViewControllerPresented = false
    private var countdownTimer: NSTimer?
    private var hasPresentedNotificationPermissionsControllerAtLeastOnce = false
    
    private var viewIsCurrentlyPresented: Bool = false
    
    private let snowFallingView = MESnowFallView()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Sick of fighting weird view hierarchy issue, moving z position down
        snowFallingView.layer.zPosition = -1
        locationLabel.layer.zPosition = 0
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        viewIsCurrentlyPresented = true
        ensureSessionIsStillValid()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewIsCurrentlyPresented = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        christmasCheerButton.layer.cornerRadius = CGRectGetHeight(christmasCheerButton.bounds) / 2.0
    }
    
    // MARK: Permissions Management
    
    func ensureSessionIsStillValid() {
        guard !isPermissionsViewControllerPresented && viewIsCurrentlyPresented else { return }
        guard requestOrUpdateDisplayName() else { return }
        guard requestOrUpdateLocationPermissions() else { return }
        guard requestOrUpdateNotificationPermissions() else { return }
        
        ensureCanSendChristmasCheer()
    }
    
    private func requestOrUpdateDisplayName() -> Bool {
        if ApplicationSettings.hasEnteredName {
            title = ApplicationSettings.displayName
            return true
        } else {
            let nameEntryVC = NameEntryViewController()
            navigationController?.presentViewController(nameEntryVC, animated: true, completion: nil)
            return false
        }
    }
    
    private func requestOrUpdateLocationPermissions() -> Bool {
        switch CLLocationManager.authorizationStatus() {
        case .Authorized, .AuthorizedWhenInUse:
            startLocationServices()
            return true
        case .NotDetermined, .Denied, .Restricted:
            presentPermissionsViewControllerWithPurpose(.LocationServices)
            return false
        }
    }
    
    private func requestOrUpdateNotificationPermissions() -> Bool {
        let installation = PFInstallation.currentInstallation()
        let authorization = NotificationManager.authorizationStatus
        
        switch authorization {
        case .Authorized where installation.hasRegisteredWithServer:
            return true
        case .Denied, .NotYetDetermined where !hasPresentedNotificationPermissionsControllerAtLeastOnce:
            hasPresentedNotificationPermissionsControllerAtLeastOnce = true
            presentPermissionsViewControllerWithPurpose(.Notifications)
            return false
        default:
            return true
        }
    }
    
    private func ensureCanSendChristmasCheer() {
        if ApplicationSettings.canSendChristmasCheer {
            enableChristmasCheerButton()
        } else {
            disableChristmasCheerButton()
            startCountdown()
        }
    }
    
    private func presentPermissionsViewControllerWithPurpose(purpose: PermissionsRequestViewController.Purpose) {
        guard !isPermissionsViewControllerPresented else { return }
        
        let permissionsVC = PermissionsRequestViewController(purpose: purpose)
        permissionsVC.delegate = self
        let navigationVC = NavigationController(rootViewController: permissionsVC)

        isPermissionsViewControllerPresented = true
        presentViewController(navigationVC, animated: true, completion: nil)
    }
    
    // MARK: Setup
    
    private func setup() {
        setupNavBar()
        setupSnowfallView()
        setupLocationLabel()
        setupChristmasCheerButton()
        
        title = ApplicationSettings.displayName
        view.backgroundColor = ColorPalette.Green.color
    }
    
    private func setupNavBar() {
        let button: UIButton = UIButton(type: .System)
        button.setImage(UIImage(named: "gift_icon"), forState: .Normal)
        button.addTarget(self, action: "shareButtonPressed:", forControlEvents: .TouchUpInside)
        button.bounds = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.imageEdgeInsets = UIEdgeInsets(top: 11, left: 24, bottom: 13, right: 0)
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButton
    }
    
    private func setupSnowfallView() {
        view.addSubview(snowFallingView)
        constrain(snowFallingView, view) { snow, view in
            snow.top == view.top
            snow.left == view.left
            snow.bottom == view.bottom
            snow.right == view.right
        }
    }
    
    private func setupChristmasCheerButton() {
        christmasCheerButton.addTarget(self, action: "sendChristmasCheerButtonPressed:", forControlEvents: .TouchUpInside)
        christmasCheerButton.tintColor = ColorPalette.SparklyWhite.color
        christmasCheerButton.imageEdgeInsets = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
        christmasCheerButton.setBackgroundImage(UIImage(named: "red_christmas_bg"), forState: .Normal)
        christmasCheerButton.clipsToBounds = true
        christmasCheerButton.titleLabel?.font = ChristmasCrackFont.Regular(62.0).font
    }
    
    private func setupLocationLabel() {
        locationLabel.font = ChristmasCrackFont.Regular(52.0).font
        locationLabel.textColor = ColorPalette.SparklyWhite.color
        locationLabel.text = ApplicationSettings.locationName
    }
    
    // MARK: Christmas Cheer Sending
    
    dynamic private func sendChristmasCheerButtonPressed(sender: UIButton) {
        guard ensureSeasonIsOpenOrAlert() else { return }
        guard ensureCanSendCheerOrAlert() else { return }
        
        PJProgressHUD.showWithStatus("Contacting the North Pole ...")
        ParseHelper.sendRandomCheer { [weak self] result in
            switch result {
            case .Success(_):
                self?.showSendChristmasCheerSuccessAlert()
            case .Failure(_):
                self?.showSendChristmasCheerFailureAlert()
            }
            self?.ensureCanSendChristmasCheer()
            PJProgressHUD.hide()
        }
    }

    private func ensureSeasonIsOpenOrAlert() -> Bool {
        let isOpen: Bool
        if ApplicationSettings.isOffSeason {
            showOffSeasonChristmasCheerAlert()
            isOpen = false
        } else {
            isOpen = true
        }
        return isOpen
    }
    
    private func ensureCanSendCheerOrAlert() -> Bool {
        let canSendCheer: Bool
        if ApplicationSettings.canSendChristmasCheer {
            canSendCheer = true
        } else {
            showChristmasCheerWaitAlert()
            canSendCheer = false
        }
        return canSendCheer
    }
    
    private func showOffSeasonChristmasCheerAlert() {
        let title = "Off Season!"
        let message = "After a long holiday, the elves need some time to rest and recharge!  Christmas Cheer! will be back next holiday season!"
        let confirmation = "See you then!"
        let alert = SCLAlertView()
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
    }
    
    private func showChristmasCheerWaitAlert() {
        let title = "Hold It!"
        let message = "While we appreciate your enthusiasm, we used up all of our magic sending your last bit of Christmas Cheer!  Give us a moment to recharge before we can deliver more!"
        let confirmation = "Fine!"
        let alert = SCLAlertView()
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
    }
    
    private func showSendChristmasCheerFailureAlert() {
        let title = "Uh Oh!"
        let message = "There was a problem communicating with the elves, and it looks like we lost your message.  Check your connection and try again in a little bit."
        let confirmation = "Rabble!"
        let alert = SCLAlertView()
        alert.showError(title, subTitle: message, closeButtonTitle: confirmation)
    }
    
    private func showSendChristmasCheerSuccessAlert() {
        let title = "Woot!"
        let message = "Somewhere in the world, another person has just received your Christmas Cheer! We'll let you know if they return it to you!  Merry Christmas!"
        let confirmation = "Yay!"
        let alert = SCLAlertView()
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
    }
    
    // MARK: Buffer
    
    private func enableChristmasCheerButton() {
        christmasCheerButton.setTitle(nil, forState: .Normal)
        christmasCheerButton.setImage(UIImage.randomChristmasIcon(), forState: .Normal)
    }
    
    private func disableChristmasCheerButton() {
        christmasCheerButton.setImage(nil, forState: .Normal)
    }
    
    private func startCountdown() {
        guard countdownTimer == nil else { return }
        countdownTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "timerFired:", userInfo: nil, repeats: true)
    }
    
    dynamic private func timerFired(timer: NSTimer) {
        let timeSinceLastCheer = ApplicationSettings.timeSinceLastSentChristmasCheerTimestamp
        let timeLeftToWait = 1.minute - timeSinceLastCheer
        updateCheerButton(waitTime: timeLeftToWait)
    }
    
    private func updateCheerButton(waitTime waitTime: NSTimeInterval) {
        if waitTime < 0.0 {
            countdownTimer?.invalidate()
            countdownTimer = nil
            enableChristmasCheerButton()
        } else {
            let display = waitTime.displayString
            christmasCheerButton.setTitle(display, forState: .Normal)
        }
    }
    
    // MARK: Location Watch
    
    private func startLocationServices() {
        LocationManager.listenForPlacemark { [weak self] placemark in
            ApplicationSettings.locationName = placemark.cc_locationDescription
            self?.locationLabel.text = ApplicationSettings.locationName
        }
    }
    
    // MARK: PermissionsRequestViewControllerDelegate
    
    func shouldDismissPermissionsRequestViewController(prvc: PermissionsRequestViewController) {
        prvc.dismissViewControllerAnimated(true) { [weak self] in
            self?.isPermissionsViewControllerPresented = false
            self?.ensureSessionIsStillValid()
        }
    }
    
    // MARK: Sharing
    
    func shareButtonPressed(sender: UIBarButtonItem) {
        let text = "Help me spread some Christmas Cheer with this cool app I found!"
        let url = NSURL(string: "https://itunes.apple.com/app/id946161841")
        share(text: text, url: url)
    }
    
    func share(text text: String? = nil, image: UIImage? = nil, url: NSURL? = nil) {
        var sharingItems = [AnyObject]()
        if let text = text {
            sharingItems.append(text)
        }
        if let image = image {
            sharingItems.append(image)
        }
        if let url = url {
            sharingItems.append(url)
        }
        
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: Status Bar
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

private extension NSTimeInterval {
    var displayString: String {
        let minutes: Int = Int(self / 1.minute)
        let seconds: Int = Int(self % 1.minute)
        let secondsString = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        let display = "\(minutes):\(secondsString)"
        return display
    }
}


