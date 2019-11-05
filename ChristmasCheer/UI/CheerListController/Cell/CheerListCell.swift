//
//  CheerListCell.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 11/24/14.
//  Copyright (c) 2014 lowriDevs. All rights reserved.
//

import UIKit

protocol CheerListCellDelegate : class {
    func cheerListCell(_ menuViewCell: CheerListCell, didPressReturnCheerButtonForOriginalNote originalNote: ChristmasCheerNotification)
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
            return .zero
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
            indicatorButton.setImage(newValue, for: .normal)
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
        backgroundColor = UIColor.clear
        indicatorButton.backgroundColor = ColorPalette.SparklyRed.color
        indicatorButton.tintColor = ColorPalette.SparklyWhite.color
        indicatorButton.imageView?.contentMode = .scaleAspectFit
        indicatorButton.layer.cornerRadius = indicatorButton.bounds.height / 2.0
        indicatorButton.setTitle("", for: .normal)
        indicatorButton.setImage(UIImage.randomChristmasIcon(), for: .normal)
        indicatorButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        indicatorButton.isUserInteractionEnabled = false
        nameLabel.font = ChristmasCrackFont.Regular(52.0).font
        locationLabel.font = ChristmasCrackFont.Regular(52.0).font
        returnTheCheerButton.backgroundColor = ColorPalette.SparklyRed.color
        returnTheCheerButton.setTitleColor(ColorPalette.SparklyWhite.color, for: .normal)
        returnTheCheerButton.titleLabel?.font = ChristmasCrackFont.Regular(42.0).font
        returnTheCheerButton.titleEdgeInsets = UIEdgeInsets(top: 6.0, left: 0, bottom: 0, right: 0)
        returnTheCheerButton.layer.cornerRadius = returnTheCheerButton.bounds.height / 4.0
    }

    @IBAction func returnTheCheerButtonPressed(sender: UIButton) {
        delegate?.cheerListCell(self, didPressReturnCheerButtonForOriginalNote: cheerNotification)
    }
    
    // MARK: Selected
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        let color: UIColor
        if isHighlighted {
            color = ColorPalette.SparklyWhite.color
        } else {
            color = UIColor.clear
        }
        backgroundColor = color
        contentView.backgroundColor = color
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        // Selected / Highlighted == Same
        setSelected(highlighted, animated: animated)
    }
    
    func configure(note: ChristmasCheerNotification) {
        nameLabel.text = note.fromName
        locationLabel.text = note.fromLocation
        returnTheCheerButton.isEnabled = !note.hasBeenRespondedTo
        cheerNotification = note
        
        // Is a response
        if let _ = note.initiationNoteId {
            indicatorButton.backgroundColor = ColorPalette.Green.color
        } else {
            indicatorButton.backgroundColor = ColorPalette.SparklyRed.color
        }
    }
    
}

