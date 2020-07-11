//
//  FlaggingLogic.swift
//  
//
//  Created by Robin Malhotra on 11/07/20.
//

import Foundation

struct FlaggingLogic {

	static func hashEvaluation(uuid: UUID) -> Int {
		Int(uuid.uuidString.unicodeScalars.map { $0.value }.reduce(0, +))
	}

	static func userFeatureFlagHash(flagUUID: UUID, userUUID: UUID) -> Int {
		hashEvaluation(uuid: flagUUID) / 2 + hashEvaluation(uuid: userUUID) / 2
	}

	static func shouldBeActive(hash: Int, rollout: Float) -> Bool {
		if rollout < 0.1 {
			return false
		} else if rollout > 0.9 {
			return true
		} else {
			return Float(hash % 10) < (rollout * Float(10))
		}
	}
	
}
