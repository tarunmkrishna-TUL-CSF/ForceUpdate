//
//  ForceUpdateVersionModel.swift
//  ForceUpdate
//
//  Created by Tarun M Krishna on 15/12/22.
//

import Foundation

public struct ForceUpdateVersionModel: Decodable {
    public let forceUpdate: UpdateData
    public let flexibleUpdate: UpdateData
    public let regularUpdate: UpdateData
}

public struct UpdateData: Decodable {
    public let title: String
    public let description: String
    public let version: [String]?
    public let recurrenceInterval: Double?
}
