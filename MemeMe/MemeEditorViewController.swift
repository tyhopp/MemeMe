//
//  ViewController.swift
//  MemeMe
//
//  Created by Ty Hopp on 25/10/21.
//

import UIKit
import AVFoundation

class MemeEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: Outlets
    
    // Top toolbar
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    // Image view
    @IBOutlet weak var imageView: UIImageView!
    
    // Bottom toolbar
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var albumButton: UIBarButtonItem!
    
    // MARK: Properties
    
    var memeModel = MemeModel()
    let cameraViewController = UIImagePickerController()
    
    struct AlertString {
        static let cameraAccessTitle = "Allow Camera Access"
        static let cameraAccessMessage = "Camera access is required to use photos for memes. Grant access in settings."
        static let settingsAction = "Settings"
        static let cancelAction = "Cancel"
    }
    
    struct ObserverKey {
        static let imageUpdated: NSNotification.Name = NSNotification.Name(rawValue: "image-updated")
    }
    
    // MARK: Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // TODO: Extract into own function
        shareButton.isEnabled = false
        cancelButton.isEnabled = false
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera) || AVCaptureDevice.authorizationStatus(for: .video) == .restricted
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: ObserverKey.imageUpdated, object: nil)
    }
    
    // MARK: Actions
    
    @IBAction func showCamera() {
        let cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraPermission {
            case .restricted:
                return // Button is disabled already if restricted, added this for exhaustive case coverage
            case .denied:
                presentCameraPermissionAlert()
            case .notDetermined, .authorized: // The system will show the permission alert if not determined
                presentCamera()
            @unknown default:
                print("Unknown case for AVCaptureDevice.authorizationStatus")
            }
    }
    
    // MARK: Setup functions
    
    func setupObservers() {
        let center = NotificationCenter.default
        
        // Update the image view when the meme model image changes
        center.addObserver(forName: ObserverKey.imageUpdated, object: nil, queue: nil) { _ in
            self.imageView.image = self.memeModel.image
        }
    }
    
    // MARK: Camera functions
    
    /**
     Initializes and presents the camera view controller.
     
     - Returns: Void
     */
    func presentCamera() -> Void {
        cameraViewController.delegate = self
        cameraViewController.sourceType = .camera
        cameraViewController.allowsEditing = true
        present(cameraViewController, animated: true)
    }
    
    /**
     Initalizes and presents an alert with a cancel and settings action. Shown only if the user denied camera access prior.
     
     The settings action navigates the user to the system settings app specific to MemeMe.
     
     - Returns: Void
     */
    func presentCameraPermissionAlert() -> Void {
        let alert = UIAlertController(title: AlertString.cameraAccessTitle, message: AlertString.cameraAccessMessage, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: AlertString.cancelAction, style: .cancel, handler: nil)
        
        let navigateToSettingsAction = UIAlertAction(title: AlertString.settingsAction, style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(navigateToSettingsAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    /**
     Delegate method that fires when the user has selected a captured photo to use.
     
     Posts to the notification center upon completion.
     
     - Returns: Void
     */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) -> Void {

        guard let image = info[.editedImage] as? UIImage else {
            return
        }
        
        memeModel.image = image
        NotificationCenter.default.post(name: ObserverKey.imageUpdated, object: nil)
        picker.dismiss(animated: true)
    }
}
