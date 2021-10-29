//
//  ViewController.swift
//  MemeMe
//
//  Created by Ty Hopp on 25/10/21.
//

import UIKit
import AVFoundation
import PhotosUI

class MemeEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate, UITextFieldDelegate {
    
    // MARK: Outlets
    
    // Top toolbar buttons
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    // Image view
    @IBOutlet weak var imageView: UIImageView!
    
    // Text fields
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    
    // Bottom toolbar buttons
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
        static let message = "Photo library access is required to use photos for memes. Grant access in settings."
    }
    
    struct PhotoLibraryLimitedPermissionAlertString {
        static let title = "Allow Photo Access"
        static let message = "The selected photo requires permission to use for memes. Grant access in settings."
    }
    
    struct AlertActionLabel {
        static let cancel = "Cancel"
        static let settings = "Settings"
    }
    
    struct TextFieldString {
        static let top = "TOP"
        static let bottom = "BOTTOM"
    }
    
    struct ObserverKey {
        static let imageUpdated: NSNotification.Name = NSNotification.Name(rawValue: "image-updated")
        static let topTextUpdated: NSNotification.Name = NSNotification.Name(rawValue: "top-text-updated")
        static let bottomTextUpdated: NSNotification.Name = NSNotification.Name(rawValue: "bottom-text-updated")
    }
    
    enum TextFieldTag: Int {
        case top, bottom
    }
    
    let notificationCenter = NotificationCenter.default
    
    // MARK: Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMemeText(textField: topTextField, text: TextFieldString.top, tag: TextFieldTag.top)
        setupMemeText(textField: bottomTextField, text: TextFieldString.bottom, tag: TextFieldTag.bottom)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // TODO: Extract into own function
        shareButton.isEnabled = false
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera) || AVCaptureDevice.authorizationStatus(for: .video) == .restricted
        
        setupObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObservers()
    }
    
    // MARK: Top toolbar actions
    
    @IBAction func reset() {
        topTextField.text = TextFieldString.top
        bottomTextField.text = TextFieldString.bottom
        
    }
    
    
    // MARK: Bottom toolbar actions
    
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
    
    @IBAction func showAlbum() {
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
    
    // MARK: Observer functions
    
    func setupObservers() {
        // Update the image view when the meme model image changes
        notificationCenter.addObserver(forName: ObserverKey.imageUpdated, object: nil, queue: nil) { _ in
            self.imageView.image = self.memeModel.image
        }
        
        // Adjust text fields when the keyboard appears
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removeObservers() {
        notificationCenter.removeObserver(self, name: ObserverKey.imageUpdated, object: nil)
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: Setup functions
    
    /**
     Sets up a text input field.
     
     - Parameters:
        - textField: The `UITextField` to set up
        - text: The initial text populating the field
     
     - Returns: Void
     */
    func setupMemeText(textField: UITextField, text: String, tag: TextFieldTag) -> Void {
        var strokeColor: UIColor = .black
        var foregroundColor: UIColor = .white
        
        if #available(iOS 13, *) {
            strokeColor = .label
            foregroundColor = .systemBackground
        }
        
        let memeTextAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.strokeColor: strokeColor,
            NSAttributedString.Key.foregroundColor: foregroundColor,
            NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
            NSAttributedString.Key.strokeWidth: 4.0
        ]
        
        textField.defaultTextAttributes = memeTextAttributes
        textField.textAlignment = .center
        textField.borderStyle = .none
        textField.autocapitalizationType = .allCharacters
        textField.returnKeyType = .done
        textField.delegate = self
        textField.tag = tag.rawValue
        textField.text = text
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
     Fires when the user has selected a captured photo to use.
     
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
     Fires when the user has selected a photo from the photo album to use.
     
     Posts to the notification center upon completion.
     
     - Returns: Void
     */
    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) -> Void {
        let identifiers = results.compactMap(\.assetIdentifier)
        
        // Cancel button touched
        if (identifiers.isEmpty) {
            picker.dismiss(animated: true)
            return
        }
        
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        let fetchedAssetCount = fetchResult.countOfAssets(with: .image)
        let photoLibraryPermission = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        // Photo without permission touched
        if (photoLibraryPermission == .limited && fetchedAssetCount == 0) {
            picker.dismiss(animated: true)
            presentPermissionAlert(title: PhotoLibraryLimitedPermissionAlertString.title, message: PhotoLibraryLimitedPermissionAlertString.message)
            return
        }
        
        let option = PHImageRequestOptions()
        option.isSynchronous = true
        let manager = PHImageManager.default()
        
        if let asset = fetchResult.firstObject {
            var photo = UIImage()
            
            // Convert asset to image
            manager.requestImage(for: asset, targetSize: CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight)), contentMode: PHImageContentMode.aspectFit, options: nil, resultHandler: {(result, info) -> Void in
                photo = result!
                self.memeModel.image = photo
                NotificationCenter.default.post(name: ObserverKey.imageUpdated, object: nil)
                picker.dismiss(animated: true)
            })
        }
    }
    
    // MARK: Text field delegate related functions
    
    /**
     Fires when the return key is tapped on the keyboard.

     - Parameter textField: The currently focused `UITextField`.

     Return true to hide the keyboard, false to ignore.

     - Returns: Boolean
     */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) -> Void {
        if textFieldHasDefaultText(textField: textField) {
            textField.text = ""
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) -> Void {
        if textField.text == "" {
            switch textField.tag {
            case TextFieldTag.top.rawValue:
                textField.text = TextFieldString.top
            case TextFieldTag.bottom.rawValue:
                textField.text = TextFieldString.bottom
            default:
                return
            }
        }
    }
    
    func textFieldHasDefaultText(textField: UITextField) -> Bool {
        if textField.tag == TextFieldTag.top.rawValue && textField.text == TextFieldString.top {
            return true
        } else if textField.tag == TextFieldTag.bottom.rawValue && textField.text == TextFieldString.bottom {
            return true
        } else {
            return false
        }
    }
    
    // MARK: Keyboard functions
    
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    @objc func keyboardWillShow(_ notification: Notification) -> Void {
        if topTextField.isEditing {
            return
        }
        view.frame.origin.y -= getKeyboardHeight(notification)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) -> Void {
        if topTextField.isEditing {
            return
        }
        view.frame.origin.y += getKeyboardHeight(notification)
    }
}
