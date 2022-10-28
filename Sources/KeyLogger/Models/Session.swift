//
//  Session.swift
//
//  Created by Andrea Piscitello on 31/10/16.
//
//  Copyright © 2016, 2022 BiAffect. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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

