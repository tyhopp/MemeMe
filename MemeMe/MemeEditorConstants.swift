//
//  MemeEditorConstants.swift
//  MemeMe
//
//  Created by Ty Hopp on 29/10/21.
//

import Foundation

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
