import XCTest
import JsonModel
@testable import KeyLogger

final class ModelTests: XCTestCase {
    
    let encoder = SerializationFactory.defaultFactory.createJSONEncoder()
    let decoder = SerializationFactory.defaultFactory.createJSONDecoder()
    
    func testKeylogCodable_NilValues() throws {
        let keylog = Keylog(value: .alphabet)
        let encodedData = try encoder.encode(keylog)
        let decodedObj = try decoder.decode(Keylog.self, from: encodedData)
        
        XCTAssertEqual(keylog.keyType, decodedObj.keyType)
        XCTAssertEqual(keylog._timestamp, decodedObj._timestamp, accuracy: 0.0001)
    }
    
    func testKeylogCodable_NonNilValues() throws {
        let keylog = Keylog(value: .alphabet)
        keylog.duration = 0.23
        keylog.coordinates = .init(x: 5, y: 7)
        keylog.distanceFromCenter = 0.5
        keylog.distanceFromPrevious = 15.0
        keylog.force = .init(value: 0.45, max: 5.0)
        keylog.radius = .init(value: 4.5, tolerance: 0.01)
        
        let encodedData = try encoder.encode(keylog)
        let decodedObj = try decoder.decode(Keylog.self, from: encodedData)
        
        XCTAssertEqual(keylog.keyType, decodedObj.keyType)
        XCTAssertEqual(keylog._timestamp, decodedObj._timestamp, accuracy: 0.0001)
        XCTAssertEqual(keylog.duration!, decodedObj.duration ?? 0, accuracy: 0.0001)
        XCTAssertEqual(keylog.distanceFromCenter!, decodedObj.distanceFromCenter ?? 0, accuracy: 0.0001)
        XCTAssertEqual(keylog.distanceFromPrevious!, decodedObj.distanceFromPrevious ?? 0, accuracy: 0.0001)
        XCTAssertEqual(keylog.force!.value, decodedObj.force?.value ?? 0, accuracy: 0.0001)
        XCTAssertEqual(keylog.force!.max, decodedObj.force?.max ?? 0, accuracy: 0.0001)
        XCTAssertEqual(keylog.radius!.value, decodedObj.radius?.value ?? 0, accuracy: 0.0001)
        XCTAssertEqual(keylog.radius!.tolerance, decodedObj.radius?.tolerance ?? 0, accuracy: 0.0001)
        XCTAssertNil(decodedObj.coordinates)
        
        guard let dictionary = try JSONSerialization.jsonObject(with: encodedData) as? [String : Any]
        else {
            XCTFail("Failed to decode a dictionary")
            return
        }
        
        XCTAssertEqual("alphabet", dictionary["value"] as? String)
        XCTAssertEqual(keylog._timestamp, dictionary["timestamp"] as? Double ?? 0, accuracy: 0.0001)
        XCTAssertEqual(keylog.duration!, dictionary["duration"] as? Double ?? 0, accuracy: 0.0001)
        XCTAssertEqual(keylog.distanceFromCenter!, dictionary["distanceFromCenter"] as? Double ?? 0, accuracy: 0.0001)
        XCTAssertEqual(keylog.distanceFromPrevious!, dictionary["distanceFromPrevious"] as? Double ?? 0, accuracy: 0.0001)
        XCTAssertNil(dictionary["coordinates"])
        XCTAssertNotNil(dictionary["force"])
        XCTAssertNotNil(dictionary["radius"])
    }
    
    func testSession() throws {
        
        let firstKeyTimestamp = Calendar.current.startOfDay(for: Date()).addingTimeInterval(10*60*60)
        
        let key1 = Keylog(key: "Y", timestamp: firstKeyTimestamp)
        key1.duration = 0.12
        key1.coordinates = .init(x: 150, y: 10)
        
        let key2 = Keylog(key: "e", timestamp: firstKeyTimestamp.addingTimeInterval(0.4))
        key2.duration = 0.08
        key2.coordinates = .init(x: 100, y: 10)
        
        let key3 = Keylog(key: "s", timestamp: firstKeyTimestamp.addingTimeInterval(0.9))
        key3.duration = 0.1
        key3.coordinates = .init(x: 90, y: 40)
        
        let key4 = Keylog(value: .punctuation, timestamp: firstKeyTimestamp.addingTimeInterval(1.5))
        key4.duration = 0.1
        key4.coordinates = .init(x: 0, y: 0)
        
        let session = Session(key1)
        session.addKeylog(key2)
        session.addKeylog(key3)
        session.addKeylog(key4)
        session.endSession()
        
        XCTAssertEqual(1.6, session.duration)
        XCTAssertNil(key1.distanceFromPrevious)
        XCTAssertEqual(50.000, key2.distanceFromPrevious ?? 0, accuracy: 0.001)
        XCTAssertEqual(31.623, key3.distanceFromPrevious ?? 0, accuracy: 0.001)
        XCTAssertEqual(98.489, key4.distanceFromPrevious ?? 0, accuracy: 0.001)
        
        XCTAssertEqual(session.timestamp, firstKeyTimestamp)

        let encodedData = try encoder.encode(session)
        let decodedObj = try decoder.decode(Session.self, from: encodedData)
        XCTAssertEqual(session._timestamp, decodedObj._timestamp, accuracy: 0.0001)
        
        guard let dictionary = try JSONSerialization.jsonObject(with: encodedData) as? [String : Any]
        else {
            XCTFail("Failed to decode a dictionary")
            return
        }
        
        XCTAssertEqual(firstKeyTimestamp.timeIntervalSince1970, dictionary["timestamp"] as? Double ?? 0, accuracy: 0.0001)
        XCTAssertNotNil(dictionary["duration"])
        XCTAssertNotNil(dictionary["keylogs"])
    }
    
