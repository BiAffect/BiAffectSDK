//
//  File.swift
//  
//
//  Created by Andrew Paparella on 1/29/24.
//

import Foundation

public class Sentiment {
    public enum Category {
        case positive, neutral, negative
    }
    
    let category: Category?
    // var confidenceScore: Double? (TODO: idea add confidence score)
    
    public init(category: Category?) {
        self.category = category
    }
    
    public func sentimentScore() -> Int? {
        switch category {
        case .positive:
            return 1
        case .neutral:
            return 0
        case .negative:
            return -1
        case .none:
            return nil
        }
    }
}
