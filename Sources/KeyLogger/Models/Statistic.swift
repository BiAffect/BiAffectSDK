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
    public let sentiment: Int? // Sentiment value, currently it could be either 1, 0, or -1
    public let sentimentSum: Int // Sum of sentiment values for the day
    public let sentimentCount: Int // Count of Statistic objects with sentiment for the day
    
    
    public init(date: Date, keys: Int = 0, autocorrections: Int = 0, suggestions: Int = 0, backspaces: Int = 0, spaces: Int = 0, duration: TimeInterval = 0, sentiment: Int? = nil,
                sentimentSum: Int = 0, sentimentCount: Int = 0) {
        self.date = date
        self.keys = keys
        self.autocorrections = autocorrections
        self.suggestions = suggestions
        self.backspaces = backspaces
        self.spaces = spaces
        self.duration = duration
        self.sentiment = sentiment
        self.sentimentSum = sentimentSum
        self.sentimentCount = sentimentCount
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
        
        
        self.sentiment = session.sentiment?.sentimentScore()
        if self.sentiment != nil {
            self.sentimentSum = self.sentiment!
            self.sentimentCount = 1
        }
        else{
            self.sentimentSum = 0
            self.sentimentCount = 0
        }
        debugPrint(">>> Statistic > init() > Date: \(self.date) Sentiment: \(self.sentiment), Sentiment Sum: \(self.sentimentSum), Sentiment Count: \(self.sentimentCount)")
    }
}

extension Statistic {

    public static var zero: Statistic {
        .init(date: .distantFuture)
    }

    public static func + (lhs: Statistic, rhs: Statistic) -> Statistic {
        var sentimentSum = lhs.sentimentSum
        var sentimentCount = lhs.sentimentCount
        if rhs.sentiment != nil {
            sentimentSum += rhs.sentiment!
            sentimentCount += 1
        }
        return Statistic(
            date: lhs.date < rhs.date ? lhs.date : rhs.date,
            keys: lhs.keys + rhs.keys,
            autocorrections: lhs.autocorrections + rhs.autocorrections,
            suggestions: lhs.suggestions + rhs.suggestions,
            backspaces: lhs.backspaces + rhs.backspaces,
            spaces: lhs.spaces + rhs.spaces,
            duration: lhs.duration + rhs.duration,
            sentimentSum: sentimentSum,
            sentimentCount: sentimentCount
        )
    }
}

extension Sequence where Element == Statistic {
    
    public func aggregateHourly(on date: Date = .init()) -> [Int: Statistic] {
        let hourlyStatistics = self.reduce(into: [Int: Statistic]()) { hourlyStats, stat in
            guard Calendar.current.isDate(stat.date, inSameDayAs: date) else { return }
            let hour = Calendar.current.component(.hour, from: stat.date)
            hourlyStats[hour] = (hourlyStats[hour] ?? .zero) + stat
        }
        debugPrint(">>> Statistic > aggregateHourly(): \(hourlyStatistics)")
        return hourlyStatistics
    }

    public func aggregateDaily() -> [Date: Statistic] {
        let dailyStatistics = self.reduce(into: [Date: Statistic]()) { dailyStats, stat in
            let startOfDay = Calendar.current.startOfDay(for: stat.date)
            // Ensure that Statistic can be initialized with just a date and can be added to another Statistic
            dailyStats[startOfDay] = (dailyStats[startOfDay] ?? .init(date: startOfDay)) + stat
        }
        debugPrint(">>> Statistic > aggregateDaily(): \(dailyStatistics)")
        return dailyStatistics
    }

}
