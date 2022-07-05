//
//  ShakeMotionSensor.swift
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

import SwiftUI
import Combine
import MobilePassiveData
import MotionSensor
import JsonModel

#if canImport(CoreMotion)
import CoreMotion
#endif

fileprivate let motionRecorderConfig = MotionRecorderConfigurationObject(identifier: "motion",
                                                             recorderTypes: [.accelerometer, .gyro, .userAcceleration],
                                                             frequency: 100)

fileprivate func createOutputDirectory() -> URL {
    URL(fileURLWithPath: UUID().uuidString, isDirectory: true, relativeTo: FileManager.default.temporaryDirectory)
}

final class ShakeMotionSensor : MotionRecorder {

    var dotType: DisplayState = .starting {
        didSet {
            self.moveTo(stepPath: "attempt/\(resetCount)/showing/\(dotType)")
        }
    }
    
    var thresholdAcceleration: Double = 0.5
    var resetUptime: ClockUptime = SystemClock.uptime()
    var stimulusUptime: ClockUptime?
    
    private var resetCount: Int = 0
    private var thresholdUptime: SystemUptime?  // SystemTime
    private var samplesSinceStimulus: Int = 0
    private var samples: [GoNoGoResultObject.Sample] = []
    
    enum DisplayState: String, CaseIterable, Comparable, Codable {
        case starting, result, none, blue, green
        static func < (lhs: ShakeMotionSensor.DisplayState, rhs: ShakeMotionSensor.DisplayState) -> Bool {
            allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
        }
    }
    
    init(outputDirectory: URL = createOutputDirectory(), sectionIdentifier: String? = nil) {
        super.init(configuration: motionRecorderConfig,
                   outputDirectory: outputDirectory,
                   initialStepPath: "starting",
                   sectionIdentifier: sectionIdentifier)
    }
    
    @MainActor func processSamples() -> [GoNoGoResultObject.Sample] {
        samples
    }
    
    @MainActor func reset() {
        guard status <= .running else { return }
        
        resetCount += 1
        resetUptime = SystemClock.uptime()
        thresholdUptime = nil
        stimulusUptime = nil
        samples.removeAll()
        samplesSinceStimulus = 0
        dotType = .none
        resume()
    }
    
    @MainActor func onMotionReceived(_ vectorMagnitude: Double, timestamp: SystemUptime) async {
        guard status <= .running, dotType >= .none, !clock.isPaused else { return }
        
        // Get the relative clock time and exit early if this is old
        let uptime = clock.relativeUptime(to: timestamp)
        guard uptime > resetUptime else { return }
        
        // Add the sample if showing the stimulus
        if let stimulusUptime = stimulusUptime, uptime > stimulusUptime {
            let sample: GoNoGoResultObject.Sample = .init(timestamp: uptime - stimulusUptime, vectorMagnitude: vectorMagnitude)
            samples.append(sample)
        }
        
        let showingStimulus = stimulusUptime != nil
        let isShaking = vectorMagnitude > thresholdAcceleration
        
        // If not showing the stimulus then exit early
        guard showingStimulus else {
            if isShaking {
                // If the user jumps the gun, stop the test right away and exit.
                deviceShaked.send(timestamp)
            }
            return
        }
        
        // Advance the post-stimulus sample count
        samplesSinceStimulus += 1
        
        // Check if we should mark the threshold timestamp.
        if isShaking, thresholdUptime == nil {
            thresholdUptime = timestamp
        }
        
        // Finally, if there have been 100 samples since showing the stimulus and the
        // device was shaking during that time, then send the message.
        if samplesSinceStimulus >= 100, let timestamp = thresholdUptime {
            deviceShaked.send(timestamp)
        }
    }
    
    struct ShakeSample : SampleRecord, Codable, Hashable {
        private enum CodingKeys : String, OrderedEnumCodingKey {
            case stepPath, uptime, timestamp, sensorType, x, y, z, vectorMagnitude
        }
        
        let stepPath: String
        let uptime: ClockUptime
        let timestamp: SecondDuration?
        let sensorType: MotionRecorderType?
        let x: Double?
        let y: Double?
        let z: Double?
        let vectorMagnitude: Double?
        
        private(set) var timestampDate: Date? = nil
    }
    
    #if os(iOS)
    
    override func samples(from data: CMDeviceMotion, frame: CMAttitudeReferenceFrame, stepPath: String, uptime: ClockUptime, timestamp: SecondDuration) -> [SampleRecord] {
        let v = data.userAcceleration
        let vectorMagnitude = sqrt(((v.x * v.x) + (v.y * v.y) + (v.z * v.z)))
        Task {
            await onMotionReceived(vectorMagnitude, timestamp: data.timestamp)
        }
        return [
            ShakeSample(stepPath: stepPath,
                        uptime: uptime,
                        timestamp: timestamp,
                        sensorType: .userAcceleration,
                        x: v.x,
                        y: v.y,
                        z: v.z,
                        vectorMagnitude: vectorMagnitude)
        ]
    }
    
    #endif
}

let deviceShaked = PassthroughSubject<TimeInterval, Never>()

#if os(iOS) && targetEnvironment(simulator)
import UIKit

extension UIWindow {
     open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            deviceShaked.send(event?.timestamp ?? ProcessInfo.processInfo.systemUptime)
        }
     }
}
#endif
