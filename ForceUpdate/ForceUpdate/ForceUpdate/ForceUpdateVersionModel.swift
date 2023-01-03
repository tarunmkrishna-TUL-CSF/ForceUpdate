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
    public let regularUpdate: RegularUpdate
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

public struct RegularUpdate: Codable {
    public let title: String?
    public let description: String?
    public let recurrenceInterval: Double?
}
