//
//  CheerListViewController.swift
//  FriendLender
//
//  Created by Logan Wright on 9/24/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import MessageUI
//import Parse

// MARK: CheerListTableViewSection

private struct CheerListTableViewSection {
    enum SectionType {
        case Unresponded, Returned, Received
    }

    let title: String?
    let sectionType: SectionType
    let associatedCheer: [ChristmasCheerNotification]
}

// MARK: CheerListViewController

/*
Remove namespacing for iOS 8, otherwise, nibs don't load properly
*/
@objc(CheerListViewController)
class CheerListViewController: UIViewController, CheerListCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var attributionButton: UIButton!
    @IBOutlet weak var supportButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var rateButton: UIButton!
    
    // MARK: Properties
    
    private var tableViewData: [CheerListTableViewSection] = []
    
    // MARK: Lifecycle
   
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        stylize()
        fetchDataAndReloadTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resize()
    }
    
    func resize() {
        let rect = UIScreen.main.bounds
        let width = rect.width
        let height = rect.height
        let smallerEdge = width < height ? width : height
        let longerEdge = width < height ? height : width
        self.view.frame = CGRect(x: 0, y: 0, width: smallerEdge * 0.8, height: longerEdge)
    }
    
    // MARK: Setup
    
    func setup() {
        setupNavBar()
        setupTableView()
        
        title = "Cheer List"
    }
    
    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem
            .cc_backBarButtonItem(self, selector: #selector(backButtonPressed))
    }
    
    func setupTableView() {
        tableView.backgroundColor = UIColor.clear
        tableView.tableFooterView = UIView()
        tableView.registerCell(CheerListCell.self)
        tableView.registerHeader(AttributionHeaderCell.self)
    }
    
    // MARK: Stylizing
    
    func stylize() {
        view.backgroundColor = ColorPalette.TexturedBackground.color
        tableView.separatorColor = ColorPalette.DarkGray.color
        
        stylizeButtonTray()
    }
    
    func stylizeButtonTray() {
        [attributionButton, supportButton, rateButton, infoButton]
            .forEach { button in
                button?.backgroundColor = ColorPalette.Green.color
                button?.tintColor = ColorPalette.SparklyWhite.color
            }
    }
    
    // MARK: TableView Reload
    
    func fetchDataAndReloadTableView() {
        PJProgressHUD.show(withStatus: "Contacting the North Pole ...")
        ParseHelper.fetchNotifications { result in
            switch result {
            case .Success(let notifications):
                self.setupDataAndReloadTableViewWithRawNotifications(rawNotifications: notifications)
            case .Failure(let error):
                print("Got error: \(error)")
                self.notifyFetchFailure()
            }
            PJProgressHUD.hide()
        }
    }
    
    func setupDataAndReloadTableViewWithRawNotifications(rawNotifications: [ChristmasCheerNotification]) {
        let notifications = rawNotifications.sorted { $0.createdAt ?? Date(timeIntervalSince1970: 0) > $1.createdAt ?? Date(timeIntervalSince1970: 0) }
        let unresponded = notifications.filter { !$0.hasBeenRespondedTo }
        let receivedCheer = notifications.filter { $0.initiationNoteId == nil && $0.hasBeenRespondedTo }
        let returnedCheer = notifications.filter { $0.initiationNoteId != nil }
        
        tableViewData = [
            CheerListTableViewSection(title: nil, sectionType: .Unresponded, associatedCheer: unresponded),
            CheerListTableViewSection(title: "Received Cheer", sectionType: .Received, associatedCheer: receivedCheer),
            CheerListTableViewSection(title: "Returned Cheer", sectionType: .Returned, associatedCheer: returnedCheer)
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
    
    // MARK: CheerListCellDelegate
    
    func cheerListCell(_ menuViewCell: CheerListCell, didPressReturnCheerButtonForOriginalNote originalNote: ChristmasCheerNotification) {
        PJProgressHUD.show(withStatus: "Contacting the North Pole ...")
        ParseHelper.returnCheer(originalNote) { [weak self] result in
            guard let welf = self else { return }
            switch result {
            case let .Success(originalNote, response):
                let rawNotifications = welf.tableViewData
                    .flatMap { $0.associatedCheer }
                welf.setupDataAndReloadTableViewWithRawNotifications(rawNotifications: rawNotifications)
                welf.notifyReturnCheerSendSuccessForName(toName: originalNote.fromName, successMessage: response.message)
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
        present(alert, animated: true, completion: nil)
    }

    private func notifyReturnCheerSendSuccessForName(toName: String, successMessage: String?) {
        let title = "Woot!"
        let message = successMessage
            ?? "The reindeer have your message and they'll be passing it on to \(toName).  Thanks for embracing the Christmas spirit!"
        let confirmation = "I'm Awesome!"
        let alert = SCLAlertView()
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: Button Presses

    @objc
    func backButtonPressed(sender: UIButton) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func attributionButtonPressed(_ sender: UIButton) {
        let attributionVC = AttributionViewController()
        let nav = NavigationController(rootViewController: attributionVC)
        present(nav, animated: true, completion: nil)
    }
    
    @IBAction func supportButtonPressed(_ sender: UIButton) {
        let contactVC = ContactViewController()
        let nav = NavigationController(rootViewController: contactVC)
        present(nav, animated: true, completion: nil)
    }

    @IBAction func rateButtonPressed(_ sender: UIButton) {
        showRatingAlert()
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        showInfoAlert()
    }
    
    private func showInfoAlert() {
        let title = "Christmas Cheer!"
        let message = "Christmas Cheer was made to spread a little bit of random Christmas spirit across the world.  Press the big red button to send some cheer and see if anyone returns it!"
        let confirmation = "Sounds Fun!"
        let alert = SCLAlertView()
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
        present(alert, animated: true, completion: nil)
    }
    
    private func showRatingAlert() {
        let title = "Rate?"
        let message = "Thanks for taking the time to rate this app!  Would you like to go to the app store now?"
        let confirmation = "Maybe later."
        let alert = SCLAlertView()
        alert.addButton("Let's Go!", action: { () -> Void in
            let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id946161841")!
            UIApplication.shared.openURL(appStoreURL)
        })
        alert.showSuccess(title, subTitle: message, closeButtonTitle: confirmation)
        present(alert, animated: true, completion: nil)
    }
}

extension CheerListViewController: UITableViewDataSource {


    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = self.tableViewData[section]
        return section.associatedCheer.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = self.tableViewData[indexPath.section]
        let cheer = section.associatedCheer[indexPath.row]
        let cell: CheerListCell = tableView.dequeueCell(indexPath: indexPath)
        cell.configure(note: cheer)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header: AttributionHeaderCell = tableView.dequeueHeader(section: section)
        let menuSection = tableViewData[section]
        header.label.text = menuSection.title
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = tableViewData[section]
        return section.title == nil ? 0 : 66
    }
    
    func tableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat {
        let heightWithButton: CGFloat = 260
        let heightWithOutButton: CGFloat = 200
        let section = tableViewData[indexPath.section]
        let note = section.associatedCheer[indexPath.row]
        return note.hasBeenRespondedTo ? heightWithOutButton : heightWithButton
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
