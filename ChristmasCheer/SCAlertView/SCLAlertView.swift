//
//  SCLAlertView.swift
//  SCLAlertView Example
//
//  Created by Viktor Radchenko on 6/5/14.
//  Copyright (c) 2014 Viktor Radchenko. All rights reserved.
//

import Foundation
import UIKit

// Pop Up Styles
enum SCLAlertViewStyle {
    case Success, Error, Notice, Warning, Info, Edit
}

// Action Types
enum SCLActionType {
	case None, Selector, Closure
}

// Button sub-class
class SCLButton: UIButton {
	var actionType = SCLActionType.None
	var target:AnyObject!
	var selector:Selector!
	var action:(()->Void)!
	
	convenience init() {
        self.init(frame: .zero)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder:aDecoder)
	}
	
	override init(frame: CGRect) {
		super.init(frame:frame)
	}
}

// Allow alerts to be closed/renamed in a chainable manner
// Example: SCLAlertView().showSuccess(self, title: "Test", subTitle: "Value").close()
class SCLAlertViewResponder {
    let alertview: SCLAlertView
    
    // Initialisation and Title/Subtitle/Close functions
    init(alertview: SCLAlertView) {
		self.alertview = alertview
	}
	
    func setTitle(title: String) {
		self.alertview.labelTitle.text = title
	}
	
    func setSubTitle(subTitle: String) {
		self.alertview.viewText.text = subTitle
	}
	
    func close() {
		self.alertview.hideView()
	}
}

let kCircleHeightBackground: CGFloat = 62.0

// The Main Class
class SCLAlertView: UIViewController {
    let kDefaultShadowOpacity: CGFloat = 0.4
    let kCircleTopPosition: CGFloat = -12.0
    let kCircleBackgroundTopPosition: CGFloat = -15.0
	let kCircleHeight: CGFloat = 56.0
    let kCircleIconHeight: CGFloat = 20.0
	let kTitleTop:CGFloat = 24.0
	let kTitleHeight:CGFloat = 40.0
    let kWindowWidth: CGFloat = 240.0
    var kWindowHeight: CGFloat = 320 // 178.0
    var kTextHeight: CGFloat = 232 // 90.0
	
    // Font
    let kDefaultFont = "HelveticaNeue"
	let kButtonFont = "HelveticaNeue-Bold"
	
    // Members declaration
    var labelTitle = UILabel()
    var viewText = UITextView()
    var contentView = UIView()
    var circleBG = UIView(frame:CGRect(x:0, y:0, width:kCircleHeightBackground, height:kCircleHeightBackground))
	var circleView = UIView()
    var circleIconImageView = UIButton(type: .system)
    var durationTimer: Timer!
	private var inputs = [UITextField]()
	private var buttons = [SCLButton]()
    
    var completion: () -> Void = {}
	
    required convenience init?(coder aDecoder: NSCoder?) {
        self.init()
    }
    
