//
//  Keylog.swift
//
//  Created by Andrea Piscitello on 17/10/16.
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
        /// It represents an alphabetical character
        case alphabet

        /// It represents a number
        case numeral

        /// It can be a period, a comma, or another punctuation mark
        case punctuation

        /// All other special characters such as currency symbols, mathematical operators, etc.
        case symbol

        /// Emoji
        case emoji

        /// Backspace
        case backspace

        /// Space
        case space

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
                if CharacterSet.letters.contains(char) {
                    self = .alphabet
                }
                else {
                    self = .numeral
                }
            }
            else if key == "@" {
                self = .at
            }
            else if key == "#" {
                self = .hashtag
            }
            else if key == " " {
                self = .space
            }
            else if CharacterSet.punctuationCharacters.contains(char) {
                self = .punctuation
            }
            else if CharacterSet.symbols.contains(char) {
                self = .symbol
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
