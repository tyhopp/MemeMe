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
    
    var memeModel: MemeModel!
    
    let cameraViewController = UIImagePickerController()
    
    struct Alert {
        static let cameraAccessTitle = "Allow Camera Access"
        static let cameraAccessMessage = "Camera access is required to use photos for memes. Grant access in settings."
    }
    
    struct AlertAction {
        static let settings = "Settings"
        static let cancel = "Cancel"
    }
    
    // MARK: Lifecycle methods
    
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
                initCamera()
            @unknown default:
                print("Unknown case for AVCaptureDevice.authorizationStatus")
            }
    }
    
    // MARK: Camera functions
    
    func initCamera() {
        cameraViewController.delegate = self
        cameraViewController.sourceType = .camera
        cameraViewController.allowsEditing = true
        present(cameraViewController, animated: true)
    }
    
    func showCameraPermissionAlert() {
        let alert = UIAlertController(title: Alert.cameraAccessTitle, message: Alert.cameraAccessMessage, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: AlertAction.cancel, style: .cancel, handler: nil)
        
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
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var meme = MemeModel()

        guard let image = info[.editedImage] as? UIImage else {
            return
        }
        
        meme.originalImage = image

        picker.dismiss(animated: true)
    }
}
