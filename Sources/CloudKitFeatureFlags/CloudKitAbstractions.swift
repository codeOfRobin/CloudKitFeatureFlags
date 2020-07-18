//
//  CloudKitAbstractions.swift
//  
//
//  Created by Robin Malhotra on 17/07/20.
//

import CloudKit

public protocol Database {
	func fetch(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord?, Error?) -> Void)
	func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void)
	func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?, completionHandler: @escaping ([CKRecord]?, Error?) -> Void)
}

public protocol Container {

	/// I'd love to name this `publicCloudDatabase` but Swift won't let me
	var featureFlaggingDatabase: Database { get }

	func fetchUserRecordID(completionHandler: @escaping (CKRecord.ID?, Error?) -> Void)
}

extension CKDatabase: Database { }

extension CKContainer: Container {
	public var featureFlaggingDatabase: Database {
		return publicCloudDatabase
	}
}
