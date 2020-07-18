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
		guard let uuidString = record[.featureFlagUUID] as? String,
			  let uuid = UUID(uuidString: uuidString),
			  let rollout = record[.rollout] as? Double,
			  let value = record[.value] as? Bool
		else {
			return nil
		}

		self.name = record.recordID.recordName
		self.uuid = uuid
		self.rollout = Float(rollout)
		self.value = value
	}

	//TODO: Fix
	public func convertToRecord() -> CKRecord {
		let record = CKRecord(recordType: "FeatureFlag", recordID: .init(recordName: self.name))
		record[.rollout] = self.rollout
		record[.value] = self.value
		record[.featureFlagUUID] = self.uuid.uuidString
		return record
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
