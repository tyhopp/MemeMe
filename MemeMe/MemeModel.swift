//
//  MemeModel.swift
//  MemeMe
//
//  Created by Ty Hopp on 26/10/21.
//

import Foundation
import UIKit

struct Meme {
    var topText: String?
    var bottomText: String?
    var originalImage: UIImage?
    var memedImage: UIImage?
    
    init(topText: String, bottomText: String, originalImage: UIImage, memedImage: UIImage) {
        self.topText = topText
        self.bottomText = bottomText
        self.originalImage = originalImage
        self.memedImage = memedImage
    }
}
