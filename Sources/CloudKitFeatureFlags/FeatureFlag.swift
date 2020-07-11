//
//  FeatureFlag.swift
//  
//
//  Created by Robin Malhotra on 11/07/20.
//

import Foundation

enum FeatureFlagKey: String {
	case uuid
	case rollout
	case value
	case defaultValue
}

struct FeatureFlag {
	let name: String
	let uuid: UUID
	let rollout: Float
	let defaultValue: Bool
	let value: Bool

	init(name: String, uuid: UUID, rollout: Float, defaultValue: Bool, value: Bool) {
		self.name = name
		self.uuid = uuid
		self.rollout = rollout
		self.defaultValue = defaultValue
		self.value = value
	}
}
