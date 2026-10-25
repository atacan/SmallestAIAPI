import Foundation
import HTTPTypes
import OpenAPIRuntime
import SmallestAIAPI
import SmallestAIAPITypes
import Testing

struct RequestSerializationTests {
    @Test(arguments: [Components.Schemas.WavesV1SttPostParametersModel.pulse, .pulse_hyphen_pro])
    func urlBodyUsesJSONContentType(model: Components.Schemas.WavesV1SttPostParametersModel) async throws {
        let client = Client(
            serverURL: URL(string: "https://example.invalid")!,
            transport: STTRequestTransport(expectedJSONURL: "https://example.com/audio.wav"),
            authentication: .bearer("offline-key")
        )
        let response = try await client.speechToText_transcribe(
            .init(
                query: .init(model: model, language: .en),
                body: .json(.init(url: "https://example.com/audio.wav"))
            )
        )
        guard case .AsyncAccepted(let acknowledgement) = try response.ok.body.json else {
            Issue.record("Expected fixture acknowledgement")
            return
        }
        #expect(acknowledgement.request_id == "offline-request")
    }

    @Test func binaryBodyRetainsContentTypeAndBytes() async throws {
        let client = Client(
            serverURL: URL(string: "https://example.invalid")!,
            transport: STTRequestTransport(expectedJSONURL: nil),
            authentication: .bearer("offline-key")
        )
        _ = try await client.speechToText_transcribe(
            .init(
                query: .init(model: .pulse_hyphen_pro, language: .en),
                body: .binary(HTTPBody(Data([0, 1, 2, 255])))
            )
        )
    }
}

/// Examines generated requests and returns a fixture without touching the network.
private struct STTRequestTransport: ClientTransport {
    var expectedJSONURL: String?

    func send(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String) async throws -> (HTTPResponse, HTTPBody?) {
        #expect(baseURL.absoluteString == "https://example.invalid")
        #expect(request.method == .post)
        #expect(request.path?.hasPrefix("/waves/v1/stt/?") == true)
        #expect(operationID == "speechToText_transcribe")
        #expect(request.headerFields[.authorization] == "Bearer offline-key")
        let data = try await Data(collecting: #require(body), upTo: 4096)
        if let expectedJSONURL {
            #expect(request.headerFields[.contentType] == "application/json; charset=utf-8")
            let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
            #expect(object == ["url": expectedJSONURL])
        } else {
            #expect(request.headerFields[.contentType] == "application/octet-stream")
            #expect(data == Data([0, 1, 2, 255]))
        }
        return (
            HTTPResponse(status: .ok, headerFields: [.contentType: "application/json"]),
            HTTPBody(#"{"status":"processing","request_id":"offline-request"}"#)
        )
    }
}
