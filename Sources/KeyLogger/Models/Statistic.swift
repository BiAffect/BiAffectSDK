//
//  Statistic.swift
//
//  Created by Andrea Piscitello on 09/02/17.
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

/// The consolidated serializable result of a session state object.
public struct Statistic : Codable, Hashable {
    public let date : Date
    public let keys : Int
    public let autocorrections : Int
    public let suggestions : Int
    public let backspaces : Int
    public let duration: TimeInterval
    
    public init(date: Date, keys: Int = 0, autocorrections: Int = 0, suggestions: Int = 0, backspaces: Int = 0, duration: TimeInterval = 0) {
        self.date = date
        self.keys = keys
        self.autocorrections = autocorrections
        self.suggestions = suggestions
        self.backspaces = backspaces
        self.duration = duration
    }
    
    public init(session: Session) {
        self.date = session.timestamp
        self.duration = session.duration
        
        var keys = 0
        var autocorrections = 0
        var suggestions = 0
        var backspaces = 0
        
        // Count up all the keys of each subcategory
        session.keylogs.forEach {
            switch $0.keyType {
            case .alphanum, .punctuation, .emoji:
                keys += 1
            case .autocorrection:
                autocorrections += 1
            case .suggestion:
                suggestions += 1
            case .backspace:
                backspaces += 1
            default:
                break;
            }
        }
        
        self.keys = keys
        self.autocorrections = autocorrections
        self.suggestions = suggestions
        self.backspaces = backspaces
    }
}

extension Statistic {
    
    public static var zero: Statistic {
        .init(date: .distantFuture)
    }
    
    public static func + (lhs: Statistic, rhs: Statistic) -> Statistic {
        .init(date: lhs.date < rhs.date ? lhs.date : rhs.date,
              keys: lhs.keys + rhs.keys,
              autocorrections: lhs.autocorrections + rhs.autocorrections,
              suggestions: lhs.suggestions + rhs.suggestions,
              backspaces: lhs.backspaces + rhs.backspaces,
              duration: lhs.duration + rhs.duration)
    }
}

extension Sequence where Element == Statistic {
    
    public func aggregateHourly(on date: Date = .init()) -> [Int : Statistic] {
        self.reduce(into: [Int : Statistic]()) { hourlyStatistics, stat in
            guard Calendar.current.isDate(stat.date, inSameDayAs: date) else { return }
            let hour = Calendar.current.component(.hour, from: stat.date)
            hourlyStatistics[hour] = (hourlyStatistics[hour] ?? .zero) + stat
        }
    }
    
    public func aggregateDaily() -> [Date : Statistic] {
        self.reduce(into: [Date : Statistic]()) { dailyStatistics, stat in
            let startOfDay = Calendar.current.startOfDay(for: stat.date)
            dailyStatistics[startOfDay] = (dailyStatistics[startOfDay] ?? .init(date: startOfDay)) + stat
        }
    }
}
