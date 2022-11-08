//
//  ShakeMotionSensor.swift
//

import SwiftUI
import Combine
import MobilePassiveData
import MotionSensor
import JsonModel

#if canImport(CoreMotion)
import CoreMotion
#endif

fileprivate let recordSchema = DocumentableRootArray(rootDocumentType: MotionSample.self,
                                          jsonSchema: .init(string: "MotionSample.json", relativeTo: kBaseJsonSchemaURL)!,
                                          documentDescription: "A list of motion sensor records.")

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
    var resetUptime: SystemUptime = .greatestFiniteMagnitude
    var stimulusUptime: SystemUptime?
    
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
        resetUptime = clock.now()
        thresholdUptime = nil
        stimulusUptime = nil
        samples.removeAll()
        samplesSinceStimulus = 0
        dotType = .none
        resume()
    }
    
    @MainActor func onMotionReceived(_ vectorMagnitude: Double, timestamp: SystemUptime) async {
        guard status <= .running, dotType >= .none, !isPaused else { return }
        
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
    
    override var schemaDoc: DocumentableRootArray? { recordSchema }

    #if os(iOS)
    
    override func samples(from data: CMDeviceMotion, frame: CMAttitudeReferenceFrame, stepPath: String, uptime: ClockUptime, timestamp: SecondDuration) -> [SampleRecord] {
        let v = data.userAcceleration
        let vectorMagnitude = sqrt(((v.x * v.x) + (v.y * v.y) + (v.z * v.z)))
        Task {
            await onMotionReceived(vectorMagnitude, timestamp: data.timestamp)
        }
        return [
            MotionSample(stepPath: stepPath,
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

struct MotionSample : SampleRecord, Codable, Hashable {
    private enum CodingKeys : String, OrderedEnumCodingKey {
        case stepPath, uptime, timestamp, timestampDate, sensorType, x, y, z, vectorMagnitude
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

extension MotionSample : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        return CodingKeys.allCases
    }

    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        (codingKey as? CodingKeys) == CodingKeys.stepPath
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .uptime:
            return .init(propertyType: .primitive(.number), propertyDescription: "System clock time.")
        case .timestamp:
            return .init(propertyType: .primitive(.number), propertyDescription: "Time that the system has been awake since last reboot.")
        case .stepPath:
            return .init(propertyType: .primitive(.string), propertyDescription: "An identifier marking the current step.")
        case .timestampDate:
            return .init(propertyType: .format(.dateTime), propertyDescription: "The date timestamp when the measurement was taken (if available).")
        case .sensorType:
            return .init(propertyType: .reference(MotionRecorderType.documentableType()), propertyDescription: "The sensor type for this record sample.")
        case .x:
            return .init(propertyType: .primitive(.number), propertyDescription: "The `x` component of the vector measurement for this sensor sample.")
        case .y:
            return .init(propertyType: .primitive(.number), propertyDescription: "The `y` component of the vector measurement for this sensor sample.")
        case .z:
            return .init(propertyType: .primitive(.number), propertyDescription: "The `z` component of the vector measurement for this sensor sample.")
        case .vectorMagnitude:
            return .init(propertyType: .primitive(.number), propertyDescription: "The calculated vector magnitude used to determine whether or not the device was shaken. (`sensorType==userAcceleration`)")
        }
    }

    public static func examples() -> [MotionSample] {
        let json = """
        [
            {
              "uptime" : 1350727.0347595001,
              "timestamp" : 0.22008016658946872,
              "stepPath" : "attempt/1/showing/none",
              "sensorType" : "gyro",
              "x" : 0.043036416172981262,
              "y" : -0.038228876888751984,
              "z" : 0.012300875037908554
            },
            {
              "uptime" : 1350727.0347595001,
              "timestamp" : 0.22008016658946872,
              "stepPath" : "attempt/1/showing/none",
              "sensorType" : "accelerometer",
              "x" : 0.0980987548828125,
              "y" : -0.483734130859375,
              "z" : -0.8672332763671875
            },
            {
              "stepPath" : "attempt/1/showing/none",
              "uptime" : 1350727.0408015,
              "timestamp" : 0.22612216649577022,
              "sensorType" : "userAcceleration",
              "x" : 0.001909300684928894,
              "y" : -0.0058466494083404541,
              "z" : 0.0059053897857666016,
              "vectorMagnitude" : 0.008526568297466116
            }
        ]
        """.data(using: .utf8)! // our data in native (JSON) format
        let decoder = BiAffectFactory().createJSONDecoder()
        return try! decoder.decode([MotionSample].self, from: json)
    }
}