    func testStatisticFromSession() {
        let firstKeyTimestamp = Calendar.current.startOfDay(for: Date()).addingTimeInterval(10*60*60)
        let session = Session(timestamp: firstKeyTimestamp,
                              duration: 3.67,
                              keylogs: [
                                .init(value: .alphabet),
                                .init(value: .alphabet),
                                .init(value: .alphabet),
                                .init(value: .backspace),
                                .init(value: .alphabet),
                                .init(value: .suggestion),
                                .init(value: .punctuation),
                                .init(value: .emoji),
                                .init(value: .at),
                                .init(value: .hashtag),
                                .init(value: .alphabet),
                                .init(value: .alphabet),
                                .init(value: .alphabet),
                                .init(value: .autocorrection),
                              ])
        let statistic = Statistic(session: session)
        
        XCTAssertEqual(firstKeyTimestamp, statistic.date)
        XCTAssertEqual(3.67, statistic.duration)
        XCTAssertEqual(9, statistic.keys)
        XCTAssertEqual(1, statistic.backspaces)
        XCTAssertEqual(1, statistic.autocorrections)
        XCTAssertEqual(1, statistic.suggestions)
    }
    
    func testStatistic_AggregateHourly() {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let yesterday = Calendar.current.startOfDay(for: startOfDay.addingTimeInterval(-1.5*60*60))
        let tenAM = startOfDay.addingTimeInterval(10*60*60)
        let twoPM = startOfDay.addingTimeInterval(14*60*60)
        let statistics: [Statistic] = [
            .init(date: startOfDay.addingTimeInterval(-1.5*60*60), keys: 5, autocorrections: 0, suggestions: 1, backspaces: 2, duration: 0.24),
            .init(date: tenAM, keys: 5, autocorrections: 0, suggestions: 1, backspaces: 2, duration: 0.24),
            .init(date: tenAM.addingTimeInterval(10*60), keys: 6, autocorrections: 0, suggestions: 1, backspaces: 2, duration: 0.24),
            .init(date: tenAM.addingTimeInterval(35*60), keys: 100, autocorrections: 1, suggestions: 3, backspaces: 1, duration: 1.3),
            .init(date: twoPM, keys: 16, autocorrections: 0, suggestions: 0, backspaces: 0, duration: 1.24),
            .init(date: twoPM.addingTimeInterval(5*60), keys: 6, autocorrections: 0, suggestions: 1, backspaces: 2, duration: 0.24),
            .init(date: twoPM.addingTimeInterval(45*60), keys: 100, autocorrections: 1, suggestions: 3, backspaces: 1, duration: 1.3),
        ]
        
        let hourly = statistics.aggregateHourly(on: now)

        XCTAssertNil(hourly[22])    // Should not include yesterday
        XCTAssertNotNil(hourly[10])
        XCTAssertNotNil(hourly[14])
        
        if let stat = hourly[10] {
            XCTAssertEqual(tenAM, stat.date)
            XCTAssertEqual(111, stat.keys)
            XCTAssertEqual(5, stat.backspaces)
            XCTAssertEqual(5, stat.suggestions)
            XCTAssertEqual(1, stat.autocorrections)
        }
        
        let daily = statistics.aggregateDaily()
        XCTAssertNotNil(daily[yesterday])
        XCTAssertNotNil(daily[startOfDay])
        
        if let stat = daily[startOfDay] {
            XCTAssertEqual(startOfDay, stat.date)
            XCTAssertEqual(233, stat.keys)
            XCTAssertEqual(8, stat.backspaces)
            XCTAssertEqual(9, stat.suggestions)
            XCTAssertEqual(2, stat.autocorrections)
        }
    }
}
