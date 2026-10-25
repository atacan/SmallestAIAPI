import Foundation
import SmallestAIAPITypes
import Testing

struct ResponseDecodingTests {
    @Test(arguments: [
        "captured-pulse-pro-word.json",
        "captured-pulse-pro-text.json",
        "captured-pulse-pro-no-language.json",
        "captured-pulse-word.json",
        "captured-pulse-text.json",
        "captured-pulse-multi-eu.json",
        "captured-pulse-language-zh.json",
        "captured-pulse-multi-indic.json",
        "captured-pulse-diarize-word-remote.json",
        "captured-pulse-diarize-remote.json",
        "captured-pulse-diarize-word.json",
        "captured-pulse-pro-diarize.json",
        "captured-pulse-pro-remote.json",
        "captured-pulse-keywords.json",
        "captured-pulse-keywords-phrase.json",
        "captured-pulse-pro-keywords.json",
        "captured-pulse-detection.json",
        "captured-pulse-us-host.json",
        "captured-pulse-india-host.json",
        "captured-pulse-access-token.json",
    ])
    func capturedSuccessRetainsAllFields(filename: String) throws {
        let data = try fixture(filename)
        let response = try JSONDecoder().decode(Components.Schemas.TranscriptionResponse.self, from: data)
        #expect(response.status == "success")
        #expect(!response.transcription.isEmpty)
        let union = try JSONDecoder().decode(Components.Schemas.Speech_to_Text_transcribe_Response_200.self, from: data)
        guard case .TranscriptionResponse = union else {
            Issue.record("Expected synchronous transcription for \(filename)")
            return
        }
        try expectSameJSON(JSONEncoder().encode(response), data)
    }

    @Test(arguments: [
        "captured-pulse-no-language.json",
        "captured-pulse-url-as-octet-stream.json",
        "captured-error-pulse-pro-language-de.json",
        "captured-error-unknown-model.json",
        "captured-error-word-timestamps-capitalized.json",
        "captured-error-keywords-101.json",
        "captured-error-empty-audio.json",
        "captured-error-401.json",
        "captured-error-no-auth.json",
    ])
    func capturedErrorsRetainAllFields(filename: String) throws {
        let data = try fixture(filename)
        let response = try JSONDecoder().decode(Components.Schemas.SttErrorResponse.self, from: data)
        #expect(response.error != nil || response.message != nil)
        try expectSameJSON(JSONEncoder().encode(response), data)
    }

    @Test func errorsDecodeArrayAndStringVariants() throws {
        let array = try JSONDecoder()
            .decode(
                Components.Schemas.SttErrorResponse.self,
                from: fixture("captured-error-pulse-pro-language-de.json")
            )
        guard case .SttErrorResponseErrors0(let details) = array.errors else {
            Issue.record("Expected validation error array")
            return
        }
        #expect(!details.isEmpty)
        let string = try JSONDecoder()
            .decode(
                Components.Schemas.SttErrorResponse.self,
                from: fixture("captured-error-empty-audio.json")
            )
        guard case .case2(let message) = string.errors else {
            Issue.record("Expected body error string")
            return
        }
        #expect(message == "Empty request body")
    }

    @Test(arguments: [
        "captured-pulse-diarize-word.json", "captured-pulse-diarize-remote.json",
        "captured-pulse-diarize-word-remote.json",
    ])
    func diarizationRetainsSpeakerTurns(filename: String) throws {
        let response = try JSONDecoder().decode(Components.Schemas.TranscriptionResponse.self, from: fixture(filename))
        let segments = try #require(response.diarization_segments)
        #expect(segments.count == 3)
        #expect(segments[0].start == 0.8)
        #expect(segments[0].end == 3.76)
        #expect(segments.map(\.speaker) == [0, 1, 0])
        #expect(response.words?.isEmpty == false)
        #expect(response.utterances?.isEmpty == false)
    }

    @Test func asyncAcknowledgementDecodesAsAsyncVariant() throws {
        let url = try #require(Bundle.module.url(forResource: "async-accepted-example", withExtension: "json", subdirectory: "Resources"))
        let data = try Data(contentsOf: url)
        let response = try JSONDecoder().decode(Components.Schemas.Speech_to_Text_transcribe_Response_200.self, from: data)
        guard case .AsyncAccepted(let acknowledgement) = response else {
            Issue.record("Expected asynchronous acknowledgement")
            return
        }
        #expect(acknowledgement.status == "processing")
        #expect(acknowledgement.request_id == "offline-request")
        try expectSameJSON(JSONEncoder().encode(acknowledgement), data)
    }

    @Test func regionalServerURLsAreStable() throws {
        #expect(try Servers.Server1.url().absoluteString == "https://api.smallest.ai")
        #expect(try Servers.Server2.url().absoluteString == "https://api.us.smallest.ai")
        #expect(try Servers.Server3.url().absoluteString == "https://api.india.smallest.ai")
    }

    private func fixture(_ filename: String) throws -> Data {
        let url = try #require(Bundle.module.url(forResource: filename, withExtension: nil, subdirectory: "Resources/Responses"))
        return try Data(contentsOf: url)
    }

    private func expectSameJSON(_ actual: Data, _ expected: Data) throws {
        let actualObject = try #require(JSONSerialization.jsonObject(with: actual) as? NSDictionary)
        let expectedObject = try #require(JSONSerialization.jsonObject(with: expected) as? NSDictionary)
        #expect(actualObject == expectedObject)
    }

    @Test func transcriptionRetainsFractionalMetadataAndOptionalFields() throws {
        let payload = Data(
            #"{"status":"success","transcription":"Offline fixture","totalBytes":12.5,"words":[{"word":"Offline","start":0.125,"end":0.875}],"metadata":{"duration":0.875,"processing_time_ms":12.5},"emotions":{"happiness":0.75}}"#
                .utf8
        )
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
