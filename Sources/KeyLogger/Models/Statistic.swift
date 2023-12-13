//
//  Statistic.swift
//
//  Created by Andrea Piscitello on 09/02/17.
//

import Foundation

/// The consolidated serializable result of a session state object.
public struct Statistic : Codable, Hashable {
    public let date : Date
    public let keys : Int
    public let autocorrections : Int
    public let suggestions : Int
    public let backspaces : Int
    public let spaces : Int
    public let duration: TimeInterval

    public init(date: Date, keys: Int = 0, autocorrections: Int = 0, suggestions: Int = 0, backspaces: Int = 0, spaces: Int = 0, duration: TimeInterval = 0) {
        self.date = date
        self.keys = keys
        self.autocorrections = autocorrections
        self.suggestions = suggestions
        self.backspaces = backspaces
        self.spaces = spaces
        self.duration = duration
    }

    public init(session: Session) {
        self.date = session.timestamp
        self.duration = session.duration

        var keys = 0
        var spaces = 0
        var autocorrections = 0
        var suggestions = 0
        var backspaces = 0

        // Count up all the keys of each subcategory
        session.keylogs.forEach {
            switch $0.keyType {
            case .alphabet, .numeral, .punctuation, .symbol, .emoji:
                keys += 1
                print("keys") 
            case .space:
                spaces += 1
                print("space") 
            case .autocorrection:
                autocorrections += 1
                print("autocorrection") 
            case .suggestion:
                suggestions += 1
                print("suggestion") 
            case .backspace:
                backspaces += 1
                print("backspaces") 
            default:
                break;
            }
        }

        self.keys = keys
        self.autocorrections = autocorrections
        self.suggestions = suggestions
        self.backspaces = backspaces
        self.spaces = spaces
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
              spaces: lhs.spaces + rhs.spaces,
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
