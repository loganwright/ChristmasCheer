//
//  CheerListCell.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/24/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit

protocol CheerListCellDelegate : class {
    func cheerListCell(menuViewCell: CheerListCell, didPressReturnCheerButtonForOriginalNote originalNote: ChristmasCheerNotification)
}

@objc(CheerListCell)
class CheerListCell: UITableViewCell {

    @IBOutlet weak var indicatorButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var returnTheCheerButton: UIButton!
    var cheerNotification: ChristmasCheerNotification!
    weak var delegate: CheerListCellDelegate?
    
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
            return indicatorButton.imageView?.image
        }
        set {
            indicatorButton.setImage(newValue, forState: .Normal)
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
        backgroundColor = UIColor.clearColor()
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

    @IBAction func returnTheCheerButtonPressed(sender: UIButton) {
        delegate?.cheerListCell(self, didPressReturnCheerButtonForOriginalNote: cheerNotification)
    }
    
    // MARK: Selected
    
    override func setSelected(selected: Bool, animated: Bool) {
        let color: UIColor
        if highlighted {
            color = ColorPalette.SparklyWhite.color
        } else {
            color = UIColor.clearColor()
        }
        backgroundColor = color
        contentView.backgroundColor = color
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        // Selected / Highlighted == Same
        setSelected(highlighted, animated: animated)
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

