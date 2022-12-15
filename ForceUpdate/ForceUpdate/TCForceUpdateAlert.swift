//
//  TCForceUpdateAlert.swift
//  ForceUpdate
//
//  Created by Tarun M Krishna on 14/12/22.
//

import UIKit

public enum ForceUpdateType {
    case forceUpdate
    case softNudge
    case na
}

public class TCForceUpdateAlert {
    public static let sharedSDK = ForceUpdate.TCForceUpdateAlert()
    
    public func determineForceUpdate(versions: [String], currentVersion: String) -> ForceUpdateType {
        if currentVersion == "a" {
            return .forceUpdate
        } else if currentVersion == "b" {
            return .softNudge
        }
        return .na
    }
    
    public func showForceUpdateAlert(appName: String, updateURL: String, updateType: ForceUpdateType) -> UIAlertController {
        let alert = UIAlertController(title: "Update Alert!", message: "\(appName) has new release 🔔🔔, please update to explore latest changes", preferredStyle: .alert)
        if updateType == .softNudge {
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        }
        alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { _ in
            print("Alert updated")
            if let appURL = URL(string: updateURL) {
                UIApplication.shared.open(appURL)
            }
        }))
        return alert
    }
}
