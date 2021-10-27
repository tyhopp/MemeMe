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
    
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    
    // MARK: Properties
    
    struct Alert {
        static let cameraAccessTitle = "Allow Camera Access"
        static let cameraAccessMessage = "Camera access is required to use photos for memes. Grant access in settings."
    }
    
    struct AlertAction {
        static let settings = "Settings"
        static let cancel = "Cancel"
    }
    
    let cancelAction = UIAlertAction(title: AlertAction.cancel, style: .cancel, handler: nil)
    
    // MARK: Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera) || AVCaptureDevice.authorizationStatus(for: .video) == .restricted
    }
    
    // MARK: Actions
    
    @IBAction func showCamera() {
        let cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraPermission {
            case .restricted:
                return // Button is disabled already if restricted, added this for exhaustive case coverage
            case .denied:
                showCameraPermissionAlert()
            case .notDetermined, .authorized: // The system will show the permission alert if not determined
                showImagePicker(sourceType: .camera)
            @unknown default:
                print("Unknown case for AVCaptureDevice.authorizationStatus")
            }
    }
    
    // MARK: Composable functions
    
    func showCameraPermissionAlert() {
        let alert = UIAlertController(title: Alert.cameraAccessTitle, message: Alert.cameraAccessMessage, preferredStyle: .alert)
        
        let navigateToSettingsAction = UIAlertAction(title: AlertAction.settings, style: .default) { (_) -> Void in
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
    
    func showImagePicker(sourceType: UIImagePickerController.SourceType) {
        let camera = UIImagePickerController()
        camera.delegate = self
        camera.sourceType = sourceType
        present(camera, animated: true)
    }
}
