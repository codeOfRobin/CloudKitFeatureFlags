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

class TestDataDelegate: UserDataDelegate {

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
	weak var delegate: UserDataDelegate?

	internal init(database: Database) {
		self.database = database
	}

	func fetchUserRecordID(completionHandler: @escaping (CKRecord.ID?, Error?) -> Void) {
		delegate?.fetchUserRecordID(completionHandler: completionHandler)
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

		for i in 0...10 {
			let rollout = Float(i)/10.0
			let featureFlag = FeatureFlag(name: UUID().uuidString, uuid: UUID(), rollout: rollout, value: true)
			let count = (0..<userPopulation)
				.map { _ in TestDataDelegate(userRecordName: UUID(), userFeatureFlagID: UUID()) }
				.map { delegate in
					let testDatabase = TestDatabase(featureFlags: [featureFlag])
					let testContainer = TestContainer(database: testDatabase)
					testDatabase.delegate = delegate
					testContainer.delegate = delegate
					let coordinator = CloudKitFeatureFlagsRepository(container: testContainer)
					var calculatedValue: Bool!
					let dispatchSemaphore = DispatchSemaphore(value: 0)
					_ = coordinator.featureEnabled(name: featureFlag.name).sink { (_) in } receiveValue: { (value) in
						calculatedValue = value
						dispatchSemaphore.signal()
					}
					dispatchSemaphore.wait()
					return calculatedValue
				}.filter { $0 }.count
			XCTAssertEqual(Float(count), Float(userPopulation) * rollout, accuracy: 0.5  * Float(userPopulation) / 100.0)
		}
	}

	static var allTests = [
		("testStubbedCoordinator", testStubbedCoordinator),
	]

}
