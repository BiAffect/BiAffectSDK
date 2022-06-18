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
    
    var thresholdUptime: TimeInterval?
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
        self.resetUptime = ProcessInfo.processInfo.systemUptime
        self.thresholdUptime = nil
        self.samples.removeAll()
    }
    
    func start() {
        listenForDeviceShake = true
    }
    
    func stop() {
        listenForDeviceShake = false
    }
}

fileprivate var listenForDeviceShake: Bool = false
let deviceShaked = PassthroughSubject<TimeInterval, Never>()

#if canImport(UIKit)
import UIKit

extension UIWindow {
     open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake, listenForDeviceShake {
            deviceShaked.send(event?.timestamp ?? ProcessInfo.processInfo.systemUptime)
        }
     }
}

#endif
