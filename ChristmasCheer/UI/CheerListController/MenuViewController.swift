//
//  MenuViewController.swift
//  FriendLender
//
//  Created by Logan Wright on 9/24/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import MessageUI
import Parse

// MARK: MenuViewTableViewSection

private struct MenuViewTableViewSection {
    enum SectionType {
        case Unresponded, Returned, Received
    }

    let title: String?
    let sectionType: SectionType
    let associatedCheer: [ChristmasCheerNotification]
}

// MARK: MenuViewController

class MenuViewController: UIViewController, MenuViewCellDelegate {
    
    @IBOutlet weak var statusBarCover: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var attributionButton: UIButton!
    @IBOutlet weak var supportButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var rateButton: UIButton!
    
    // MARK: Constants
    
    private let MenuTableViewGeneralCellIdentifier = "MenuTableViewGeneralCellIdentifier"
    private let MenuTableViewDatePickerCellIdentifier = "MenuTableViewDatePickerCellIdentifier"
    
    // MARK: Properties
    
    private var tableViewData: [MenuViewTableViewSection] = []
    
    // MARK: Lifecycle
   
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        stylize()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        resize()
    }
    
    func resize() {
        let rect = UIScreen.mainScreen().bounds
        let width = CGRectGetWidth(rect)
        let height = CGRectGetHeight(rect)
        let smallerEdge = width < height ? width : height
        let longerEdge = width < height ? height : width
        self.view.frame = CGRect(x: 0, y: 0, width: smallerEdge * 0.8, height: longerEdge)
    }
    
    // MARK: Setup
    
    func setup() {
        setupTableView()
    }
    
    func setupTableView() {
        tableView.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = UIView()
        tableView.registerCell(MenuViewCell.self)
        tableView.registerHeader(AttributionHeaderCell.self)
    }
    
    // MARK: Stylizing
    
    func stylize() {
        view.backgroundColor = ColorPalette.TexturedBackground.color
        statusBarCover.backgroundColor = ColorPalette.Green.color
        tableView.separatorColor = ColorPalette.DarkGray.color
        
        stylizeButtonTray()
    }
    
    func stylizeButtonTray() {
        [attributionButton, supportButton, rateButton, infoButton]
            .forEach { button in
                button.backgroundColor = ColorPalette.Green.color
                button.tintColor = ColorPalette.SparklyWhite.color
            }
    }
    
    // MARK: TableView Reload
    
    func fetchDataAndReloadTableView() {
        PJProgressHUD.showWithStatus("Contacting the North Pole ...")
        ParseHelper.fetchNotifications { result in
            switch result {
            case .Success(let notifications):
                self.setupDataAndReloadTableViewWithRawNotifications(notifications)
            case .Failure(let error):
                print("Got error: \(error)")
                self.notifyFetchFailure()
            }
            PJProgressHUD.hide()
        }
    }
    
    func setupDataAndReloadTableViewWithRawNotifications(rawNotifications: [ChristmasCheerNotification]) {
        let notifications = rawNotifications.sort { $0.createdAt > $1.createdAt }
        let unresponded = notifications.filter { !$0.hasBeenRespondedTo }
        let receivedCheer = notifications.filter { $0.initiationNoteId == nil && $0.hasBeenRespondedTo }
        let returnedCheer = notifications.filter { $0.initiationNoteId != nil }
        
        tableViewData = [
            MenuViewTableViewSection(title: nil, sectionType: .Unresponded, associatedCheer: unresponded),
            MenuViewTableViewSection(title: "Received Cheer", sectionType: .Received, associatedCheer: receivedCheer),
            MenuViewTableViewSection(title: "Returned Cheer", sectionType: .Returned, associatedCheer: returnedCheer)
        ]
        
        self.reloadTableView()
    }

    func notifyFetchFailure() {
        let title = "Uh Oh!"
        let message = "There was a problem communicating with the elves, and it looks like we couldn't find your Christmas Cheer.  Check your connection and try again in a little bit. "
        let confirmation = "Dag Nabit!"
        SCLAlertView().showError(title, subTitle: message, closeButtonTitle: confirmation)
    }
    
    func reloadTableView() {
        Qu.Main {
            self.tableView.reloadData()
        }
    }
    
    // MARK: MenuViewCellDelegate
    
    func menuViewCell(menuViewCell: MenuViewCell, didPressReturnCheerButtonForOriginalNote originalNote: ChristmasCheerNotification) {
        PJProgressHUD.showWithStatus("Contacting the North Pole ...")
        ParseHelper.returnCheer(originalNote) { [weak self] result in
            guard let welf = self else { return }
            switch result {
            case .Success(_):
                let rawNotifications = welf.tableViewData
                    .flatMap { $0.associatedCheer }
                welf.setupDataAndReloadTableViewWithRawNotifications(rawNotifications)
                welf.notifyReturnCheerSendSuccessForName(originalNote.fromName)
            case .Failure(_):
                welf.notifyReturnCheerSendFailure()
            }
            PJProgressHUD.hide()
        }
    }
    
    private func notifyReturnCheerSendFailure() {
        let title = "Uh Oh!"
        let message = "There was a problem communicating with the elves, and it looks like we couldn't send your response.  Check your connection and try again in a little bit. "
        let confirmation = "Hogwash!"
        let alert = SCLAlertView()
        alert.showError(title, subTitle: message, closeButtonTitle: confirmation)
    }

    private func notifyReturnCheerSendSuccessForName(toName: String) {
        let title = "Woot!"
        let message = "The reindeer have your message and they'll be passing it on to \(toName).  Thanks for embracing the Christmas spirit!"
        let confirmation = "I'm Awesome!"
        let alert = SCLAlertView()
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
    }
    
    // MARK: Button Presses
    
    @IBAction func attributionButtonPressed(sender: UIButton) {
        let attributionVC = AttributionViewController()
        let nav = NavigationController(rootViewController: attributionVC)
        presentViewController(nav, animated: true, completion: nil)
    }
    
    @IBAction func supportButtonPressed(sender: UIButton) {
        let contactVC = ContactViewController()
        let nav = NavigationController(rootViewController: contactVC)
        presentViewController(nav, animated: true, completion: nil)
    }

    @IBAction func rateButtonPressed(sender: UIButton) {
        showRatingAlert()
    }
    
    @IBAction func infoButtonPressed(sender: UIButton) {
        showInfoAlert()
    }
    
    private func showInfoAlert() {
        let title = "Christmas Cheer!"
        let message = "Christmas Cheer was made to spread a little bit of random Christmas spirit across the world.  Press the big red button to send some cheer and see if anyone returns it!"
        let confirmation = "Sounds Fun!"
        let alert = SCLAlertView()
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
    }
    
    private func showRatingAlert() {
        let title = "Rate?"
        let message = "Thanks for taking the time to rate this app!  Would you like to go to the app store now?"
        let confirmation = "Maybe later."
        let alert = SCLAlertView()
        alert.addButton("Let's Go!", action: { () -> Void in
            let appStoreURL = NSURL(string: "itms-apps://itunes.apple.com/app/id946161841")!
            UIApplication.sharedApplication().openURL(appStoreURL)
        })
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
    }
}

extension MenuViewController : UITableViewDataSource {

    // MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tableViewData.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = self.tableViewData[section]
        return section.associatedCheer.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = self.tableViewData[indexPath.section]
        let cheer = section.associatedCheer[indexPath.row]
        let cell: MenuViewCell = tableView.dequeueCell(indexPath)
        cell.configure(cheer)
        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header: AttributionHeaderCell = tableView.dequeueHeader(section)
        let menuSection = tableViewData[section]
        header.label.text = menuSection.title
        return header
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = tableViewData[section]
        return section.title == nil ? 0 : 66
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let heightWithButton: CGFloat = 260
        let heightWithOutButton: CGFloat = 200
        let section = tableViewData[indexPath.section]
        let note = section.associatedCheer[indexPath.row]
        return note.hasBeenRespondedTo ? heightWithOutButton : heightWithButton
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
