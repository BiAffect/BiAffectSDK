//
//  GoNoGoStepObject.swift
//

import Foundation
import JsonModel
import ResultModel
import AssessmentModel

extension SerializableNodeType {
    static let gonogo: SerializableNodeType = "gonogo"
}

struct GoNoGoStepObject : SerializableNode, Step, Codable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case serializableType = "type", identifier
        
        case detail
        
        // Parameters
        case _maximumStimulusInterval = "maximumStimulusInterval",
             _minimumStimulusInterval = "minimumStimulusInterval",
             _thresholdAcceleration = "thresholdAcceleration",
             _numberOfAttempts = "numberOfAttempts",
             _timeout = "timeout",
             _maxTotalAttempts = "maxTotalAttempts"
    }
    
    private(set) var serializableType: SerializableNodeType = .gonogo
    let identifier: String
    
    /// Localized instruction string included in JSON file.
    let detail: String
    
    /// The maximum interval before the stimulus is delivered.
    var maximumStimulusInterval: TimeInterval { _maximumStimulusInterval ?? 10.0 }
    private(set) var _maximumStimulusInterval: TimeInterval?
    
    /// The minimum interval before the stimulus is delivered.
    var minimumStimulusInterval: TimeInterval { _minimumStimulusInterval ?? 4.0 }
    private(set) var _minimumStimulusInterval: TimeInterval?
    
    /// The acceleration required to end a reaction time test.
    var thresholdAcceleration: Double { _thresholdAcceleration ?? 0.5 }
    private(set) var _thresholdAcceleration: Double?
    
    /// The number of successful attempts required before the task is complete. The active step result will contain
    /// this many child results if the task is completed.
    var numberOfAttempts: Int { _numberOfAttempts ?? 9 }
    private(set) var _numberOfAttempts: Int?
    
    /// The max number of attempts to try before quitting.
    var maxTotalAttempts: Int { _maxTotalAttempts ?? 18 }
    private(set) var _maxTotalAttempts: Int?
    
    /// The interval permitted after the stimulus until the test fails, if the threshold is not reached.
    var timeout: TimeInterval { _timeout ?? 3.0 }
    private(set) var _timeout: TimeInterval?
    
    init() {
        self.identifier = SerializableNodeType.gonogo.rawValue
        self.detail = "Quickly shake the device when the blue dot appears. Do not shake for a green dot."
    }
    
    func instantiateResult() -> ResultData {
        GoNoGoResultObject(identifier: self.identifier)
    }
    
    // Step implementations - ignored
    
    var comment: String? { nil }
    
    func button(_ buttonType: ButtonType, node: Node) -> ButtonActionInfo? {
        nil
    }
    
    func shouldHideButton(_ buttonType: ButtonType, node: Node) -> Bool? {
        nil
    }
    
    func spokenInstruction(at timeInterval: TimeInterval) -> String? {
        nil
    }
}
