//
//  TrailmakingResultObject.swift
//

import Foundation
import JsonModel
import ResultModel

extension SerializableResultType {
    static let trailmaking: SerializableResultType = "trailmaking"
}

public final class TrailmakingResultObject : MultiplatformResultData, SerializableResultData {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case serializableType = "type", identifier, _jsonSchema = "$schema", startDateTime = "startDate", endDateTime = "endDate", points, numberOfErrors, responses = "taps", pauseInterval, runtime, timedOut
    }
    public private(set) var serializableType: SerializableResultType = .trailmaking
    
    public var jsonSchema: URL { _jsonSchema ?? jsonURL() }
    private var _jsonSchema: URL?

    public let identifier: String
    public var startDateTime: Date = Date()
    public var endDateTime: Date?
    public var points: [TrailmakingPoint]?
    public var numberOfErrors: Int?
    public var responses: [Response]?
    public var pauseInterval: TimeInterval?
    public var runtime: TimeInterval?
    public var timedOut: Bool?

    init(identifier: String) {
        self.identifier = identifier
        self._jsonSchema = jsonURL()
    }
    
    func jsonURL() -> URL {
        URL(string: "\(self.className).json", relativeTo: kBaseJsonSchemaURL)!
    }
    
    public func deepCopy() -> TrailmakingResultObject {
        let copy = TrailmakingResultObject(identifier: self.identifier)
        copy.startDateTime = self.startDateTime
        copy.endDateTime = self.endDateTime
        copy.numberOfErrors = self.numberOfErrors
        copy.responses = self.responses
        copy.points = self.points
        copy.pauseInterval = self.pauseInterval
        copy.runtime = self.runtime
        copy.timedOut = self.timedOut
        return copy
    }
    
    public struct Response : Codable, Hashable {
        private enum CodingKeys : String, OrderedEnumCodingKey {
            case timestamp, index, incorrect
        }
        public let timestamp: TimeInterval
        public let index: Int
        public let incorrect: Bool
    }
}

extension TrailmakingResultObject : FileArchivable {
    public func buildArchivableFileData(at stepPath: String?) throws -> (fileInfo: FileInfo, data: Data)? {
        let data = try self.jsonEncodedData()
        let fileInfo = FileInfo(filename: "trailmaking.json", timestamp: self.endDate, contentType: "application/json", identifier: self.identifier, stepPath: stepPath, jsonSchema: jsonSchema)
        return (fileInfo, data)
    }
}

extension TrailmakingResultObject : DocumentableRootObject {
    
    public convenience init() {
        self.init(identifier: SerializableResultType.trailmaking.rawValue)
    }

    public var documentDescription: String? {
        "The archived result of a single trailmaking test step."
    }
}

extension TrailmakingResultObject : DocumentableStruct {
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
        case .responses:
            return .init(propertyType: .referenceArray(TrailmakingResultObject.Response.documentableType()), propertyDescription:
                            "An array of all taps completed during the test.")
        case .pauseInterval:
            return .init(propertyType: .primitive(.number), propertyDescription:
                            "The total time in seconds that the test was paused.")
        case .runtime:
            return .init(propertyType: .primitive(.number), propertyDescription:
                            "The total time in seconds that the test was shown (minus the pause inteval).")
        case .numberOfErrors:
            return .init(propertyType: .primitive(.integer), propertyDescription:
                            "The number of errors generated during the test.")
        case .points:
            return .init(propertyType: .referenceArray(TrailmakingPoint.documentableType()), propertyDescription:
                            "An array of all the trail points displayed for this run of the test.")
        case .timedOut:
            return .init(propertyType: .primitive(.number), propertyDescription:
                            "If `true` then the test timed out.")
        }
    }
    
    public static func examples() -> [TrailmakingResultObject] {
        [.init()]
    }
}

extension TrailmakingResultObject.Response : DocumentableStruct {
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
                            "A relative timestamp indicating the time of the tap event in seconds.")
        case .incorrect:
            return .init(propertyType: .primitive(.boolean), propertyDescription:
                            "This is `true` if the button was tapped in error.")
        case .index:
            return .init(propertyType: .primitive(.integer), propertyDescription:
                            "The index of the button tapped.")
        }
    }
    
    public static func examples() -> [TrailmakingResultObject.Response] {
        [.init(timestamp: 0, index: 0, incorrect: false)]
    }
}

