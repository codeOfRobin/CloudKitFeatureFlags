//
//  AdditionalUserData.swift
//  
//
//  Created by Robin Malhotra on 11/07/20.
//

import Foundation
import CloudKit

enum AdditionalUserDataKeys: String {
	case userFeatureFlaggingID
}

public struct AdditionalUserData {
	public let featureFlaggingID: UUID
}

extension AdditionalUserData {
	init?(record: CKRecord) {
		guard let featureFlagIDString = record[.userFeatureFlaggingID] as? String,
			  let uuid = UUID(uuidString: featureFlagIDString) else {
			return nil
		}
		self.featureFlaggingID = uuid
	}
}

extension CKRecord {
	
	subscript(key: AdditionalUserDataKeys) -> Any? {
		get {
			return self[key.rawValue]
		}
		set {
			self[key.rawValue] = newValue as? CKRecordValue
		}
	}
}
