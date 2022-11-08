//
//  TrailmakingTests.swift
//

import XCTest
@testable import BiAffectSDK
import JsonModel
import ResultModel
import AssessmentModelUI

final class TrailmakingTests: XCTestCase {
    
    func testTrailGenerator_0() {
        let trail = TrailmakingPoint.generate(testNum: 0, invertX: false, invertY: false, reverse: false)
        trail.enumerated().forEach { (index, point) in
            XCTAssertEqual(index, point.index)
        }
        XCTAssertEqual(0.819257, trail.first!.x, accuracy: 0.000001)
        XCTAssertEqual(0.121951, trail.first!.y, accuracy: 0.000001)
        
        let labels = trail.map { $0.label }
        XCTAssertEqual(["1","A","2","B","3","C","4","D","5","E","6","F","7"], labels)
    }
    
    func testTrailGenerator_0_reversed() {
        let trail = TrailmakingPoint.generate(testNum: 0, invertX: false, invertY: false, reverse: true)
        trail.enumerated().forEach { (index, point) in
            XCTAssertEqual(index, point.index)
        }
        XCTAssertEqual(0.819257, trail.last!.x, accuracy: 0.000001)
        XCTAssertEqual(0.121951, trail.last!.y, accuracy: 0.000001)
        
        let labels = trail.map { $0.label }
        XCTAssertEqual(["1","A","2","B","3","C","4","D","5","E","6","F","7"], labels)
    }

    func testTrailGenerator_0_invertX() {
        let trail = TrailmakingPoint.generate(testNum: 0, invertX: true, invertY: false, reverse: false)
        trail.enumerated().forEach { (index, point) in
            XCTAssertEqual(index, point.index)
        }
        XCTAssertEqual(0.180743, trail.first!.x, accuracy: 0.000001)
        XCTAssertEqual(0.121951, trail.first!.y, accuracy: 0.000001)
        
        let labels = trail.map { $0.label }
        XCTAssertEqual(["1","A","2","B","3","C","4","D","5","E","6","F","7"], labels)
    }
    
    func testTrailGenerator_0_invertY() {
        let trail = TrailmakingPoint.generate(testNum: 0, invertX: false, invertY: true, reverse: false)
        trail.enumerated().forEach { (index, point) in
            XCTAssertEqual(index, point.index)
        }
        XCTAssertEqual(0.819257, trail.first!.x, accuracy: 0.000001)
        XCTAssertEqual(0.878049, trail.first!.y, accuracy: 0.000001)
        
        let labels = trail.map { $0.label }
        XCTAssertEqual(["1","A","2","B","3","C","4","D","5","E","6","F","7"], labels)
    }
    
    func testTrailmakingResult_Copy() {
        let resultA = TrailmakingResultObject()
        resultA.endDateTime = Date()
        resultA.points = TrailmakingPoint.generate(testNum: 0)
        resultA.numberOfErrors = 1
        resultA.pauseInterval = 3.123
        resultA.responses = [.init(timestamp: 1.2, index: 0, incorrect: false), .init(timestamp: 3.3, index: 1, incorrect: false)]
        resultA.runtime = 8.000
        
        let copyA = resultA.deepCopy()
        XCTAssertEqual(resultA.identifier, copyA.identifier)
        XCTAssertEqual(resultA.serializableType, copyA.serializableType)
        XCTAssertEqual(resultA.startDateTime, copyA.startDateTime)
        XCTAssertEqual(resultA.endDateTime, copyA.endDateTime)
        XCTAssertEqual(resultA.points, copyA.points)
        XCTAssertEqual(resultA.numberOfErrors, copyA.numberOfErrors)
        XCTAssertEqual(resultA.pauseInterval, copyA.pauseInterval)
        XCTAssertEqual(resultA.runtime, copyA.runtime)
    }
    
    func testTrailmakingResult_CodingNull() {
        let result = TrailmakingResultObject()
        do {
            let factory = BiAffectFactory()
            let decoder = factory.createJSONDecoder()
            
            // check that the empty unstarted result can be serialized
            guard let archivable = try result.buildArchivableFileData(at: "foo/trailmaking")
            else {
                XCTFail("Failed to build the archivable object. Expected NULL")
                return
            }
            
            XCTAssertEqual("foo/trailmaking", archivable.fileInfo.stepPath)
            XCTAssertEqual("trailmaking.json", archivable.fileInfo.filename)
            
            // Check that it can be decoded from the encoded object
            // Note: Encoding/Decoding is auto-generated for this object so it doesn't require equality testing
            // which would fail, anyway, bc of precision errors in the encoded number.
            let _ = try decoder.decode(ResultWrapper<TrailmakingResultObject>.self, from: archivable.data).object
        }
        catch {
            XCTFail("Failed to encode/decode result. \(error)")
        }
    }
    
