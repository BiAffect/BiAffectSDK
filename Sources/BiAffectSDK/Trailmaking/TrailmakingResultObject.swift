//
//  TrailmakingResultObject.swift
//
//  Copyright © 2022 BiAffect. All rights reserved.
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
import JsonModel

extension SerializableResultType {
    static let trailmaking: SerializableResultType = "trailmaking"
}

public final class TrailmakingResultObject : MultiplatformResultData, SerializableResultData {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case serializableType = "type", identifier, startDateTime = "startDate", endDateTime = "endDate", points, numberOfErrors, responses = "taps", pauseInterval, runtime
    }
    public private(set) var serializableType: SerializableResultType = .trailmaking

    public let identifier: String
    public var startDateTime: Date = Date()
    public var endDateTime: Date?
    public var points: [TrailmakingPoint]?
    public var numberOfErrors: Int?
    public var responses: [Response]?
    public var pauseInterval: TimeInterval?
    public var runtime: TimeInterval?

    init(identifier: String) {
        self.identifier = identifier
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

extension TrailmakingResultObject {
    convenience init() {
        self.init(identifier: SerializableResultType.trailmaking.rawValue)
    }
}

extension TrailmakingResultObject : FileArchivable {
    public func buildArchivableFileData(at stepPath: String?) throws -> (fileInfo: FileInfo, data: Data)? {
        let data = try self.jsonEncodedData()
        // TODO: syoung 06/14/2022 Build JSON schema and include in this repo
        let fileInfo = FileInfo(filename: "trailmaking.json", timestamp: self.endDate, contentType: "application/json", identifier: self.identifier, stepPath: stepPath, jsonSchema: nil)
        return (fileInfo, data)
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
                            "The list of motion samples for this run of the test.")
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

