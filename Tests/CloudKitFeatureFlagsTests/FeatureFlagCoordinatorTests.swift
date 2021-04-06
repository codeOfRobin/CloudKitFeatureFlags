//
//  FeatureFlagCoordinatorTests.swift
//  
//
//  Created by Robin Malhotra on 17/07/20.
//

import XCTest
import CloudKit
@testable import CloudKitFeatureFlags

/// Simulates the user data retrieval that CloudKit would do for us
protocol UserDataDelegate: class {
	func fetchUserRecordID(completionHandler: @escaping (CKRecord.ID?, Error?) -> Void)
	func fetch(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord?, Error?) -> Void)
}

class TestUserDataDelegate: UserDataDelegate {

	let userRecordName: UUID
	let userFeatureFlagID: UUID

	internal init(userRecordName: UUID, userFeatureFlagID: UUID) {
		self.userRecordName = userRecordName
		self.userFeatureFlagID = userFeatureFlagID
	}

	func fetch(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
		let record = CKRecord(recordType: "random", recordID: .init(recordName: userRecordName.uuidString))
		record[.userFeatureFlaggingID] = userFeatureFlagID
		completionHandler(record, nil)
	}

	func fetchUserRecordID(completionHandler: @escaping (CKRecord.ID?, Error?) -> Void) {
		completionHandler(.init(recordName: userRecordName.uuidString), nil)
	}
}

class TestContainer: Container {

	let database: Database
	weak var userDataDelegate: UserDataDelegate?

	internal init(database: Database) {
		self.database = database
	}

	func fetchUserRecordID(completionHandler: @escaping (CKRecord.ID?, Error?) -> Void) {
		userDataDelegate?.fetchUserRecordID(completionHandler: completionHandler)
	}

	var featureFlaggingDatabase: Database {
		return database
	}
}

class TestDatabase: Database {

	let featureFlags: [FeatureFlag]
	weak var delegate: UserDataDelegate?

	init(featureFlags: [FeatureFlag]) {
		self.featureFlags = featureFlags
	}

	func fetch(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
		self.delegate?.fetch(withRecordID: recordID, completionHandler: completionHandler)
	}

	func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
		completionHandler(record, nil)
	}

	func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?, completionHandler: @escaping ([CKRecord]?, Error?) -> Void) {
		completionHandler(featureFlags.map { $0.convertToRecord() }, nil)
	}
}


final class FeatureFlagCoordinatorTests: XCTestCase {

	func testStubbedCoordinator() {
		let userPopulation = 100_000
        
        let rollouts = (0...10).map { i in Float(i)/10.0 }
        let featureFlags = rollouts.map { rollout in FeatureFlag(name: FeatureFlag.Name(rawValue: UUID().uuidString), uuid: UUID(), rollout: rollout, value: true) }
        let testDatabase = TestDatabase(featureFlags: featureFlags)
        let testContainer = TestContainer(database: testDatabase)
        let userProxies = (0..<userPopulation)
            .map { _ in TestUserDataDelegate(userRecordName: UUID(), userFeatureFlagID: UUID()) }
        
        func switchUser(in container: TestContainer, with userDataDelegate: UserDataDelegate) -> TestContainer {
            container.userDataDelegate = userDataDelegate
            (container.database as? TestDatabase)?.delegate = userDataDelegate
            return container
        }
        
        func simulate(flags: [FeatureFlag], in repo: CloudKitFeatureFlagsRepository, currentResultSet: [FeatureFlag.Name: Int]) -> [FeatureFlag.Name: Int] {
            return flags.reduce(into: currentResultSet) { (currentResults, flag) in
                var calculatedValue: Bool!
                let dispatchSemaphore = DispatchSemaphore(value: 0)
                _ = repo.featureEnabled(name: flag.name.rawValue)
                    .sink(receiveCompletion: { (_) in }, receiveValue: { (value) in
                        calculatedValue = value
                        dispatchSemaphore.signal()
                    })
                dispatchSemaphore.wait()
                currentResults[flag.name, default: 0] += (calculatedValue == true) ? 1 : 0
            }
        }
        
        let collectedResults = userProxies.reduce([FeatureFlag.Name: Int]()) { (calculation, userProxy) in
            let testContainer = switchUser(in: testContainer, with: userProxy)
            let coordinator = CloudKitFeatureFlagsRepository(container: testContainer)
            return simulate(flags: featureFlags, in: coordinator, currentResultSet: calculation)
        }

        for flag in featureFlags {
            /// 0.5% accuracy
            let measuredRollout = Float(collectedResults[flag.name]!) / (Float(userPopulation))
            print(measuredRollout)
            XCTAssertEqual(measuredRollout, flag.rollout, accuracy: 0.005)
        }
        
        
	}

	static var allTests = [
		("testStubbedCoordinator", testStubbedCoordinator),
	]

}
