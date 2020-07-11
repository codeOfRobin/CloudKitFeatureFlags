//
//  FlaggingLogicTests.swift
//  
//
//  Created by Robin Malhotra on 11/07/20.
//

import XCTest
@testable import CloudKitFeatureFlags

final class FlaggingLogicTests: XCTestCase {

	func testIncrementalRollouTo100Percent() {
		let population: Float = 100_000
		let users = (0..<Int(population)).map { _ in UUID() }

		for i in 0...10 {
			let featureFlagID = UUID()
			let rollout = Float(i)/10.0
			let included = users.lazy.map { (user) in
				FlaggingLogic.shouldBeActive(hash: FlaggingLogic.userFeatureFlagHash(flagUUID: featureFlagID, userUUID: user), rollout: rollout)
			}.filter { $0 }.count
			XCTAssertEqual(population * rollout, Float(included), accuracy: 0.3 * population / 100.0)
		}
	}

	static var allTests = [
		("testIncrementalRollouTo100Percent", testIncrementalRollouTo100Percent),
	]
	
}

