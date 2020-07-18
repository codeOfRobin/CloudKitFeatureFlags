//
//  FeatureFlagCoordinatorTests.swift
//  
//
//  Created by Robin Malhotra on 17/07/20.
//

import XCTest
import CloudKit
@testable import CloudKitFeatureFlags

class TestContainer: Container {

	let userRecordName: String
	let database: Database

	internal init(userRecordName: String, database: Database) {
		self.userRecordName = userRecordName
		self.database = database
	}

	func fetchUserRecordID(completionHandler: @escaping (CKRecord.ID?, Error?) -> Void) {
		let id = CKRecord.ID(recordName: userRecordName)
		completionHandler(id, nil)
	}

	var featureFlaggingDatabase: Database {
		return database
	}
}

class TestDatabase: Database {

	let userRecord: AdditionalUserData
	let featureFlags: [FeatureFlag]

	init(userRecord: AdditionalUserData, featureFlags: [FeatureFlag]) {
		self.userRecord = userRecord
		self.featureFlags = featureFlags
	}

	func fetch(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
		let record = CKRecord(recordType: "something")
		completionHandler(record, nil)
	}

	func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
		completionHandler(record, nil)
	}

	func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?, completionHandler: @escaping ([CKRecord]?, Error?) -> Void) {
		completionHandler([], nil)
	}
}


final class FeatureFlagCoordinatorTests: XCTestCase {

	lazy var testContainer = TestContainer(userRecordName: "testUser", database: TestDatabase(userRecord: AdditionalUserData(featureFlaggingID: UUID()), featureFlags: []))

	func testStubbedCoordinator() {
		let coordinator = FeatureFlagCoordinator(container: testContainer)

		let expectationFalse = expectation(description: "false")

		let x = coordinator.isSomeFeatureEnabled(name: "something")
		x.sink(receiveCompletion: { (completion) in

		}) { (value) in
			expectationFalse.fulfill()
		}

		wait(for: [expectationFalse], timeout: 10)
	}

	static var allTests = [
		("testStubbedCoordinator", testStubbedCoordinator),
	]

}
