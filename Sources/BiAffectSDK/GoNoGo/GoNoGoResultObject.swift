//
//  GoNoGoResultObject.swift
//

import Foundation
import JsonModel
import ResultModel
import MobilePassiveData

extension SerializableResultType {
    static let gonogo: SerializableResultType = "gonogo"
}

public final class GoNoGoResultObject : MultiplatformResultData, SerializableResultData {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case serializableType = "type", identifier, _jsonSchema = "$schema", startDateTime = "startDate", endDateTime = "endDate", startUptime, responses = "results", motionError
    }
    public private(set) var serializableType: SerializableResultType = .gonogo
    
    public var jsonSchema: URL { _jsonSchema ?? jsonURL() }
    private var _jsonSchema: URL?

    public let identifier: String
    public var startDateTime: Date
    public var endDateTime: Date?
    public var startUptime: SystemUptime?
    public var responses: [Response]
    public var motionError: ErrorResultObject?

    public init(identifier: String) {
        self.identifier = identifier
        self.startDateTime = Date()
        self.endDateTime = nil
        self.responses = []
        self._jsonSchema = jsonURL()
    }
    
    func jsonURL() -> URL {
        URL(string: "\(self.className).json", relativeTo: kBaseJsonSchemaURL)!
    }
    
    public func deepCopy() -> GoNoGoResultObject {
        let copy = GoNoGoResultObject(identifier: self.identifier)
        copy.startDateTime = self.startDateTime
        copy.endDateTime = self.endDateTime
        copy.startUptime = self.startUptime
        copy.responses = self.responses
        copy.motionError = self.motionError
        return copy
    }
    
    public struct Response : Codable, Hashable {
        private enum CodingKeys : String, OrderedEnumCodingKey {
            case stepPath, timestamp, resetTimestamp, timeToThreshold, stimulusDelay, go, incorrect, samples
        }
        public let stepPath: String?
        public let timestamp: SystemUptime
        public let resetTimestamp: SystemUptime
        public let timeToThreshold: SecondDuration
        public let stimulusDelay: SecondDuration
        public let go: Bool
        public let incorrect: Bool
        public let samples: [Sample]?
    }
    
    public struct Sample : Codable, Hashable {
        private enum CodingKeys : String, CodingKey, CaseIterable {
            case timestamp, vectorMagnitude
        }
        public let timestamp: TimeInterval
        public let vectorMagnitude: Double
    }
}

extension GoNoGoResultObject : FileArchivable {
    public func buildArchivableFileData(at stepPath: String?) throws -> (fileInfo: FileInfo, data: Data)? {
        let data = try self.jsonEncodedData()
        let fileInfo = FileInfo(filename: "gonogo.json", timestamp: self.endDate, contentType: "application/json", identifier: self.identifier, stepPath: stepPath, jsonSchema: jsonSchema)
        return (fileInfo, data)
    }
}

extension GoNoGoResultObject : DocumentableRootObject {
    
    public convenience init() {
        self.init(identifier: SerializableResultType.gonogo.rawValue)
    }

    public var documentDescription: String? {
        "The archived result of a single go-no-go test step."
    }
}

extension GoNoGoResultObject : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        (codingKey as? CodingKeys).map {
            switch $0 {
            case .serializableType, .identifier, .startDateTime:
                return true
            default:
                return false
            }
        } ?? false
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .serializableType:
            return .init(constValue: SerializableResultType.gonogo)
        case .identifier:
            return .init(propertyType: .primitive(.string))
        case ._jsonSchema:
            return .init(propertyType: .primitive(.string))
        case .startDateTime, .endDateTime:
            return .init(propertyType: .format(.dateTime))
        case .startUptime:
            return .init(propertyType: .primitive(.number), propertyDescription:
                            "The system clock uptime when the recorder was started.")
        case .responses:
            return .init(propertyType: .referenceArray(GoNoGoResultObject.Response.documentableType()), propertyDescription:
                            "The list of motion samples for this run of the test.")
        case .motionError:
            return .init(propertyType: .reference(ErrorResultObject.documentableType()), propertyDescription:
                            "The error returned when failed to use the motion sensors.")
        }
    }
    
    public static func examples() -> [GoNoGoResultObject] {
        [.init()]
    }
}

extension GoNoGoResultObject.Response : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        (codingKey as? CodingKeys).map { $0 != .samples } ?? true
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .stepPath:
            return .init(propertyType: .primitive(.string), propertyDescription:
                            "A marker that matches the 'stepPath' in the 'motion.json' file with raw motion sensor data.")
        case .timestamp:
            return .init(propertyType: .primitive(.number), propertyDescription:
                            """
                            The timestamp is the system uptime for when the stimulus was displayed.
                            A false start where the participant shakes the device while waiting for
                            the stimulus to be displayed is indicated by a value of zero.
                            """)
        case .resetTimestamp:
            return .init(propertyType: .primitive(.number), propertyDescription:
                            """
                            The reset timestamp is the system uptime for when go-no-go attempt is
                            reset (ie. started).
                            """)
        case .timeToThreshold:
            return .init(propertyType: .primitive(.number), propertyDescription:
                            """
                            Time from when the stimulus occurred to the threshold being reached.
                            For a timeout or false start, this value will be zero.
                            """)
        case .stimulusDelay:
            return .init(propertyType: .primitive(.number), propertyDescription:
                            "The delay (in seconds) from reset until the stimulus is shown.")
        case .go:
            return .init(propertyType: .primitive(.boolean), propertyDescription:
                            "YES if a go test and NO if a no go test.")
        case .incorrect:
            return .init(propertyType: .primitive(.boolean), propertyDescription:
                            "Set to YES if the incorrect response is given --i.e shaken for no go test or not shaken for a go test.")
        case .samples:
            return .init(propertyType: .referenceArray(GoNoGoResultObject.Sample.documentableType()), propertyDescription:
                            "A collection of samples.")
        }
    }
    
    public static func examples() -> [GoNoGoResultObject.Response] {
        [.init(stepPath: "0", timestamp: 0, resetTimestamp: 120492.081, timeToThreshold: 0.1, stimulusDelay: 7.3, go: true, incorrect: true, samples: nil)]
    }
}

extension GoNoGoResultObject.Sample : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        true
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .timestamp:
            return .init(propertyType: .primitive(.number), propertyDescription:
                            """
                            The timestamp is relative to the time the stimulus was displayed, if there was a stimulus.
                            If the participant triggered a false start, then the timestamps are equal to the system uptime.
                            """)
        case .vectorMagnitude:
            return .init(propertyType: .primitive(.number), propertyDescription:
                            "Magnitude of the acceleration event.")
        }
    }
    
    public static func examples() -> [GoNoGoResultObject.Sample] {
        [.init(timestamp: 0, vectorMagnitude: 0)]
    }
}