    required init() {
        super.init(nibName: nil, bundle: nil)
        
		// Set up main view
		view.frame = UIScreen.main.bounds
		view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.backgroundColor = UIColor(red:0, green:0, blue:0, alpha:kDefaultShadowOpacity)
		view.addSubview(contentView)
		// Content View
        contentView.backgroundColor = ColorPalette.TexturedBackground.color
        contentView.layer.cornerRadius = 5
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 3.0
		contentView.addSubview(labelTitle)
		contentView.addSubview(viewText)
		// Circle View
		circleBG.backgroundColor = ColorPalette.TexturedBackground.color
		circleBG.layer.cornerRadius = circleBG.frame.size.height / 2
		view.addSubview(circleBG)
		circleBG.addSubview(circleView)
		circleView.addSubview(circleIconImageView)
		var x = (kCircleHeightBackground - kCircleHeight) / 2
		circleView.frame = CGRect(x:x, y:x, width:kCircleHeight, height:kCircleHeight)
		circleView.layer.cornerRadius = circleView.frame.size.height / 2
		x = (kCircleHeight - kCircleIconHeight) / 2
		circleIconImageView.frame = CGRect(x:x, y:x, width:kCircleIconHeight, height:kCircleIconHeight)
        // Title
        labelTitle.numberOfLines = 1
        labelTitle.textAlignment = .center
        labelTitle.font = ChristmasCrackFont.Regular(42.0).font
		labelTitle.frame = CGRect(x:12, y:kTitleTop, width: kWindowWidth - 24, height:kTitleHeight)
        labelTitle.backgroundColor = UIColor.clear
        
        // View text
		viewText.isEditable = false
        viewText.textAlignment = .center
        viewText.textContainerInset = .zero
        viewText.textContainer.lineFragmentPadding = 0;
        viewText.font = ChristmasCrackFont.Regular(32.0).font
        viewText.backgroundColor = UIColor.clear
        
        // Colours
        contentView.backgroundColor = ColorPalette.TexturedBackground.color
        labelTitle.textColor = ColorPalette.SparklyRed.color
        viewText.textColor = ColorPalette.DarkGray.color
        contentView.layer.borderColor = ColorPalette.SparklyRed.color.cgColor
        
        self.circleIconImageView.tintColor = ColorPalette.SparklyWhite.color
        self.circleIconImageView.isUserInteractionEnabled = false
        self.circleIconImageView.imageEdgeInsets = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
    }
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		var sz = UIScreen.main.bounds.size
		let sver = UIDevice.current.systemVersion as NSString
		let ver = sver.floatValue
		if ver < 8.0 {
			// iOS versions before 7.0 did not switch the width and height on device roration
            if UIApplication.shared.statusBarOrientation.isLandscape {
				let ssz = sz
				sz = CGSize(width:ssz.height, height:ssz.width)
			}
		}
		// Set background frame
		view.frame.size = sz
		// Set frames
		var x = (sz.width - kWindowWidth) / 2
		var y = (sz.height - kWindowHeight -  (kCircleHeight / 8)) / 2
		contentView.frame = CGRect(x:x, y:y, width:kWindowWidth, height:kWindowHeight)
		y -= kCircleHeightBackground * 0.6
		x = (sz.width - kCircleHeightBackground) / 2
		circleBG.frame = CGRect(x:x, y:y, width:kCircleHeightBackground, height:kCircleHeightBackground)
		// Subtitle
		y = kTitleTop + kTitleHeight
		viewText.frame = CGRect(x:12, y:y, width: kWindowWidth - 24, height:kTextHeight)
		// Text fields
		y += kTextHeight + 14.0
		for txt in inputs {
			txt.frame = CGRect(x:12, y:y, width:kWindowWidth - 24, height:30)
			txt.layer.cornerRadius = 3
			y += 40
		}
		// Buttons
		for btn in buttons {
            btn.titleLabel?.font = ChristmasCrackFont.Regular(36.0).font
            btn.contentEdgeInsets = UIEdgeInsets(top: 4.0, left: 0, bottom: 0, right: 0)
            btn.setTitleColor(ColorPalette.SparklyWhite.color, for: .normal)
			btn.frame = CGRect(x:12, y:y, width:kWindowWidth - 24, height:35)
			btn.layer.cornerRadius = 3
			y += 45.0
		}
	}

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touches = event?.touches(for: view), touches.count > 0 else { return }
        view.endEditing(true)
	}
	
	func addTextField(title:String?=nil)->UITextField {
		// Update view height
		kWindowHeight += 40.0
		// Add text field
		let txt = UITextField()
		txt.borderStyle = .roundedRect
		txt.font = UIFont(name:kDefaultFont, size: 14)
        txt.autocapitalizationType = .words
		txt.clearButtonMode = .whileEditing
		txt.layer.masksToBounds = true
		txt.layer.borderWidth = 1.0
		if title != nil {
			txt.placeholder = title!
		}
		contentView.addSubview(txt)
		inputs.append(txt)
		return txt
	}
	
	func addButton(_ title:String, action: @escaping ()->Void)->SCLButton {
		let btn = addButton(title)
		btn.actionType = SCLActionType.Closure
		btn.action = action
        btn.addTarget(self, action: #selector(buttonTapped), for:.touchUpInside)
		return btn
	}
	
	func addButton(_ title:String, target:AnyObject, selector:Selector)->SCLButton {
		let btn = addButton(title)
		btn.actionType = SCLActionType.Selector
		btn.target = target
		btn.selector = selector
        btn.addTarget(self, action:  #selector(buttonTapped), for:.touchUpInside)
		return btn
	}
	
	private func addButton(_ title: String)->SCLButton {
		// Update view height
		kWindowHeight += 45.0
		// Add button
		let btn = SCLButton()
		btn.layer.masksToBounds = true
		btn.setTitle(title, for: .normal)
		btn.titleLabel?.font = UIFont(name:kButtonFont, size: 14)
		contentView.addSubview(btn)
		buttons.append(btn)
		return btn
	}

    @objc
	func buttonTapped(_ btn: SCLButton) {
		if btn.actionType == SCLActionType.Closure {
			btn.action()
		} else if btn.actionType == SCLActionType.Selector {
			let ctrl = UIControl()
            ctrl.sendAction(btn.selector, to:btn.target, for:nil)
		} else {
			print("Unknow action type for button")
		}
		hideView()
	}
	
	// showSuccess(view, title, subTitle)
	func showSuccess(_ title: String, subTitle: String, closeButtonTitle: String? = nil, duration: TimeInterval = 0.0) -> SCLAlertViewResponder {
		return showTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .Success)
	}
	
	// showError(view, title, subTitle)
	func showError(_ title: String, subTitle: String, closeButtonTitle:String? = nil, duration: TimeInterval = 0.0) -> SCLAlertViewResponder {
		return showTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .Error)
	}
	
	// showNotice(view, title, subTitle)
	func showNotice(_ title: String, subTitle: String, closeButtonTitle:String?=nil, duration:TimeInterval=0.0) -> SCLAlertViewResponder {
		return showTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .Notice)
	}
	
	// showWarning(view, title, subTitle)
	func showWarning(_ title: String, subTitle: String, closeButtonTitle:String?=nil, duration:TimeInterval=0.0) -> SCLAlertViewResponder {
		return showTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .Warning)
	}
	
	// showInfo(view, title, subTitle)
	func showInfo(_ title: String, subTitle: String, closeButtonTitle:String?=nil, duration:TimeInterval=0.0) -> SCLAlertViewResponder {
		return showTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .Info)
	}
	
	func showEdit(_ title: String, subTitle: String, closeButtonTitle:String?=nil, duration:TimeInterval=0.0) -> SCLAlertViewResponder {
		return showTitle(title, subTitle: subTitle, duration: duration, completeText:closeButtonTitle, style: .Edit)
	}
	
    // showTitle(view, title, subTitle, style)
	func showTitle(_ title: String, subTitle: String, style: SCLAlertViewStyle, closeButtonTitle:String?=nil, duration:TimeInterval=0.0) -> SCLAlertViewResponder {
        return showTitle(title, subTitle: subTitle, duration:duration, completeText:closeButtonTitle, style: style)
    }
    
    // showTitle(view, title, subTitle, duration, style)
    func showTitle(_ title: String, subTitle: String, duration: TimeInterval?, completeText: String?, style: SCLAlertViewStyle) -> SCLAlertViewResponder {
        view.alpha = 0
        // TODO: !!
        let rv: UIView = UIApplication.shared.keyWindow!.subviews.first!
		rv.addSubview(view)
		view.frame = rv.bounds
		
        // Alert colour/icon
        var viewColor = UIColor()
        var iconImage: UIImage
        
        // Icon style
        switch style {
			case .Success:
				viewColor = ColorPalette.Green.color
				iconImage = UIImage.randomChristmasIcon()
				
			case .Error:
				viewColor = ColorPalette.SparklyRed.color
				iconImage = UIImage(named: "icon_error")!
				
			case .Notice:
                viewColor = UIColorFromRGB(0x727375)
				iconImage = UIImage.randomChristmasIcon()
				
			case .Warning:
				viewColor = UIColorFromRGB(0xFFD110)
				iconImage = UIImage.randomChristmasIcon()
				
			case .Info:
				viewColor = UIColorFromRGB(0x2866BF)
				iconImage = UIImage.randomChristmasIcon()
            
			case .Edit:
				viewColor = UIColorFromRGB(0xA429FF)
				iconImage = UIImage.randomChristmasIcon()
        }
		
        // Title
        if !title.isEmpty {
            self.labelTitle.text = title
        }
        
        // Subtitle
        if !subTitle.isEmpty {
            viewText.text = subTitle
			// Adjust text view size, if necessary
			let str = subTitle as NSString
            // TODO: !
            let attr = [NSAttributedString.Key.font : viewText.font!]
			let sz = CGSize(width: kWindowWidth - 24, height:kTextHeight)
            let r = str.boundingRect(with: sz, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes:attr, context:nil)
			let ht = ceil(r.size.height)
			if ht < kTextHeight {
				kWindowHeight -= (kTextHeight - ht)
				kTextHeight = ht
			}
        }
		
		// Done button

		let txt = completeText != nil ? completeText! : "Done"
        addButton(txt, target:self, selector: #selector(hideView))
		
        // Alert view colour and images
        self.circleView.backgroundColor = viewColor
        self.circleIconImageView.setImage(iconImage, for: .normal)
		for txt in inputs {
            txt.layer.borderColor = viewColor.cgColor
		}
		for btn in buttons {
			btn.backgroundColor = viewColor
			if style == SCLAlertViewStyle.Warning {
                btn.setTitleColor(UIColor.black, for: .normal)
			}
		}
		
        // Adding duration
        if let duration = duration, duration > 0 {
            durationTimer?.invalidate()
            durationTimer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(hideView), userInfo: nil, repeats: false)
        }
        
        // Animate in the alert view
        UIView.animate(withDuration: 0.2, animations: {
				self.view.frame.origin.y = rv.center.y - 100
				self.view.alpha = 1
            }, completion: { finished in
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.center = rv.center
				})
        })
        // Chainable objects
        return SCLAlertViewResponder(alertview: self)
    }
	
    // Close SCLAlertView
    @objc
    func hideView() {
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 0
            }, completion: { finished in
                self.completion()
                self.view.removeFromSuperview()
        })
    }
    
    // Helper function to convert from RGB to UIColor
    func UIColorFromRGB(_ rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
