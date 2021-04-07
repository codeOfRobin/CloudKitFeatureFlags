//
//  FeatureFlagCoordinator.swift
//  
//
//  Created by Robin Malhotra on 11/07/20.
//

import Foundation
import CloudKit
import Combine
import CryptoKit

public class CloudKitFeatureFlagsRepository {

	let container: Container
	//TODO: make this a store that's updated from CK subscription
    private let featureFlagsFuture: Future<[FeatureFlag.Name: FeatureFlag], Error>
	private let userDataFuture: Future<AdditionalUserData, Error>

	public init(container: Container) {
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

	@discardableResult public func featureEnabled(name: String) -> AnyPublisher<Bool, Error> {
		Publishers.CombineLatest(featureFlagsFuture, userDataFuture).map { (dict, userData) -> Bool in
            guard let ff = dict[FeatureFlag.Name(rawValue: name)] else {
				return false
			}
			//TODO: figure out what to do here
			return FlaggingLogic.shouldBeActive(hash: FlaggingLogic.userFeatureFlagHash(flagUUID: ff.uuid, userUUID: userData.featureFlaggingID), rollout: ff.rollout)
		}.eraseToAnyPublisher()
	}
}


extension CloudKitFeatureFlagsRepository {
    public struct VerificationFunctions {
        private var base: CloudKitFeatureFlagsRepository
        private var session: URLSession
        init(_ base: CloudKitFeatureFlagsRepository, session: URLSession = .shared) {
            self.base = base
            self.session = session
        }
            
        func getDebuggingData() -> AnyPublisher<([FeatureFlag.Name: FeatureFlag], AdditionalUserData),Error> {
            return base.getDebuggingData()
        }
        
        public func sendDataToVerificationServer(url: URL) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
            let requests = getDebuggingData()
                .tryMap { (flags, userData) -> URLRequest? in
                    guard let userIDData = userData.featureFlaggingID.uuidString.data(using: .utf8) else {
                        return nil
                    }
                    let hash = SHA256.hash(data: userIDData)
                    var bodyObj: [String: Any] = [
                        "userID": hash.compactMap { String(format: "%02x", $0) }.joined()
                    ]
                    for (key, value) in flags {
                        bodyObj[key.rawValue] = value.value
                    }
                    let data = try JSONSerialization.data(withJSONObject: bodyObj, options: [])
                    
                    var request = URLRequest(url: url)
                    request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                    request.httpBody = data
                    request.httpMethod = "POST"
                    return request
                }.compactMap { $0 }
                .map({ (request) in
                    return URLSession.shared.dataTaskPublisher(for: request).mapError{ $0 as Error }
                })
            
            return Publishers.SwitchToLatest(upstream: requests).eraseToAnyPublisher()
        }
    }
    
    public var DEBUGGING_AND_VERIFICATION: VerificationFunctions { .init(self) }
    private func getDebuggingData() -> AnyPublisher<([FeatureFlag.Name: FeatureFlag], AdditionalUserData),Error> {
        return Publishers.CombineLatest(featureFlagsFuture, userDataFuture).eraseToAnyPublisher()
    }
}
