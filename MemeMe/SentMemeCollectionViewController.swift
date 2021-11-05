//
//  SentMemeCollectionViewController.swift
//  MemeMe
//
//  Created by Ty Hopp on 2/11/21.
//

import Foundation
import UIKit

class SentMemeCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: Outlets
    
    @IBOutlet weak var sentMemeCollectionView: UICollectionView!
    @IBOutlet weak var sentMemeFlowLayout: UICollectionViewFlowLayout!
    
    // MARK: Properties
    
    let notificationCenter: NotificationCenter = NotificationCenter.default
    var memeSharedNotification: Notification? = nil
    
    // MARK: Lifecycle methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        notificationCenter.addObserver(forName: ObserverKey.memeShared, object: nil, queue: nil, using: { notification in
            self.memeSharedNotification = notification
            self.sentMemeCollectionView.reloadData()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let notification = self.memeSharedNotification {
            notificationCenter.removeObserver(notification, name: ObserverKey.memeShared, object: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let space: CGFloat = 3.0
        let width = (view.frame.size.width - (2 * space)) / 3.0
        let height = (view.frame.size.height - (2 * space)) / 6.0

        sentMemeFlowLayout.minimumInteritemSpacing = space
        sentMemeFlowLayout.minimumLineSpacing = space
        sentMemeFlowLayout.itemSize = CGSize(width: width, height: height)
    }
    
    // MARK: Delegate methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (UIApplication.shared.delegate as! AppDelegate).memes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SentMemeCollectionViewCell", for: indexPath) as! SentMemeCollectionViewCell
        let memes = (UIApplication.shared.delegate as! AppDelegate).memes
        let meme = memes[(indexPath as NSIndexPath).row]
        
        // Set the collection cell image
        if let originalImage = meme.originalImage {
            cell.memeImageView?.image = originalImage
        }

        // Set the collection cell top and bottom labels
        if let memeTopText = meme.topText, let memeBottomText = meme.bottomText {
            let memeTextAttributes = MemeText().getAttributes(fontSize: 20)
            cell.memeTopLabel.attributedText = NSMutableAttributedString(string: memeTopText, attributes: memeTextAttributes)
            cell.memeBottomLabel.attributedText = NSMutableAttributedString(string: memeBottomText, attributes: memeTextAttributes)
        }
            
        return cell
    }
}
