//
//  StorageManager.swift
//  Color Camera
//
//  Created by Ted on 3/8/20.
//  Copyright © 2020 Ted Kostylev. All rights reserved.
//

import Foundation
import os.log

private let defaultsTypes: [defaultsKeys: Any.Type] = [
    .activeFilter: String.self,
    .isOnFrontal:  Bool.self
]

public enum defaultsKeys: String {
    case activeFilter = "activeFilter"
    case isOnFrontal  = "isOnFrontal"
}

public func setUserDefault(value: Any, forKey key: defaultsKeys) throws {
    assert(type(of: value) == defaultsTypes[key])
    let defaults = UserDefaults.standard
    defaults.set(value, forKey: key.rawValue)
}

public var isOnFrontal: Bool {
    get {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: defaultsKeys.isOnFrontal.rawValue)
    }
    set {
        do {
            try setUserDefault(value: newValue, forKey: .isOnFrontal)
        } catch {
            os_log(.error, "Tried saving %s to isOnFrontal", newValue)
        }
    }
}

public func getStoredFilter() -> String? {
    let defaults = UserDefaults.standard
    return defaults.string(forKey: defaultsKeys.activeFilter.rawValue)
}
