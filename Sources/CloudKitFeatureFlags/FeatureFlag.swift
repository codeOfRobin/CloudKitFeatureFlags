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
    
    public struct Name: RawRepresentable, Hashable, Equatable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
    }
    
    let name: FeatureFlag.Name
	let uuid: UUID
	let rollout: Float
	let value: Bool

	public init(name: Name, uuid: UUID, rollout: Float, value: Bool) {
		self.name = name
		self.uuid = uuid
		self.rollout = rollout
		self.value = value
	}
}