    func testTrailmakingResult_CodingNonNull() {
        let result = TrailmakingResultObject()
        result.endDateTime = Date()
        result.points = TrailmakingPoint.generate(testNum: 0)
        result.numberOfErrors = 1
        result.pauseInterval = 3.123
        result.responses = [.init(timestamp: 1.2, index: 0, incorrect: false), .init(timestamp: 3.3, index: 1, incorrect: false)]
        result.runtime = 8.000
        
        do {
            let factory = BiAffectFactory()
            let decoder = factory.createJSONDecoder()
            
            // check that the empty unstarted result can be serialized
            guard let archivable = try result.buildArchivableFileData(at: "foo/trailmaking")
            else {
                XCTFail("Failed to build the archivable object. Expected NULL")
                return
            }
            
            XCTAssertEqual("foo/trailmaking", archivable.fileInfo.stepPath)
            XCTAssertEqual("trailmaking.json", archivable.fileInfo.filename)
            
            // Check that the result is registered by the factory.
            // Note: Encoding/Decoding is auto-generated for this object so it doesn't require equality testing
            // which would fail, anyway, bc of precision errors in the encoded number.
            let _ = try decoder.decode(ResultWrapper<TrailmakingResultObject>.self, from: archivable.data).object
            
            guard let dictionary = try JSONSerialization.jsonObject(with: archivable.data) as? [String : Any]
            else {
                XCTFail("Failed to decode a dictionary.")
                return
            }
            
            XCTAssertEqual(result.identifier, dictionary["identifier"] as? String)
            XCTAssertEqual(result.serializableType.rawValue, dictionary["type"] as? String)
            XCTAssertNotNil(dictionary["startDate"])
            XCTAssertNotNil(dictionary["endDate"])
            XCTAssertEqual(result.numberOfErrors, dictionary["numberOfErrors"] as? Int)
            XCTAssertEqual(result.pauseInterval!, dictionary["pauseInterval"] as? Double ?? 0, accuracy: 0.000001)
            XCTAssertEqual(result.runtime!, dictionary["runtime"] as? Double ?? 0, accuracy: 0.000001)
            XCTAssertEqual(13, (dictionary["points"] as? [Any])?.count)
            XCTAssertEqual(2, (dictionary["taps"] as? [Any])?.count)
        }
        catch {
            XCTFail("Failed to encode/decode result. \(error)")
        }
    }
    
    @MainActor
    func testRunTrailmakingTest() async throws {
        let viewModel = TrailmakingStepView.ViewModel()
        let step = TrailmakingStepObject()
        let result = TrailmakingResultObject()
        let nodeState = StepState(step: step, result: result)
        
        // Start
        viewModel.onAppear(nodeState)
        
        // Check initial startup values
        XCTAssertNotNil(viewModel.result)
        XCTAssertEqual(.running, viewModel.testState)
        XCTAssertEqual(viewModel.points, result.points)
        XCTAssertEqual([], result.responses)
        XCTAssertNotEqual(0, viewModel.clock.startTime)
        
        // tap each button
        for ii in 0..<viewModel.points.count {
            
            // If this is the 4th button then tap the wrong one
            if ii == 4 {
                viewModel.onTap(at: 6)
                // Verify results
                XCTAssertEqual(1, viewModel.numberOfErrors)
                XCTAssertEqual(1, result.numberOfErrors)
                XCTAssertEqual(6, viewModel.lastIncorrectTap)
                XCTAssertEqual(4, viewModel.currentIndex)
                if let lastTap = result.responses?.last {
                    XCTAssertEqual(6, lastTap.index)
                    XCTAssertTrue(lastTap.incorrect)
                }
                else {
                    XCTFail("Failed to add response for incorrect tap")
                }
            }
            
            // For each button tap the correct one
            viewModel.onTap(at: ii)
            XCTAssertEqual(ii+1, viewModel.currentIndex)
            XCTAssertEqual(-1, viewModel.lastIncorrectTap)
            if let lastTap = result.responses?.last {
                XCTAssertEqual(ii, lastTap.index)
                XCTAssertFalse(lastTap.incorrect)
            }
            else {
                XCTFail("Failed to add response for incorrect tap")
            }
        }
        
        XCTAssertEqual(viewModel.points.count, viewModel.currentIndex)
        XCTAssertEqual(.stopping, viewModel.testState)
        XCTAssertNotNil(result.runtime)
        
        guard let responses = result.responses
        else {
            XCTFail("Unexpeted Null")
            return
        }
        
        let indexOrder = [0,1,2,3,6,4,5,6,7,8,9,10,11,12]
        XCTAssertEqual(indexOrder, responses.map { $0.index} )
        let incorrect = [false,false,false,false,true,false,false,false,false,false,false,false,false,false]
        XCTAssertEqual(incorrect, responses.map { $0.incorrect } )
        let sorted = responses.sorted(by: { $0.timestamp < $1.timestamp })
        XCTAssertEqual(sorted, responses)
    }
    
    @MainActor
    func testRunTrailmakingTest_Pause() async throws {
        let viewModel = TrailmakingStepView.ViewModel()
        let step = TrailmakingStepObject()
        let result = TrailmakingResultObject()
        let nodeState = StepState(step: step, result: result)
        
        // Start
        viewModel.onAppear(nodeState)
        
        // Pause
        let firstInterval = try await pause(viewModel: viewModel)
        XCTAssertEqual(firstInterval, viewModel.clock.pauseCumulation, accuracy: 0.1)
        
        // Pause again
        let secondInterval = try await pause(viewModel: viewModel)
        XCTAssertEqual((firstInterval + secondInterval), viewModel.clock.pauseCumulation, accuracy: 0.1)
    }
    
    @MainActor
    func pause(viewModel: TrailmakingStepView.ViewModel, seconds: UInt64 = 1) async throws -> TimeInterval {
        let before = ProcessInfo.processInfo.systemUptime
        viewModel.clock.pause()
        try await Task.sleep(nanoseconds: seconds * 1_000_000_000)
        viewModel.clock.resume()
        let after = ProcessInfo.processInfo.systemUptime
        return after - before
    }
}

struct ResultWrapper<Value : ResultData> : Decodable {
    let object : Value
    init(from decoder: Decoder) throws {
        let obj = try decoder.serializationFactory.decodePolymorphicObject(ResultData.self, from: decoder)
        guard let aObj = obj as? Value else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Failed to decode a QuestionStep")
            throw DecodingError.typeMismatch(Value.self, context)
        }
        self.object = aObj
    }
}
