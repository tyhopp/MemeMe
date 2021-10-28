//
//  ViewController.swift
//  MemeMe
//
//  Created by Ty Hopp on 25/10/21.
//

import UIKit
import AVFoundation
import PhotosUI

class MemeEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
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
    
    struct CameraPermissionAlertString {
        static let title = "Allow Camera Access"
        static let message = "Camera access is required to use photos for memes. Grant access in settings."
    }
    
    struct PhotoLibraryPermissionAlertString {
        static let title = "Allow Photo Library Access"
        static let message = "No acceess permission was given for the selected photo. Grant access in settings."
    }
    
    struct AlertActionLabel {
        static let cancel = "Cancel"
        static let settings = "Settings"
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
                presentPermissionAlert(title: CameraPermissionAlertString.title, message: CameraPermissionAlertString.message)
            case .notDetermined, .authorized: // The system will show the permission alert if not determined
                presentImagePicker(sourceType: .camera)
            @unknown default:
                print("Unknown case for AVCaptureDevice.authorizationStatus")
            }
    }
    
    @IBAction func showAlbum(_ sender: Any) {
        if #available(iOS 14, *) {
            let photoLibraryPresmission = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            switch photoLibraryPresmission {
                case .restricted:
                    return
                case .denied:
                    presentPermissionAlert(title: PhotoLibraryPermissionAlertString.title, message: PhotoLibraryPermissionAlertString.message)
                case .notDetermined, .authorized, .limited:
                    presentImagePicker(sourceType: .photoLibrary)
            @unknown default:
                print("Unknown case for PHPhotoLibrary.authorizationStatus")
            }
        } else {
            presentImagePicker(sourceType: .photoLibrary)
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
    
    // MARK: Image picker presentation functions
    
    /**
     Presents a `UIImagePickerViewController`.
     
     - Parameter sourceType: Either .camera or .photoLibrary
     
     - Returns: Void
     */
    func presentImagePicker(sourceType: UIImagePickerController.SourceType) -> Void {
        if #available(iOS 14, *), sourceType == .photoLibrary {
            let photoLibrary = PHPhotoLibrary.shared()
            let photoPickerConfig = PHPickerConfiguration(photoLibrary: photoLibrary)
            let photoPicker = PHPickerViewController(configuration: photoPickerConfig)
            photoPicker.delegate = self
            present(photoPicker, animated: true)
        } else {
            let imagePickerViewController = UIImagePickerController()
            imagePickerViewController.delegate = self
            imagePickerViewController.sourceType = sourceType
            imagePickerViewController.allowsEditing = true
            present(imagePickerViewController, animated: true)
        }
    }
    
    /**
     Presents an alert with a cancel and navigation to settings action. Shown if the user attemts to access protected resources without granting explicit access prior.
     
     The settings action navigates the user to the system settings app specific to MemeMe.
     
     - Parameters:
        - title: Alert title string
        - message: Alert message string
     
     - Returns: Void
     */
    func presentPermissionAlert(title: String, message: String) -> Void {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: AlertActionLabel.cancel, style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: AlertActionLabel.settings, style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(settingsAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: Image picker delegate functions
    
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
    
    /**
     Delegate method that fires when the user has selected a photo from the photo album to use.
     
     Posts to the notification center upon completion.
     
     - Returns: Void
     */
    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) -> Void {
        let identifiers = results.compactMap(\.assetIdentifier)
        
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        let fetchedAssetCount = fetchResult.countOfAssets(with: .image)
        
        // If we fail to fetch the selected image, assume the user needs to give access
        if (fetchedAssetCount == 0) {
            picker.dismiss(animated: true)
            presentPermissionAlert(title: PhotoLibraryPermissionAlertString.title, message: PhotoLibraryPermissionAlertString.message)
            return
        }
        
        let option = PHImageRequestOptions()
        option.isSynchronous = true
        let manager = PHImageManager.default()
        
        if let asset = fetchResult.firstObject {
            var photo = UIImage()
            
            manager.requestImage(for: asset, targetSize: CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight)), contentMode: PHImageContentMode.aspectFit, options: nil, resultHandler: {(result, info) -> Void in
                photo = result!
                self.memeModel.image = photo
                NotificationCenter.default.post(name: ObserverKey.imageUpdated, object: nil)
                picker.dismiss(animated: true)
            })
        }
        
        picker.dismiss(animated: true)
    }
}
