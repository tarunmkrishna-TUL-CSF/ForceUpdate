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
    public var forceUpdateModel: ForceUpdateVersionModel?
    
    /// Check if updates are available
    /// - Parameters:
    ///   - bundleId: app bundleId
    ///   - currentVersion: current App version
    ///   - completion: to determine type to update based on flag
    public func appUpdateAvailable(bundleId: String, currentVersion: String, completion: @escaping (Bool?, Error?) -> Void) {
        let appStoreUrl = "http://itunes.apple.com/lookup?bundleId=\(bundleId)"
        if let appUrl = URL(string: appStoreUrl) {
            let request = URLRequest(url: appUrl, cachePolicy: .reloadIgnoringLocalCacheData)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let result = (json["results"] as? [Any])?.first as? [String: Any],
                        let latestVersion = result["version"] as? String {
                        completion(currentVersion != latestVersion, nil)
                    }
                } else {
                    completion(false, error)
                }
            }
            task.resume()
        }
    }
    
    
    /// Determine the type of Update
    /// - Parameters:
    ///   - updateModel: data to configure and determine alert
    ///   - currentVersion: current App version
    ///   - timeStamp: previously viewed time should be in 'timeIntervalSince1970'
    /// - Returns: update type
    public func determineForceUpdate(updateModel: ForceUpdateVersionModel, currentVersion: String, timeStamp: TimeInterval) -> ForceUpdateType {
        forceUpdateModel = updateModel
        let forceUpdateVersions = forceUpdateModel?.forceUpdate.version
        let softNudges = forceUpdateModel?.flexibleUpdate.version
        let currentTime = Date().timeIntervalSince1970
        let elapsedDays = Double((currentTime - timeStamp)/86400)
        
        let isSoftNudgeDisplay = (forceUpdateModel?.flexibleUpdate.recurrenceInterval ?? 0.0) < elapsedDays
        if (forceUpdateVersions?.contains(currentVersion) ?? false) {
            return .forceUpdate
        } else if (softNudges?.contains(currentVersion) ?? false), isSoftNudgeDisplay {
            return .softNudge
        } else {
            return .na
        }
    }
    
    /// Alert ViewController for updates
    /// - Parameters:
    ///   - updateURL: AppStore URL
    ///   - updateType: updateType to configure View
    /// - Returns: UIAlertController
    public func showForceUpdateAlert(updateURL: String, updateType: ForceUpdateType) -> UIAlertController {
        let alertConfig = configureTitleDescription(updateType: updateType)
        let alert = UIAlertController(title: alertConfig.0 , message: alertConfig.1, preferredStyle: .alert)
        if updateType == .softNudge {
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        }
        alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { _ in
            if let appURL = URL(string: updateURL) {
                UIApplication.shared.open(appURL)
            }
        }))
        return alert
    }
    
    private func configureTitleDescription(updateType: ForceUpdateType) -> (String?, String?) {
        var title: String?
        var description: String?
        switch updateType {
        case .forceUpdate:
            title = forceUpdateModel?.forceUpdate.title
            description = forceUpdateModel?.forceUpdate.description
        case .softNudge:
            title = forceUpdateModel?.flexibleUpdate.title
            description = forceUpdateModel?.flexibleUpdate.description
        case .na:
            break
        }
        return (title, description)
    }
}
