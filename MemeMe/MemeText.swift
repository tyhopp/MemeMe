//
//  MemeText.swift
//  MemeMe
//
//  Created by Ty Hopp on 5/11/21.
//

import Foundation
import UIKit

struct MemeText {
    var strokeColor: UIColor {
        get {
            if #available(iOS 13, *) {
                return .label
            } else {
                return .black
            }
        }
    }
    
    var foregroundColor: UIColor {
        get {
            if #available(iOS 13, *) {
                return .systemBackground
            } else {
                return .white
            }
        }
    }
    
    func getAttributes(fontSize: CGFloat) -> [NSAttributedString.Key: Any] {
        return [
            NSAttributedString.Key.strokeColor: strokeColor,
            NSAttributedString.Key.foregroundColor: foregroundColor,
            NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: fontSize)!,
            NSAttributedString.Key.strokeWidth: -4.0
        ]
    }
}
