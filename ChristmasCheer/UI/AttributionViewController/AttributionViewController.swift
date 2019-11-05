//
//  AttributionViewController.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/27/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit
import Cartography
//import Genome
//import YamlSwift

//func +(lhs: JSON, rhs: JSON) -> JSON {
//    var combined = lhs
//    rhs.forEach { combined[$0] = $1 }
//    return combined
//}
//
//extension Yaml {
//    var contents: AnyObject? {
//        switch self {
//        case .Bool(let b):
//            return b
//        case .Double(let d):
//            return d
//        case .Int(let i):
//            return i
//        case .String(let s):
//            return s
//        case .Null:
//            return nil
//        case .Array(let a):
//            return a.flatMap { $0.contents }
//        case .Dictionary(let dictionary):
//            let keys = dictionary.keys.flatMap { $0.string }
//            let values = dictionary.values.flatMap { $0.contents }
//            let json: JSON = zip(keys, values).reduce([:]) {
//                return $0 + [$1.0 : $1.1]
//            }
//            return json
//        }
//    }
//    
//    func json() -> JSON? {
//        return contents as? JSON
//    }
//    
//    func jsonArray() -> [JSON]? {
//        return contents as? [JSON]
//    }
//}
//
///*
//I like yaml format when writing, but parsing json is easier, mixing both for now
//*/
//extension NSBundle {
//    func loadYaml(fileName: String) -> Yaml? {
//        guard
//            let filePath = MainBundle
//                .pathForResource(fileName, ofType: "yml"),
//            let data = NSData(contentsOfFile: filePath),
//            let string = String(data: data, encoding: NSUTF8StringEncoding)
//            else { return nil }
//        return Yaml.load(string).value
//    }
//}
//
//extension Array where Element : MappableObject {
//    static func mappedYaml(yamlFile: String) throws -> Array {
//        guard
//            let attributionJson = MainBundle.loadYaml("attributions")?.jsonArray()
//            else {
//                throw MappingError.UnableToMap("Unable to load yaml \(yamlFile)")
//        }
//        return try mappedInstance(attributionJson)
//    }
//}

struct Attribution: Codable {
    let title: String
    let author: String
    let link: String
}

struct AttributionSection: Codable {
    let title: String
    let attributions: [Attribution]
}

class AttributionCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    
    private func setup() {
        backgroundColor = UIColor.clear
        textLabel?.font = ChristmasCrackFont.Regular(36.0).font
        textLabel?.textColor = ColorPalette.DarkGray.color
        detailTextLabel?.textColor = ColorPalette.DarkGray.color
    }
    
    func configure(attribution: Attribution) {
        textLabel?.text = attribution.author
        detailTextLabel?.text = attribution.title
    }
}

class AttributionHeaderCell : UITableViewHeaderFooterView {
    
    var label: UILabel = UILabel()
    
    convenience init() {
        self.init(reuseIdentifier: nil)
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        setupLabel()
        setupLabelConstraints()
        contentView.backgroundColor = ColorPalette.Green.color
    }
    
    private func setupLabel() {
        label.font = ChristmasCrackFont.Regular(52.0).font
        label.textColor = ColorPalette.SparklyWhite.color
        label.textAlignment = .center
        contentView.addSubview(label)
    }
    
    private func setupLabelConstraints() {
        constrain(label, self) { label, view in
            label.top == view.top
            label.left == view.left
            label.bottom == view.bottom
            label.right == view.right
        }
    }
}

extension UIBarButtonItem {
    static func cc_backBarButtonItem(_ target: AnyObject?, selector: Selector) -> UIBarButtonItem {
        let backButton = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: target,
            action: selector
        )
        let attributes = [
            NSAttributedString.Key.font : ChristmasCrackFont.Regular(32.0).font
        ]
        backButton.setTitleTextAttributes(
            attributes,
            for: .normal
        )
        return backButton
    }
}

/*
Remove namespacing for iOS 8, otherwise, nibs don't load properly
*/
@objc(AttributionViewController)
class AttributionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var attributionSections: [AttributionSection] = []
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTitleLabel()
    }

    // MARK: Setup
    
    private func setup() {
        setupData()
        setupTableView()
        setupNavigationBar()
    }
    
    private func setupTableView() {
        tableView.registerCell(AttributionCell.self)
        tableView.registerHeader(AttributionHeaderCell.self)
        tableView.backgroundColor = ColorPalette.TexturedBackground.color
        tableView.allowsSelection = false
        tableView.reloadData()
    }
    
    private func setupNavigationBar() {
        title = "Attributions"
        navigationItem.leftBarButtonItem = UIBarButtonItem
            .cc_backBarButtonItem(self, selector: #selector(backButtonPressed))
    }
    
    private func setupData() {
//        guard
//            let attributionJson = MainBundle.loadYaml("attributions")?.jsonArray(),
//            let attributionSections = try? [AttributionSection].mappedInstance(attributionJson)
//            else {
//                self.attributionSections = []
//                return
//            }

        // todo
        print("todo")
        self.attributionSections = []
    }
    
    // MARK: Main Label
    
    private func updateTitleLabel() {
        // Don't call till viewwillappear
        let titleLabel = MarginLabel()
        titleLabel.numberOfLines = 0
        titleLabel.marginInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        titleLabel.textAlignment = .center
        titleLabel.textColor = ColorPalette.DarkGray.color
        titleLabel.font = ChristmasCrackFont.Regular(42.0).font
        titleLabel.text = "Christmas Cheer! wouldn't have been possible without the help of an active and talented open source community! Here's a list of some of the honorary elves that contributed their work along the way!\n\nThanks!"
        
        let maxWidth = self.tableView.bounds.width
        let sizeThatFits = titleLabel.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        titleLabel.bounds = CGRect(x: 0, y: 0, width: maxWidth, height: sizeThatFits.height + 100)
        tableView.tableHeaderView = titleLabel
    }
    
    // MARK: Button Press

    @objc
    dynamic private func backButtonPressed(sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return attributionSections.count;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = attributionSections[section]
        return section.attributions.count;
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: AttributionCell = tableView.dequeueCell(indexPath: indexPath)
        let attributionSection = attributionSections[indexPath.section]
        let attribution = attributionSection.attributions[indexPath.row]
        cell.configure(attribution: attribution)
        return cell;
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header: AttributionHeaderCell = tableView.dequeueHeader(section: section)
        let attributeSection = attributionSections[section]
        header.label.text = attributeSection.title
        return header
    }


    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 66.0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
}

