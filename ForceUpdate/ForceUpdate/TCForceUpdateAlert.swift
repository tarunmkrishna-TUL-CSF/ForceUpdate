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

enum Constants {
    static let title = "Please Update your app."
    static let description = "Critical update has been released."
    static let cancel = "Cancel"
    static let update = "Update"
    static let timeStampDefaultsKey = "nudgesTimeStamp"
    static let results = "results"
    static let version = "version"
    static let appStoreEndPoint = "http://itunes.apple.com/lookup?bundleId="
    static let middleLayerEndPoint = "/otatacliq/getApplicationProperties.json?propertyNames="
}

enum FallBackValues {
    static let softNudgeTwoDays = 2.0
    static let regularUpdateSevenDays = 7.0
}

public class TCForceUpdateAlert {
    public static let shared = ForceUpdate.TCForceUpdateAlert()
    private var bundleID: String = ""
    private var appCurrentVersion: String?
    private var appRedirectionURL: String = ""
    private var updatePropertyName: String?
    private var baseUrl: String?
    private var elapsedDays: Double = 0.0
    private var isSoftNudgeDisplay: Bool = false
    private var isRegularUpdate: Bool = false
    private var popUpTimeStamp: TimeInterval?
    private let networkManager: NetworkCallManager = NetworkCallManager()
    public var forceUpdateModel: ForceUpdateVersionModel?
    private var updateTypeDetermined: ForceUpdateType = .na
    
    /// Set up framework with required data
    /// - Parameters:
    ///   - bundleId: bundleId to determine availability of new version
    ///   - currentVersion: currentVersion app version installed
    ///   - appStoreRedirectionURL: updateURL to redirect to AppStore
    ///   - baseMiddleLayerURL: baseMiddleLayerURL endpoint
    ///   - middleLayerPropertyName: middleLayerPropertyName parameter value for baseMiddleLayerURL
    public func buildFrameWork(
        bundleId: String,
        currentVersion: String,
        appStoreRedirectionURL: String,
        baseMiddleLayerURL: String,
        middleLayerPropertyName: String
    ) {
        bundleID = bundleId
        baseUrl = baseMiddleLayerURL
        appCurrentVersion = currentVersion
        appRedirectionURL = appStoreRedirectionURL
        updatePropertyName = middleLayerPropertyName
        popUpTimeStamp = UserDefaults.standard.value(forKey: Constants.timeStampDefaultsKey) as? TimeInterval
        getUpdateProperties()
    }
    
    /// MiddleLayer call to get Properties to determine Alert type
    private func getUpdateProperties() {
        let apiEndPoint = "\(baseUrl ?? "")\(Constants.middleLayerEndPoint)\(updatePropertyName ?? "")"
        networkManager.makeServerRequest(with: apiEndPoint) { [weak self] data, _, _ in
            guard let self = self else { return }
            if let data = data, let json = try? JSONDecoder().decode(ForceUpdateVersionModel.self, from: data) {
                self.forceUpdateModel = json
            }
            self.determineUpdateType()
        }
    }
    
    /// Determine availability of new version in AppStore
    private func appUpdateAvailable() {
        let appStoreUrl = "\(Constants.appStoreEndPoint)\(bundleID)"
        networkManager.makeServerRequest(with: appStoreUrl) { [weak self] data, response, error in
            guard let self = self else { return }
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let result = (json[Constants.results] as? [Any])?.first as? [String: Any],
               let latestVersion = result[Constants.version] as? Double {
                if Double(self.appCurrentVersion ?? "0.0") ?? 0.0 < latestVersion {
                    self.determineRegularUpdate()
                } else {
                    UserDefaults.standard.set(nil, forKey: Constants.timeStampDefaultsKey)
                }
            }
        }
    }
    
