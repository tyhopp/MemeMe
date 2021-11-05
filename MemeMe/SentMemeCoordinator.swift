//
//  SentMemeCoordinator.swift
//  MemeMe
//
//  Created by Ty Hopp on 5/11/21.
//

import Foundation
import UIKit

struct SentMemeCoordinator {
    
    func presentDetailView(storyboard: UIStoryboard?, navigationController: UINavigationController?, meme: Meme) {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier: "SentMemeDetailViewController") as! SentMemeDetailViewController
        detailViewController.meme = meme
        
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
