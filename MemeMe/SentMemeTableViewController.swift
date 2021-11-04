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
        let cell = tableView.dequeueReusableCell(withIdentifier: "SentMemeTableCell")!
        let memes = (UIApplication.shared.delegate as! AppDelegate).memes
        let meme = memes[(indexPath as NSIndexPath).row]
        
        // Set the table cell image
        if let memedImage = meme.memedImage {
            if let imageView = cell.contentView.subviews[0] as? UIImageView {
                imageView.image = memedImage
            }
        }

        // Set the table cell label
        if let label = cell.contentView.subviews[1].subviews[0] as? UILabel {
            label.text = "\(meme.topText ?? TextFieldString.top) ... \(meme.bottomText ?? TextFieldString.bottom)"
        }
            
        return cell
    }
}
