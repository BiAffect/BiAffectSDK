//
//  Session.swift
//
//  Created by Andrea Piscitello on 31/10/16.
//

import Foundation
import SwiftUI
import JsonModel
import ResultModel

let kBaseJsonSchemaURL = URL(string: "https://biaffect.github.io/biaffectsdk/json/schemas/v1/")!

/// A serializable state object used to track keyboard sesson state.
public class Session : Codable {
    private enum CodingKeys : String, CodingKey {
        case uptime, _timestamp = "timestamp", jsonSchema = "$schema", duration, keylogs, associatedFiles
    }
    
    public static let AssessmentIdentifier = "KeyboardSession"
    
    public private(set) var jsonSchema: URL = URL(string: "KeyboardSession.json", relativeTo: kBaseJsonSchemaURL)!
    
    /// System clock time
    public let uptime: TimeInterval
    
    public var timestamp: Date {
        Date(timeIntervalSince1970: _timestamp)
    }
    internal let _timestamp: TimeInterval
    public private(set) var duration: TimeInterval
    public private(set) var keylogs: [Keylog]
    public var associatedFiles: [FileResultObject]?
    
    public convenience init(_ keylog: Keylog) {
        self.init(uptime: keylog.uptime, timeInterval: keylog._timestamp, duration: 0.0, keylogs: [keylog])
    }
    
    convenience init(timestamp: Date, duration: TimeInterval, keylogs: [Keylog]) {
        let now = Date()
        let nowUptime = ProcessInfo.processInfo.systemUptime
        self.init(uptime: nowUptime - now.timeIntervalSince(timestamp), timeInterval: timestamp.timeIntervalSince1970, duration: duration, keylogs: keylogs)
    }
    
    private init(uptime: TimeInterval, timeInterval: TimeInterval, duration: TimeInterval, keylogs: [Keylog]) {
        self.uptime = uptime
        self._timestamp = timeInterval
        self.duration = duration
        self.keylogs = keylogs
    }
    
    /// Add keylog to list
    public func addKeylog(_ keylog: Keylog) {
        keylog.setDistance(from: keylogs.last?.coordinates)
        keylogs.append(keylog)
    }

    /// Finalize session filling duration field.
    public func endSession() {
        guard let start = keylogs.first, let end = keylogs.last else { return }
        duration = end._timestamp - start._timestamp + (end.duration ?? 0)
    }
}

