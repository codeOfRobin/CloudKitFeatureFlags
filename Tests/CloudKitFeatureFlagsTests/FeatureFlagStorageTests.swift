//
//  FeatureFlagStorageTests.swift
//  
//
//  Created by Robin Malhotra on 04/04/2021.
//

import XCTest
import CloudKit
@testable import CloudKitFeatureFlags

final class UserDefaultFeatureFlagStorageTests: XCTestCase {
    
    let featureFlagStorage = UserDefaultsFeatureFlagStorage(userDefaults: .standard)
    
    func testGetterAndSetterInStorage() {
        featureFlagStorage.set(name: "test", value: true)
        XCTAssertEqual(featureFlagStorage.get(name: "test"), true)
    }
    
    static var allTests = [
        ("testGetterAndSetterInStorage", testGetterAndSetterInStorage)
    ]
}
