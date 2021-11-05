//
//  SentMemeTableViewController.swift
//  MemeMe
//
//  Created by Ty Hopp on 2/11/21.
//

import Foundation
import UIKit

class SentMemeTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Outlets
    
    @IBOutlet weak var sentMemeTableView: UITableView!
    
    // MARK: Properties
    
    let notificationCenter: NotificationCenter = NotificationCenter.default
    var memeSharedNotification: Notification? = nil
    
    // MARK: Lifecycle methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        notificationCenter.addObserver(forName: ObserverKey.memeShared, object: nil, queue: nil, using: { notification in
            self.memeSharedNotification = notification
            self.sentMemeTableView.reloadData()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let notification = self.memeSharedNotification {
            notificationCenter.removeObserver(notification, name: ObserverKey.memeShared, object: nil)
        }
    }
    
    // MARK: Table delegate methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (UIApplication.shared.delegate as! AppDelegate).memes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SentMemeTableViewCell") as! SentMemeTableViewCell
        let memes = (UIApplication.shared.delegate as! AppDelegate).memes
        let meme = memes[(indexPath as NSIndexPath).row]
        
        // Set the table cell image
        if let originalImage = meme.originalImage {
            cell.memeImageView?.image = originalImage
        }

        // Set the table cell labels
        if let memeTopText = meme.topText, let memeBottomText = meme.bottomText {
            let memeTextAttributes = MemeText().getAttributes(fontSize: 20)
            cell.memeTopLabel.attributedText = NSMutableAttributedString(string: memeTopText, attributes: memeTextAttributes)
            cell.memeBottomLabel.attributedText = NSMutableAttributedString(string: memeBottomText, attributes: memeTextAttributes)
            cell.memeRightLabel?.text = "\(memeTopText)...\(memeBottomText)"
        }
            
        return cell
    }
}
