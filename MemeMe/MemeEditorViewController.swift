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
    
    // Top toolbar
    @IBOutlet weak var topToolbar: UIToolbar!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    // Image view
    @IBOutlet weak var imageView: UIImageView!
    
    // Text fields
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    
    // Bottom toolbar
    @IBOutlet weak var bottomToolbar: UIToolbar!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var albumButton: UIBarButtonItem!
    
    // MARK: Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMemeText(textField: topTextField, text: TextFieldString.top, tag: TextFieldTag.top)
        setupMemeText(textField: bottomTextField, text: TextFieldString.bottom, tag: TextFieldTag.bottom)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBottomToolbar()
        setupObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObservers()
    }
    
    // MARK: Top toolbar actions
    
    @IBAction func share(_ sender: Any) {
        let memedImage = generateMemedImage()
        let activityViewController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        if activityViewController.responds(to: #selector(getter: popoverPresentationController)) {
            activityViewController.popoverPresentationController?.sourceView = view
        }
        activityViewController.completionWithItemsHandler = { activity, success, items, error in
            if success {
                self.save(memedImage: memedImage)
            }
        }
        present(activityViewController, animated: true)
    }
    
    @IBAction func reset(_ sender: Any) {
        topTextField.text = TextFieldString.top
        bottomTextField.text = TextFieldString.bottom
        imageView.image = nil
        shareButton.isEnabled = false
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
    
    @IBAction func showAlbum(_ sender: Any) {
        if #available(iOS 14, *) {
            let photoLibraryPermission = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            switch photoLibraryPermission {
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
    
    // MARK: Observer methods
    
    func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: Setup methods
    
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
            NSAttributedString.Key.strokeWidth: -4.0
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
    
    func setupBottomToolbar() -> Void {
        shareButton.isEnabled = false
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera) || AVCaptureDevice.authorizationStatus(for: .video) == .restricted
    }
    
    // MARK: Meme methods
    
    func generateMemedImage() -> UIImage {
        // Hide toolbars
        showHideToolbars(hidden: true)
        
        // Combine original image and text into memed image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Show toolbars
        showHideToolbars(hidden: false)
        
        return memedImage
    }
    
    func showHideToolbars(hidden: Bool) {
        topToolbar.isHidden = hidden
        bottomToolbar.isHidden = hidden
    }
    
    func save(memedImage: UIImage) {
        // Create the meme
        let _ = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, originalImage: imageView.image!, memedImage: memedImage)
        
        // TODO: It's unclear what the course requires us to do here, leave it for now
    }
    
    // MARK: Image picker presentation methods
    
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
    
    // MARK: Image picker delegate methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) -> Void {

        guard let image = info[.editedImage] as? UIImage else {
            return
        }
        
        imageView.image = image
        shareButton.isEnabled = true
        picker.dismiss(animated: true)
    }
    
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
                self.imageView.image = photo
                self.shareButton.isEnabled = true
                picker.dismiss(animated: true)
            })
        }
    }
    
    // MARK: Text field delegate and helper methods
    
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
        switch textField.tag {
        case TextFieldTag.top.rawValue:
            if textField.text == "" {
                textField.text = TextFieldString.top
            }
        case TextFieldTag.bottom.rawValue:
            if textField.text == "" {
                textField.text = TextFieldString.bottom
            }
        default:
            return
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
    
    // MARK: Keyboard methods
    
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    @objc func keyboardWillShow(_ notification: Notification) -> Void {
        if !bottomTextField.isFirstResponder {
            return
        }
        view.frame.origin.y = -getKeyboardHeight(notification)
    }
    
    @objc func keyboardWillHide(_ notification: Notification) -> Void {
        if !bottomTextField.isFirstResponder {
            return
        }
        view.frame.origin.y += getKeyboardHeight(notification)
    }
}
