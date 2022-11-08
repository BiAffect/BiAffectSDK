//
//  TrailmakingStepObject.swift
//

import Foundation
import JsonModel
import ResultModel
import AssessmentModel

extension SerializableNodeType {
    static let trailmaking: SerializableNodeType = "trailmaking"
}

struct TrailmakingStepObject : SerializableNode, Step, Codable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case serializableType = "type", identifier
    }
    
    private(set) var serializableType: SerializableNodeType = .trailmaking
    let identifier: String
    
    init() {
        self.identifier = SerializableNodeType.gonogo.rawValue
    }
    
    func instantiateResult() -> ResultData {
        TrailmakingResultObject(identifier: self.identifier)
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

