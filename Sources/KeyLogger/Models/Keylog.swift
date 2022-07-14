//
//  Keylog.swift
//
//  Created by Andrea Piscitello on 17/10/16.
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
import SwiftUI

/// Data structure containing all the information linked with a key pression
public class Keylog : Codable {
    private enum CodingKeys : String, CodingKey {
        case uptime, _timestamp = "timestamp", value, duration, distanceFromPrevious, distanceFromCenter, force, radius
    }
    
    /// System clock time
    public let uptime: TimeInterval
    
    /// Time instant of the touch up event (when the finger is raised).
    public var timestamp: Date {
        get { Date(timeIntervalSince1970: _timestamp) }
        set { _timestamp = newValue.timeIntervalSince1970 }
    }
    internal var _timestamp: TimeInterval
    
    /// Description of the key pressed. It can be either a KeyType or a particular key that is recorded.
    public var keyType: KeyType { .init(rawValue: value) ?? .other }
    private let value: String
    
    /// Residence Time. Time interval the finger is kept on the key.
    public var duration: TimeInterval?
    
    /// Distance (in universal size called gridpoint which is independent of screen resolutions) of touch from the previous KeyLog touch position.
    public var distanceFromPrevious: Double?
    
    /// Distance (in universal size called gridpoint which is independent of screen resolutions) of touch from key center.
    public var distanceFromCenter: Double?
    
    /// Force of touch.
    public var force: Force?
    
    /// Radius of touch.
    public var radius: Radius?
    
    /** 
        Coordinates of the touch in the keyboard.
        It is used just to compute distances between two consecutive touch events.
        ** It should never be serialized and sent to not compromise text privacy **
    */
    public var coordinates: CGPoint? = nil
    
    public convenience init(key: String, timestamp: Date = Date()) {
        self.init(value: .init(key: key), timestamp: timestamp)
    }
    
    public init(value: KeyType, timestamp: Date = Date()) {
        let now = Date()
        let nowUptime = ProcessInfo.processInfo.systemUptime
        self.uptime = nowUptime - now.timeIntervalSince(timestamp)
        self._timestamp = timestamp.timeIntervalSince1970
        self.value = value.rawValue
    }
    
    /// Compute distance between this keylog touch coordinates and the previous one passed as parameter.
    /// - parameter from: Touch position of the previous keylog.
    public func setDistance(from point: CGPoint?) {
        guard let coordinates = coordinates, let point = point else {
            return
        }
        self.distanceFromPrevious = Utils.distance(coordinates, b: point)
    }
    
    /// General types of key which is pressed
    public enum KeyType : String {
        /// It represents a character or number.
        case alphanum
        
        /// It can be a point, a comma or another special character.
        case punctuation
        
        /// Emoji
        case emoji
        
        /// Backspace
        case backspace
        
        /// Suggestion
        case suggestion
        
        /// Autocorrection
        case autocorrection
        
        /// Special-case characters
        case at = "@", hashtag = "#"
        
        /// Default base case; it should never occur.
        case other
        
        public init(key: String) {
            guard let char = key.unicodeScalars.first else {
                self = .other
                return
            }
            
            if CharacterSet.alphanumerics.contains(char) {
                self = .alphanum
            }
            else if key == "@" {
                self = .at
            }
            else if key == "#" {
                self = .hashtag
            }
            else if CharacterSet.symbols.contains(char) {
                self = .punctuation
            }
            else {
                self = .other
            }
        }
    }
    
    /// Touch force sensed by 3DTouch sensor.
    public struct Force : Codable {
        public let value: Double
        public let max: Double
        
        /// - Parameters:
        ///   - value: Actual force sensed as conventional value.
        ///   - max: Maximum possible force that can be sensed by the sensor.
        public init(value: Double, max: Double) {
            self.value = value
            self.max = max
        }
    }
    
    /// Radius of the touch surface.
    public struct Radius : Codable {
        public private(set) var value: Double
        public private(set) var tolerance: Double

        /// - Parameters:
        ///   - value: Actual radius of the touch surface (in universal size called gridpoint which is independent of screen resolutions).
        ///   - tolerance: Srandard deviation.
        public init(value: Double, tolerance: Double) {
            self.value = value
            self.tolerance = tolerance
        }
    }
}