    /// Determine softNudge or forceUpdate
    private func determineUpdateType() {
        let forceUpdateVersions = forceUpdateModel?.forceUpdate.version
        let softNudges = forceUpdateModel?.flexibleUpdate.version
        isSoftNudgeDisplay = isTimeIntervalExceeded(updateType: .softNudge)
        
        if (forceUpdateVersions?.contains(appCurrentVersion ?? "") ?? false) {
            updateTypeDetermined = .forceUpdate
        } else if (softNudges?.contains(appCurrentVersion ?? "") ?? false), isSoftNudgeDisplay {
            updateTypeDetermined = .softNudge
        } else {
            appUpdateAvailable()
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.showUpdateAlert(updateType: self.updateTypeDetermined)
        }
    }
    
    /// Determine regular update
    private func determineRegularUpdate() {
        isRegularUpdate = isTimeIntervalExceeded(updateType: .regularUpdate)
        if isRegularUpdate {
            DispatchQueue.main.async {
                [weak self] in
                    guard let self = self else { return }
                self.showUpdateAlert(updateType: .regularUpdate)
            }
        }
    }
    
    /// Condition to show SoftNudges or Regular update
    /// - Parameter updateType: type of update determined
    /// - Returns: bool to show alert
    private func isTimeIntervalExceeded(updateType: ForceUpdateType) -> Bool {
        let currentTime = Date().timeIntervalSince1970
        if let timeStamp = popUpTimeStamp {
            elapsedDays = Double((currentTime - timeStamp)/86400)
            if updateType == .regularUpdate {
                // Default interval in case of network failure; regularUpdate : 7 days
                return (forceUpdateModel?.regularUpdate.recurrenceInterval ?? FallBackValues.regularUpdateSevenDays) < elapsedDays
            } else {
                // Default interval in case of network failure; softNudge : 2 days
                return (forceUpdateModel?.flexibleUpdate.recurrenceInterval ?? FallBackValues.softNudgeTwoDays) < elapsedDays
            }
        } else {
            return true
        }
    }
    
    /// Show Update pop up based on updateType
    /// - Parameter updateType: type of update determined
    private func showUpdateAlert(updateType: ForceUpdateType) {
        let alertConfig = alertInfo(updateType: updateType)
        let alert = UIAlertController(title: alertConfig.0 , message: alertConfig.1, preferredStyle: .alert)
        if updateType == .softNudge || updateType == .regularUpdate {
            let timeStampString = Date().timeIntervalSince1970
            UserDefaults.standard.set(timeStampString, forKey: Constants.timeStampDefaultsKey)
            alert.addAction(UIAlertAction(title: Constants.cancel, style: .cancel))
        }
        alert.addAction(UIAlertAction(title: Constants.update, style: .default, handler: { [weak self]_ in
            guard let self = self, let appURL = URL(string: self.appRedirectionURL) else { return }
            UIApplication.shared.open(appURL)
        }))
        
        let rootVC = UIApplication.shared.windows.first?.rootViewController
        rootVC?.present(alert, animated: true)
    }
    
    /// Text configuration of alert pop up
    /// - Parameter updateType: type of update determined
    /// - Returns: title and description
    private func alertInfo(updateType: ForceUpdateType) -> (title: String, description: String) {
        let title: String
        let description: String
        switch updateType {
        case .forceUpdate:
            title = forceUpdateModel?.forceUpdate.title ?? Constants.title
            description = forceUpdateModel?.forceUpdate.description ?? Constants.description
        case .softNudge:
            title = forceUpdateModel?.flexibleUpdate.title ?? Constants.title
            description = forceUpdateModel?.flexibleUpdate.description ?? Constants.description
        case .na:
            title = ""
            description = ""
        case .regularUpdate:
            title = forceUpdateModel?.regularUpdate.title ?? Constants.title
            description = forceUpdateModel?.regularUpdate.description ?? Constants.description
        }
        return (title, description)
    }
}


private class NetworkCallManager {
    public func makeServerRequest(with endPoint: String?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) {
        if let urlString = endPoint, let networkURL = URL(string: urlString) {
            let request = URLRequest(url: networkURL, cachePolicy: .reloadIgnoringLocalCacheData)
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                completionHandler(data, response, error)
            }
            task.resume()
        }
    }
}
