//
//  MemeDetailViewController.swift
//  MemeMe
//
//  Created by Ty Hopp on 5/11/21.
//

import UIKit

class SentMemeDetailViewController: UIViewController {
    
    // MARK: Properties

    var meme: Meme?
    
    // MARK: Outlets
    
    @IBOutlet weak var memeImageView: UIImageView!
    
    // MARK: Lifecycle methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        
        if let memedImage = meme?.memedImage {
            memeImageView.image = memedImage
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
}
