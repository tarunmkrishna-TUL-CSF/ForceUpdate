//
//  ForceUpdateVersionModel.swift
//  ForceUpdate
//
//  Created by Tarun M Krishna on 15/12/22.
//

import Foundation

public struct ForceUpdateVersionModel: Codable {
    public let forceUpdate: ForceUpdateUser
    public let flexibleUpdate: FlexibleUpdateUser
}

public struct ForceUpdateUser: Codable {
    public let title: String?
    public let description: String?
    public let version: [String]?
}

public struct FlexibleUpdateUser: Codable {
    public let title: String?
    public let description: String?
    public let version: [String]?
    public let recurrenceInterval: Double?
}
