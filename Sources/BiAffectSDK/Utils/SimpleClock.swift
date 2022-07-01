//
//  SimpleClock.swift
//  
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
import Combine
import MobilePassiveData

@MainActor
class SimpleClock : ObservableObject {
    
    public private(set) var startTime: SystemUptime = ProcessInfo.processInfo.systemUptime
    private(set) var stopTime: SystemUptime? = nil
    private(set) var pauseCumulation: SecondDuration = 0
    private(set) var pauseStartTime: Double? = nil
    
    @Published var isPaused: Bool = false {
        didSet {
            if isPaused {
                pause()
            }
            else {
                resume()
            }
        }
    }
    
    public let onPauseChanged = PassthroughSubject<Bool, Never>()
    
    public func reset() {
        startTime = ProcessInfo.processInfo.systemUptime
        stopTime = nil
        pauseStartTime = nil
        pauseCumulation = 0
        isPaused = false
    }
    
    public func runningDuration(timestamp: SystemUptime = ProcessInfo.processInfo.systemUptime) -> SecondDuration {
        timestamp - startTime - pauseCumulation
    }
    
    public func stoppedDuration(timestamp: SystemUptime = ProcessInfo.processInfo.systemUptime) -> SecondDuration {
        stopTime.map { timestamp - $0 } ?? 0
    }

    private func pause() {
        guard pauseStartTime == nil else { return }
        pauseStartTime = ProcessInfo.processInfo.systemUptime
        onPauseChanged.send(true)
    }
    
    private func resume() {
        guard let pauseStartTime = pauseStartTime else { return }
        pauseCumulation += (ProcessInfo.processInfo.systemUptime - pauseStartTime)
        self.pauseStartTime = nil
        onPauseChanged.send(false)
    }
}
