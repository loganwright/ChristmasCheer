//
//  MenuViewCell.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/24/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit

let MenuViewCellNibName = "MenuViewCell"
let MenuViewCellIdentifier = "MenuViewCellIdentifier"

protocol MenuViewCellDelegate : class {
    func menuViewCell(menuViewCell: MenuViewCell, didPressReturnCheerButtonForOriginalNote originalNote: ChristmasCheerNotification)
}

class MenuViewCell: UITableViewCell {

    @IBOutlet weak var indicatorButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var returnTheCheerButton: UIButton!
    var cheerNotification: ChristmasCheerNotification!
    weak var delegate: MenuViewCellDelegate?
    
    // To prevent cell separator inset
    @available(iOS 8.0, *)
    override var layoutMargins: UIEdgeInsets {
        get {
            return UIEdgeInsetsZero
        }
        set {
            super.layoutMargins = newValue
        }
    }
    
    var indicatorImage: UIImage? {
        get {
            return self.indicatorButton.imageView?.image
        }
        set {
            self.indicatorButton.setImage(newValue, forState: .Normal)
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.clipsToBounds = true
        self.backgroundColor = UIColor.clearColor()
        indicatorButton.backgroundColor = ColorPalette.SparklyRed.color
        indicatorButton.tintColor = ColorPalette.SparklyWhite.color
        indicatorButton.imageView?.contentMode = .ScaleAspectFit
        indicatorButton.layer.cornerRadius = CGRectGetHeight(indicatorButton.bounds) / 2.0
        indicatorButton.setTitle("", forState: .Normal)
        indicatorButton.setImage(UIImage.randomChristmasIcon(), forState: .Normal)
        indicatorButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        indicatorButton.userInteractionEnabled = false
        nameLabel.font = ChristmasCrackFont.Regular(52.0).font
        locationLabel.font = ChristmasCrackFont.Regular(52.0).font
        returnTheCheerButton.backgroundColor = ColorPalette.SparklyRed.color
        returnTheCheerButton.setTitleColor(ColorPalette.SparklyWhite.color, forState: .Normal)
        returnTheCheerButton.titleLabel?.font = ChristmasCrackFont.Regular(42.0).font
        returnTheCheerButton.titleEdgeInsets = UIEdgeInsets(top: 6.0, left: 0, bottom: 0, right: 0)
        returnTheCheerButton.layer.cornerRadius = CGRectGetHeight(returnTheCheerButton.bounds) / 4.0
    }
    
    func setupWithEmptyTableMessage() {
        self.nameLabel.text = "No Cheer Yet."
        self.locationLabel.text = "Try sending some!"
        self.returnTheCheerButton.enabled = false
        self.indicatorButton.backgroundColor = ColorPalette.SparklyRed.color

    }

    @IBAction func returnTheCheerButtonPressed(sender: UIButton) {
        self.delegate?.menuViewCell(self, didPressReturnCheerButtonForOriginalNote: self.cheerNotification)
    }
    
    // MARK: Selected
    
    override func setSelected(selected: Bool, animated: Bool) {
        if selected {
            let color = ColorPalette.SparklyWhite.color
            self.backgroundColor = color
            self.contentView.backgroundColor = color
        } else {
            self.contentView.backgroundColor = UIColor.clearColor()
            self.backgroundColor = UIColor.clearColor()
        }
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        if highlighted {
            let color = ColorPalette.SparklyWhite.color
            self.backgroundColor = color
            self.contentView.backgroundColor = color
        } else {
            self.contentView.backgroundColor = UIColor.clearColor()
            self.backgroundColor = UIColor.clearColor()
        }
    }
    
    func configure(note: ChristmasCheerNotification) {
        nameLabel.text = note.fromName
        locationLabel.text = note.fromLocation
        returnTheCheerButton.enabled = !note.hasBeenRespondedTo
        cheerNotification = note
        
        // Is a response
        if let _ = note.initiationNoteId {
            indicatorButton.backgroundColor = ColorPalette.Green.color
        } else {
            indicatorButton.backgroundColor = ColorPalette.SparklyRed.color
        }
    }
    
}

