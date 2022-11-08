//
//  Task+Utils.swift
//

import Foundation

extension Task where Success == Never, Failure == Never {
    static func wait(seconds: TimeInterval) async -> Bool {
        let duration = UInt64(seconds * 1_000_000_000)
        do {
            try await Task.sleep(nanoseconds: duration)
            return true
        }
        catch {
            return false
        }
    }
}
