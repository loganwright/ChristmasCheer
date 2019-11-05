//
//  CellConfiguring.swift
//  ChristmasCheer
//
//  Created by Logan Wright on 10/25/15.
//  Copyright © 2015 lowriDevs. All rights reserved.
//

import UIKit

extension UITableView {
    func registerCell<T : UITableViewCell>(_: T.Type, identifier: String = T.identifier) {
        if let nib = T.nib {
            register(nib, forCellReuseIdentifier: identifier)
        } else {
            register(T.self, forCellReuseIdentifier: identifier)
        }
    }
    
    func registerHeader<T: UITableViewHeaderFooterView>(_: T.Type, identifier: String = T.identifier) {
        if let nib = T.nib {
            register(nib, forHeaderFooterViewReuseIdentifier: identifier)
        } else {
            register(T.self, forHeaderFooterViewReuseIdentifier: identifier)
        }
    }
    
    func dequeueCell<T: UITableViewCell>(indexPath: IndexPath, identifier: String = T.identifier) -> T {
        let cell = dequeueReusableCell(withIdentifier: T.identifier, for: indexPath as IndexPath) as! T
        return cell
    }
    
    func dequeueHeader<T: UITableViewHeaderFooterView>(section: Int, identifier: String = T.identifier) -> T {
        let header = dequeueReusableHeaderFooterView(withIdentifier: T.identifier) as! T
        return header
    }
}

extension UITableViewHeaderFooterView {
    class var nibName: String {
        let name = "\(self)".components(separatedBy: ".").first ?? ""
        return name
    }
    class var nib: UINib? {
        if let _ = MainBundle.path(forResource: nibName, ofType: "nib") {
            return UINib(nibName: nibName, bundle: nil)
        } else {
            return nil
        }
    }
    class var identifier: String {
        return "identifier:\(self)"
    }
}

extension UITableViewCell {
    class var nibName: String {
        let name = "\(self)".components(separatedBy: ".").first ?? ""
        return name
    }
    class var nib: UINib? {
        if let _ = MainBundle.path(forResource: nibName, ofType: "nib") {
            return UINib(nibName: nibName, bundle: nil)
        } else {
            return nil
        }
    }
    class var identifier: String {
        return "identifier:\(self)"
    }
}
