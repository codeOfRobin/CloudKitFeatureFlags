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

struct FeatureFlag {
	let name: String
	let uuid: UUID
	let rollout: Float
	let value: Bool

	init(name: String, uuid: UUID, rollout: Float, value: Bool) {
		self.name = name
		self.uuid = uuid
		self.rollout = rollout
		self.value = value
	}
}
