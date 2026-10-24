import Foundation
import SmallestAIAPITypes
import Testing

struct ResponseDecodingTests {
    @Test func transcriptionRetainsFractionalMetadataAndOptionalFields() throws {
        let payload = Data(#"{"status":"success","transcription":"Offline fixture","totalBytes":12.5,"words":[{"word":"Offline","start":0.125,"end":0.875}],"metadata":{"duration":0.875,"processing_time_ms":12.5},"emotions":{"happiness":0.75}}"#.utf8)
        let response = try JSONDecoder().decode(Components.Schemas.TranscriptionResponse.self, from: payload)
        #expect(response.transcription == "Offline fixture")
        #expect(response.totalBytes == 12.5)
        #expect(response.words?.first?.start == 0.125)
        #expect(response.metadata?.processing_time_ms == 12.5)
        #expect(response.emotions?.additionalProperties["happiness"] == 0.75)
        #expect(response.utterances == nil)
        #expect(response.language == nil)
    }
}
