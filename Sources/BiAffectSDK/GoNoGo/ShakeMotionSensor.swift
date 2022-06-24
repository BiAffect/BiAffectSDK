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

#if canImport(CoreMotion)
import CoreMotion
#endif

@MainActor
class ShakeMotionSensor : ObservableObject {
    @Published var resetUptime: TimeInterval?
    @Published var motionError: Error?
    @Published var state: State = .idle
    
    enum State: Int {
        case idle, started, listening, paused, stopped
    }
    
    var thresholdAcceleration: Double = 0.5
    var thresholdUptime: TimeInterval?
    var stimulusUptime: TimeInterval?
    var samplesSinceStimulus: Int = 0
    var samples: [GoNoGoResultObject.Sample] = []
    
    func processSamples(_ stimulusUptime: TimeInterval) -> [GoNoGoResultObject.Sample] {
        let ret: [GoNoGoResultObject.Sample] = samples.compactMap {
            $0.timestamp >= stimulusUptime ?
                .init(timestamp: $0.timestamp - stimulusUptime, vectorMagnitude: $0.vectorMagnitude) : nil
        }
        samples.removeAll()
        return ret
    }
    
    func reset() {
        guard state != .stopped else { return }
        
        resetUptime = ProcessInfo.processInfo.systemUptime
        thresholdUptime = nil
        stimulusUptime = nil
        samples.removeAll()
        samplesSinceStimulus = 0
        
        // Wait 0.5 seconds before listening for the participant to shake the device.
        Task {
            guard await Task.wait(seconds: 0.5) else { return }
            state = .listening
        }
    }
    
    #if os(iOS)
    
    let motionManager: CMMotionManager = .init()
    
    init() {
        motionManager.deviceMotionUpdateInterval = 0.01
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func start() {
        guard state == .idle else { return }
        state = .started
        listenForDeviceShake = true
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            if let motion = motion {
                self?.onMotionReceived(motion)
            }
            else {
                self?.motionError = error
            }
        }
    }
    
    func onMotionReceived(_ motion: CMDeviceMotion) {
        // Turn off listening for device "shake" b/c motion sensors are more precise.
        // This allows running the test if using the simulator or if permission to use
        // motion sensors has not been given.
        listenForDeviceShake = false
        
        // Ignore if not runnning
        guard state == .listening else { return }
        
        // Process the sample
        let v = motion.userAcceleration
        let vectorMagnitude = sqrt(((v.x * v.x) + (v.y * v.y) + (v.z * v.z)))
        let sample: GoNoGoResultObject.Sample = .init(timestamp: motion.timestamp, vectorMagnitude: vectorMagnitude)
        samples.append(sample)
        
        let showingStimulus = stimulusUptime != nil
        let isShaking = vectorMagnitude > thresholdAcceleration
        
        // If not showing the stimulus then exit early
        guard showingStimulus else {
            if isShaking {
                // If the user jumps the gun, stop the test right away and exit.
                deviceShaked.send(motion.timestamp)
            }
            return
        }
        
        // Advance the post-stimulus sample count
        samplesSinceStimulus += 1
        
        // Check if we should mark the threshold timestamp.
        if isShaking, thresholdUptime == nil {
            thresholdUptime = motion.timestamp
        }
        
        // Finally, if there have been 100 samples since showing the stimulus and the
        // device was shaking during that time, then send the message.
        if samplesSinceStimulus >= 100, let timestamp = thresholdUptime {
            state = .paused
            deviceShaked.send(timestamp)
        }
    }
    
    func stop() {
        state = .stopped
        listenForDeviceShake = false
        motionManager.stopDeviceMotionUpdates()
    }
    
    #else
    // If running on a Mac (unit tests) then these methods do nothing.
    func start() { }
    func stop() { }
    #endif
}

fileprivate var listenForDeviceShake: Bool = false
let deviceShaked = PassthroughSubject<TimeInterval, Never>()

#if os(iOS)
import UIKit

extension UIWindow {
     open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake, listenForDeviceShake {
            deviceShaked.send(event?.timestamp ?? ProcessInfo.processInfo.systemUptime)
        }
     }
}
#endif
