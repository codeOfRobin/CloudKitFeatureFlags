//
//  FeatureFlag+CloudKit.swift
//  
//
//  Created by Robin Malhotra on 11/07/20.
//

import Foundation
import CloudKit

extension FeatureFlag {
	init?(record: CKRecord) {
		guard let uuidString = record[.uuid] as? String,
			  let uuid = UUID(uuidString: uuidString),
			  let rollout = record[.rollout] as? Float,
			  let value = record[.value] as? Bool,
			  let defaultValue = record[.defaultValue] as? Bool
		else {
			return nil
		}

		self.name = record.recordID.recordName
		self.uuid = uuid
		self.rollout = rollout
		self.value = value
		self.defaultValue = defaultValue
	}

	//TODO: Fix
	func recordToCreate() -> (record: CKRecord, name: String) {
		let record = CKRecord(recordType: "FeatureFlag")
		record[.rollout] = self.rollout
		record[.value] = self.value
		record[.uuid] = self.uuid
		return (record, self.name)
	}
}

extension CKRecord {
	subscript(key: FeatureFlagKey) -> Any? {
		get {
			return self[key.rawValue]
		}
		set {
			self[key.rawValue] = newValue as? CKRecordValue
		}
	}

}
