//
//  FeatureFlag.swift
//  
//
//  Created by Robin Malhotra on 11/07/20.
//

import Foundation

enum FeatureFlagKey: String {
	/// "uuid" appears to be reserved
	case featureFlagUUID
	case rollout
	case value
}

public struct FeatureFlag {
	public let name: String
	public let uuid: UUID
	public let rollout: Float
	public let value: Bool

	public init(name: String, uuid: UUID, rollout: Float, value: Bool) {
		self.name = name
		self.uuid = uuid
		self.rollout = rollout
		self.value = value
	}
}
