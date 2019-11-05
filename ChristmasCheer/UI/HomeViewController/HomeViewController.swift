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

/*
Remove namespacing for iOS 8, otherwise, nibs don't load properly
*/
@objc(HomeViewController)
class HomeViewController: UIViewController, PermissionsRequestViewControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: Views
    
    @IBOutlet weak var christmasCheerButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    
    // MARK: Private Properties
    private var isPermissionsViewControllerPresented = false
    private var countdownTimer: Timer?
    
    // Required to allow functionality w/o notifications, but Imma bug you about it.
    private var hasPresentedNotificationPermissionsControllerAtLeastOnce = false
    
    private var viewIsCurrentlyPresented: Bool = false
    
    private let snowFallingView = MESnowFallView()
    private var snowflakeButton: UIButton!
    
    private var repeater: Repeater?
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Sick of fighting weird view hierarchy issue, moving z position down
        snowFallingView.layer.zPosition = -1
        locationLabel.layer.zPosition = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewIsCurrentlyPresented = true
        updateSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewIsCurrentlyPresented = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        christmasCheerButton.layer.cornerRadius = christmasCheerButton.bounds.height / 2.0
    }
    
    // MARK: Unread Cheer Check
    
    private func checkForUnreturnedCheer() {
        repeater = Repeater(interval: 1.minute, fireImmediately: true) { [weak self] in
            self?.updateUnreturnedCheerBadge()
        }
    }
    
    
    private func updateUnreturnedCheerBadge() {
        ParseHelper.fetchUnreturnedCheer { [weak self] result in
            switch result {
            case let .Success(unreturnedCheer):
                self?.styleSnowButtonForCheerCount(unreturnedCheer.count)
            case let .Failure(error):
                print("error fetching unreturned cheer: \(error)")
            }
        }
    }
    
    private func styleSnowButtonForCheerCount(_ cheerCount: Int) {
        let title: String?
        let img: UIImage?
        let color: UIColor?
        let size: CGSize
        if cheerCount <= 0 {
            title = nil
            img = UIImage(named: "snowflake_icon")
            color = nil
            size = CGSize(width: 44, height: 44)
        } else {
            title = "\(cheerCount)"
            img = nil
            color = ColorPalette.SparklyWhite.color
            size = CGSize(width: 22, height: 22)
        }
        snowflakeButton.setTitle(title, for: .normal)
        snowflakeButton.setImage(img, for: .normal)
        snowflakeButton.backgroundColor = color
        snowflakeButton.bounds.size = size
        snowflakeButton.layer.cornerRadius = min(snowflakeButton.bounds.width, snowflakeButton.bounds.height) / 2
    }
    
    // MARK: Permissions Management
    
    func updateSession() {
        guard ensureSessionIsStillValid() else { return }
        checkForUnreturnedCheer()
    }
    
    private func ensureSessionIsStillValid() -> Bool {
        guard !isPermissionsViewControllerPresented && viewIsCurrentlyPresented else { return false }
        guard requestOrUpdateDisplayName() else { return false }
        guard requestOrUpdateLocationPermissions() else { return false }
        guard requestOrUpdateNotificationPermissions() else { return false }
        
        ensureCanSendChristmasCheer()
        return true
    }
    
    private func requestOrUpdateDisplayName() -> Bool {
        if ApplicationSettings.hasEnteredName {
            title = ApplicationSettings.displayName
            return true
        } else {
            let nameEntryVC = NameEntryViewController()
            navigationController?.present(nameEntryVC, animated: true, completion: nil)
            return false
        }
    }
    
    private func requestOrUpdateLocationPermissions() -> Bool {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            startLocationServices()
            return true
        case .notDetermined, .denied, .restricted:
            presentPermissionsViewControllerWithPurpose(purpose: .LocationServices)
            return false
        }
    }
    
    private func requestOrUpdateNotificationPermissions() -> Bool {
        let installation = PFInstallation.current()
        let authorization = NotificationManager.authorizationStatus
        
        switch authorization {
        case .Authorized where installation?.hasRegisteredWithServer == true:
            return true
        case .Denied where !hasPresentedNotificationPermissionsControllerAtLeastOnce,
             .NotYetDetermined where !hasPresentedNotificationPermissionsControllerAtLeastOnce:
            hasPresentedNotificationPermissionsControllerAtLeastOnce = true
            presentPermissionsViewControllerWithPurpose(purpose: .Notifications)
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
        present(navigationVC, animated: true, completion: nil)
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
        setupSnowflakeButton()
        setupShareButton()
    }
    
    private func setupSnowflakeButton() {
        snowflakeButton = UIButton(type: .system)
        snowflakeButton.addTarget(self, action: #selector(cheerListButtonPressed), for: .touchUpInside)
        snowflakeButton.bounds = CGRect(x: 0, y: 0, width: 44, height: 44)
        snowflakeButton.titleLabel?.font = ChristmasCrackFont.Regular(26).font
        snowflakeButton.setTitleColor(ColorPalette.SparklyRed.color, for: .normal)
        snowflakeButton.setImage(UIImage(named: "snowflake_icon"), for: .normal)
        snowflakeButton.imageEdgeInsets = UIEdgeInsets(top: 11, left: 0, bottom: 13, right: 24)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: snowflakeButton)
    }
    
    private func setupShareButton() {
        let button: UIButton = UIButton(type: .system)
        button.setImage(UIImage(named: "gift_icon"), for: .normal)
        button.addTarget(self, action: #selector(shareButtonPressed), for: .touchUpInside)
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
        christmasCheerButton.addTarget(self, action: #selector(sendChristmasCheerButtonPressed), for: .touchUpInside)
        christmasCheerButton.tintColor = ColorPalette.SparklyWhite.color
        christmasCheerButton.imageEdgeInsets = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
        christmasCheerButton.setBackgroundImage(UIImage(named: "red_christmas_bg"), for: .normal)
        christmasCheerButton.clipsToBounds = true
        christmasCheerButton.titleLabel?.font = ChristmasCrackFont.Regular(62.0).font
    }
    
    private func setupLocationLabel() {
        locationLabel.font = ChristmasCrackFont.Regular(52.0).font
        locationLabel.textColor = ColorPalette.SparklyWhite.color
        locationLabel.text = ApplicationSettings.locationName
    }
    
    // MARK: Christmas Cheer Sending
    @objc
    dynamic private func sendChristmasCheerButtonPressed(sender: UIButton) {
        sendCheer()
    }
    
    func sendCheer(_ completion: @escaping (Bool) -> Void = { _ in }) {
        guard ensureCanSendCheerOrAlert() else {
            completion(false)
            return
        }
        
        PJProgressHUD.show(withStatus: "Contacting the North Pole ...")
        ParseHelper.sendRandomCheer { [weak self] result in
            let success: Bool
            switch result {
            case let .Success(response) where response.isOffSeason:
                self?.showOffSeasonChristmasCheerAlert()
                success = false
            case let .Success(response):
                self?.showSendChristmasCheerSuccessAlert(successMessage: response.message)
                success = true
                ApplicationSettings.lastSentChristmasCheerTimestamp = NSDate()
            case .Failure(_):
                self?.showSendChristmasCheerFailureAlert()
                success = false
            }
            self?.ensureCanSendChristmasCheer()
            PJProgressHUD.hide()
            completion(success)
        }
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
    
    private func showSendChristmasCheerSuccessAlert(successMessage: String?) {
        let title = "Woot!"
        let message = successMessage
            ?? "Somewhere in the world, another person has just received your Christmas Cheer! We'll let you know if they return it to you!  Merry Christmas!"
        let confirmation = "Yay!"
        let alert = SCLAlertView()
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
    }
    
    // MARK: Buffer
    
    private func enableChristmasCheerButton() {
        christmasCheerButton.setTitle(nil, for: .normal)
        christmasCheerButton.setImage(UIImage.randomChristmasIcon(), for: .normal)
    }
    
    private func disableChristmasCheerButton() {
        christmasCheerButton.setImage(nil, for: .normal)
    }
    
    private func startCountdown() {
        guard countdownTimer == nil else { return }
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
    }

    @objc
    dynamic private func timerFired(_ timer: Timer) {
        let timeSinceLastCheer = ApplicationSettings.timeSinceLastSentChristmasCheerTimestamp
        let timeLeftToWait = 1.minute - timeSinceLastCheer
        updateCheerButton(waitTime: timeLeftToWait)
    }
    
    private func updateCheerButton(waitTime: TimeInterval) {
        if waitTime < 0.0 {
            countdownTimer?.invalidate()
            countdownTimer = nil
            enableChristmasCheerButton()
        } else {
            let display = waitTime.displayString
            christmasCheerButton.setTitle(display, for: .normal)
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
    
    func shouldDismissPermissionsRequestViewController(_ prvc: PermissionsRequestViewController) {
        prvc.dismiss(animated: true) { [weak self] in
            self?.isPermissionsViewControllerPresented = false
            self?.updateSession()
        }
    }
    
    // MARK: Sharing

    @objc
    func cheerListButtonPressed(sender: UIBarButtonItem) {
        let nav = NavigationController(rootViewController: CheerListViewController())
        navigationController?.present(nav, animated: true, completion: nil)
    }

    @objc
    func shareButtonPressed(sender: UIBarButtonItem) {
        let text = "Help me spread some Christmas Cheer with this cool app I found!"
        let url = NSURL(string: "https://itunes.apple.com/app/id946161841")
        share(text, url: url)
    }
    
    func share(_ text: String? = nil, image: UIImage? = nil, url: NSURL? = nil) {
        var sharingItems = [AnyObject]()
        if let text = text {
            sharingItems.append(text as AnyObject)
        }
        if let image = image {
            sharingItems.append(image)
        }
        if let url = url {
            sharingItems.append(url)
        }
        
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: Status Bar
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

private extension TimeInterval {
    var displayString: String {
        let minutes: Int = Int(self / 1.minute)
        let seconds: Int = Int(self.truncatingRemainder(dividingBy: 1.0.minute))
        let secondsString = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        let display = "\(minutes):\(secondsString)"
        return display
    }
}

private final class Repeater {
    let interval: TimeInterval
    let condition: () -> Bool
    let operation: () -> Void
    
    var queued = false
    
    init(interval: TimeInterval, fireImmediately: Bool = true, condition: @escaping () -> Bool = { true }, operation: @escaping () -> Void) {
        self.interval = interval
        self.condition = condition
        self.operation = operation
        
        if fireImmediately {
            fired()
        } else {
            queueRepeater()
        }
    }
    
    private func queueRepeater() {
        guard !queued else { return }
        queued = true
        After(interval) { [weak self] in
            self?.queued = true
            self?.fired()
        }
    }
    
    private func fired() {
        guard condition() else { return }
        operation()
        queueRepeater()
    }
    
}

//
//  After.swift
//
//  Created by Logan Wright on 10/24/15.
//  Copyright © 2015 lowriDevs. All rights reserved.
//

public func After(_ after: TimeInterval, op: @escaping () -> ()) {
    After(after, op: op, completion: nil)
}

public func After(_ after: TimeInterval, numberOfTimes: Int, op: @escaping () -> (), completion: @escaping () -> Void = {}) {
    let numberOfTimesLeft = numberOfTimes - 1
    let wrappedCompletion: () -> Void
    if numberOfTimesLeft > 0 {
        wrappedCompletion = {
            After(after, numberOfTimes: numberOfTimesLeft, op: op, completion: completion)
        }
    } else {
        wrappedCompletion = completion
    }
    
    After(after, op: op, completion: wrappedCompletion)
}

public func After(_ after: TimeInterval, op: @escaping () -> (), completion:  (() -> Void)?) {
    DispatchQueue.main.asyncAfter(deadline: .now() + after) {
        let blockOp = BlockOperation(block: op)
        blockOp.completionBlock = completion
        OperationQueue.main.addOperation(blockOp)
    }
//    let seconds = Int64(after * Double(NSEC_PER_SEC))
////    let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, seconds)
//    dispatch_after
//    dispatch_after(dispatchTime, dispatch_get_main_queue()) {
//        let blockOp = NSBlockOperation(block: op)
//        blockOp.completionBlock = completion
//        OperationQueue.main.add(blockOp)
//    }
}
