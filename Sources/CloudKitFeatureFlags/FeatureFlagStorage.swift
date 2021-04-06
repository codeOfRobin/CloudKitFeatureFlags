//
//  FeatureFlagStorage.swift
//  
//
//  Created by Robin Malhotra on 04/04/2021.
//

import Foundation

public protocol FeatureFlagStorage: AnyObject {
    func set(name: String, value: Bool)
    func get(name: String) -> Bool?
}

public class UserDefaultsFeatureFlagStorage: FeatureFlagStorage {
    
    let userDefaults: UserDefaults
    
    
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    public func set(name: String, value: Bool) {
        userDefaults.setValue(value, forKey: name)
    }
    
    public func get(name: String) -> Bool? {
        return userDefaults.object(forKey: name) as? Bool
    }
    
}
