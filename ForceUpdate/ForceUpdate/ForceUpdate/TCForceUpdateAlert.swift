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
    case regularUpdate
    case na
}

struct TCForceUpdateAlertConstant {
    static let title = "Please Update your app."
    static let description = "Critical update has been released."
    static let cancel = "Cancel"
    static let update = "Update"
    static let timeStampDefaultsKey = "nudgesTimeStamp"
    static let results = "results"
    static let version = "version"
    
    struct FallBackValues {
        static let softNudgeTwoDays = 2.0
        static let regularUpdateSevenDays = 7.0
    }
}

public class TCForceUpdateAlert {
    public static let sharedSDK = ForceUpdate.TCForceUpdateAlert()
    private var bundleID: String = ""
    private var appCurrentVersion: String?
    private var appRedirectionURL: String = ""
    private var elapsedDays: Double = 0.0
    private var isSoftNudgeDisplay: Bool = false
    private var isRegularUpdate: Bool = false
    private var popUpTimeStamp: TimeInterval?
    public var forceUpdateModel: ForceUpdateVersionModel?
    private var updateTypeDetermined: ForceUpdateType = .na
    
    /// Set up framework with required data
    /// - Parameters:
    ///   - updateModel: data model to determine update types
    ///   - bundleId: bundleId to determine availability of new version
    ///   - currentVersion: currentVersion app version installed
    ///   - timeStamp: timeStamp of last softNudge or regularUpdate
    ///   - updateURL: updateURL to redirect to AppStore
    public func buildFrameWork(updateModel: ForceUpdateVersionModel, bundleId: String, currentVersion: String, timeStamp: TimeInterval?, updateURL: String) {
        forceUpdateModel = updateModel
        bundleID = bundleId
        appCurrentVersion = currentVersion
        popUpTimeStamp = timeStamp
        appRedirectionURL = updateURL
    }
    
    /// Determine availability of new version in AppStore
    public func appUpdateAvailable() {
        let appStoreUrl = "http://itunes.apple.com/lookup?bundleId=\(bundleID)"
        if let appUrl = URL(string: appStoreUrl) {
            let request = URLRequest(url: appUrl, cachePolicy: .reloadIgnoringLocalCacheData)
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let result = (json[TCForceUpdateAlertConstant.results] as? [Any])?.first as? [String: Any],
                   let latestVersion = result[TCForceUpdateAlertConstant.version] as? String {
                    if self.appCurrentVersion != latestVersion {
                        self.determineRegularUpdate()
                    } else {
                        UserDefaults.standard.set(nil, forKey: TCForceUpdateAlertConstant.timeStampDefaultsKey)
                    }
                }
            }
            task.resume()
        }
    }
    
    /// Determine softNudge or forceUpdate
    public func determineForceUpdate() {
        let forceUpdateVersions = forceUpdateModel?.forceUpdate.version
        let softNudges = forceUpdateModel?.flexibleUpdate.version
        let currentTime = Date().timeIntervalSince1970
        
        if let timeStamp = popUpTimeStamp {
            elapsedDays = Double((currentTime - timeStamp)/86400)
            // Default interval in case of network failure; softNudge : 2 days
            isSoftNudgeDisplay = (forceUpdateModel?.flexibleUpdate.recurrenceInterval ?? TCForceUpdateAlertConstant.FallBackValues.softNudgeTwoDays) < elapsedDays
        } else {
            isSoftNudgeDisplay = true
        }
        if (forceUpdateVersions?.contains(appCurrentVersion ?? "") ?? false) {
            updateTypeDetermined = .forceUpdate
        } else if (softNudges?.contains(appCurrentVersion ?? "") ?? false), isSoftNudgeDisplay {
            updateTypeDetermined = .softNudge
        } else {
            return
        }
        showForceUpdateAlert(updateType: updateTypeDetermined)
    }
    
    /// Determine regular update
    private func determineRegularUpdate() {
        let currentTime = Date().timeIntervalSince1970
        if let timeStamp = popUpTimeStamp {
            elapsedDays = Double((currentTime - timeStamp)/86400)
            // Default interval in case of network failure; regularUpdate : 7 days
            isRegularUpdate = (forceUpdateModel?.regularUpdate.recurrenceInterval ?? TCForceUpdateAlertConstant.FallBackValues.regularUpdateSevenDays) < elapsedDays
        } else {
            isRegularUpdate = true
        }
        if isRegularUpdate {
            showForceUpdateAlert(updateType: .regularUpdate)
        }
    }
    
    /// Show Update pop up based on updateType
    /// - Parameter updateType: type of update determined
    private func showForceUpdateAlert(updateType: ForceUpdateType) {
        let alertConfig = configureTitleDescription(updateType: updateType)
        let alert = UIAlertController(title: alertConfig.0 , message: alertConfig.1, preferredStyle: .alert)
        if updateType == .softNudge || updateType == .regularUpdate {
            let timeStampString = Date().timeIntervalSince1970
            UserDefaults.standard.set(timeStampString, forKey: TCForceUpdateAlertConstant.timeStampDefaultsKey)
            alert.addAction(UIAlertAction(title: TCForceUpdateAlertConstant.cancel, style: .cancel))
        }
        alert.addAction(UIAlertAction(title: TCForceUpdateAlertConstant.update, style: .default, handler: { [weak self]_ in
            guard let self = self, let appURL = URL(string: self.appRedirectionURL) else { return }
            UIApplication.shared.open(appURL)
        }))
        
        let rootVC = UIApplication.shared.windows.first?.rootViewController
        DispatchQueue.main.async {
            rootVC?.present(alert, animated: true)
        }
    }
    
    /// Text configuration of alert pop up
    /// - Parameter updateType: type of update determined
    /// - Returns: title and description
    private func configureTitleDescription(updateType: ForceUpdateType) -> (String, String) {
        var title: String = ""
        var description: String = ""
        switch updateType {
        case .forceUpdate:
            title = forceUpdateModel?.forceUpdate.title ?? TCForceUpdateAlertConstant.title
            description = forceUpdateModel?.forceUpdate.description ?? TCForceUpdateAlertConstant.description
        case .softNudge:
            title = forceUpdateModel?.flexibleUpdate.title ?? TCForceUpdateAlertConstant.title
            description = forceUpdateModel?.flexibleUpdate.description ?? TCForceUpdateAlertConstant.description
        case .na:
            break
        case .regularUpdate:
            title = forceUpdateModel?.regularUpdate.title ?? TCForceUpdateAlertConstant.title
            description = forceUpdateModel?.regularUpdate.description ?? TCForceUpdateAlertConstant.description
        }
        return (title, description)
    }
}
