//
//  FeatureFlagCoordinator.swift
//  
//
//  Created by Robin Malhotra on 11/07/20.
//

import Foundation
import CloudKit
import Combine

class FeatureFlagCoordinator {

	let container: CKContainer
	//TODO: make this a store that's updated from CK subscription
	let featureFlagsFuture: Future<[String: FeatureFlag], Error>
	let userDataFuture: Future<AdditionalUserData, Error>

	init(container: CKContainer, featureFlagsFuture: Future<[String : FeatureFlag], Error>, userDataFuture: Future<AdditionalUserData, Error>) {
		self.container = container
		self.featureFlagsFuture = featureFlagsFuture
		self.userDataFuture = userDataFuture
	}

	init(container: CKContainer) {
		self.container = container
		self.userDataFuture = Future<AdditionalUserData, Error> { (promise) in
			container.fetchUserRecordID { (recordID, error) in
				guard let recordID = recordID else {
					//TODO: Fix
					promise(.failure(error!))
					return
				}
				container.publicCloudDatabase.fetch(withRecordID: recordID) { (record, error) in
					guard let record = record else {
						//TODO: Fix
						promise(.failure(error!))
						return
					}
					guard let data = AdditionalUserData(record: record) else {
						/// User doesn't have an ID set
						record[.userFeatureFlaggingID] = UUID().uuidString
						container.publicCloudDatabase.save(record) { (record, error) in
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

		self.featureFlagsFuture = Future{ (promise) in
			let query = CKQuery(recordType: "FeatureFlag", predicate: NSPredicate(value: true))

			container.publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
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

	func isSomeFeatureEnabled(name: String) -> AnyPublisher<Bool, Error> {
		Publishers.CombineLatest(featureFlagsFuture, userDataFuture).map { (dict, userData) -> Bool in
			guard let ff = dict[name] else {
				return false
			}

			return FlaggingLogic.shouldBeActive(hash: FlaggingLogic.userFeatureFlagHash(flagUUID: ff.uuid, userUUID: userData.featureFlaggingID), rollout: ff.rollout)
		}.eraseToAnyPublisher()
	}
}
