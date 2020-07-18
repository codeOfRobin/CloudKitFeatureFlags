//
//  FeatureFlagCoordinator.swift
//  
//
//  Created by Robin Malhotra on 11/07/20.
//

import Foundation
import CloudKit
import Combine

class CloudKitFeatureFlagsRepository {

	let container: Container
	//TODO: make this a store that's updated from CK subscription
	private let featureFlagsFuture: Future<[String: FeatureFlag], Error>
	private let userDataFuture: Future<AdditionalUserData, Error>

	init(container: Container) {
		self.container = container
		self.userDataFuture = Future<AdditionalUserData, Error> { (promise) in
			container.fetchUserRecordID { (recordID, error) in
				guard let recordID = recordID else {
					//TODO: Fix
					promise(.failure(error!))
					return
				}
				container.featureFlaggingDatabase.fetch(withRecordID: recordID) { (record, error) in
					guard let record = record else {
						//TODO: Fix
						promise(.failure(error!))
						return
					}
					guard let data = AdditionalUserData(record: record) else {
						/// User doesn't have an ID set
						record[.userFeatureFlaggingID] = UUID().uuidString
						container.featureFlaggingDatabase.save(record) { (record, error) in
							guard let record = record, let data = AdditionalUserData(record: record) else {
								//TODO: Fix
								promise(.failure(error!))
								return
							}
							promise(.success(data))
						}
						return
					}
					promise(.success(data))
				}
			}
		}

		self.featureFlagsFuture = Future { (promise) in
			let query = CKQuery(recordType: "FeatureFlag", predicate: NSPredicate(value: true))

			container.featureFlaggingDatabase.perform(query, inZoneWith: nil) { (records, error) in
				guard let records = records else {
					//TODO: Fix
					promise(.failure(error!))
					return
				}
				let flags = records.compactMap(FeatureFlag.init).reduce(into: [:], { (dict, flag) in
					dict[flag.name] = flag
				})
				promise(.success(flags))
			}
		}
	}

	@discardableResult func featureEnabled(name: String) -> AnyPublisher<Bool, Error> {
		Publishers.CombineLatest(featureFlagsFuture, userDataFuture).map { (dict, userData) -> Bool in
			guard let ff = dict[name] else {
				return false
			}
			//TODO: figure out what to do here
			return FlaggingLogic.shouldBeActive(hash: FlaggingLogic.userFeatureFlagHash(flagUUID: ff.uuid, userUUID: userData.featureFlaggingID), rollout: ff.rollout)
		}.eraseToAnyPublisher()
	}
}
