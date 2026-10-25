import Foundation
import HTTPTypes
import OpenAPIRuntime
import SmallestAIAPI
import Testing

struct AuthenticationTests {
    @Test(arguments: [
        "auth_create_access_token", "textToSpeech_synthesizeSpeech", "textToSpeech_synthesizeSpeechSse",
        "voiceCloning_createVoiceClone", "voiceCloning_listVoiceClones",
        "pronunciationDictionaries_getPronunciationDicts", "pronunciationDictionaries_createPronunciationDict",
        "pronunciationDictionaries_updatePronunciationDict", "pronunciationDictionaries_deletePronunciationDict",
        "speechToText_transcribe", "electron_complete",
    ])
    func protectedOperationSendsExactProviderHeader(operationID: String) async throws {
        let middleware = AuthenticationMiddleware(authentication: .bearer("offline-key"))
        _ = try await middleware.intercept(
            HTTPRequest(method: .post, scheme: "https", authority: "example.invalid", path: "/"),
            body: nil, baseURL: URL(string: "https://example.invalid")!, operationID: operationID
        ) { request, _, _ in
            #expect(request.headerFields[.authorization] == "Bearer offline-key")
            return (HTTPResponse(status: .ok), nil)
        }
    }

    @Test func namedCredentialAndProviderAreResolvedPerRequest() async throws {
        let tokens = Tokens()
        let middleware = AuthenticationMiddleware(authentication: .credentials([
            "BearerAuth": .init(provider: { await tokens.next() })
        ]))
        for expected in ["Bearer offline-1", "Bearer offline-2"] {
            _ = try await middleware.intercept(
                HTTPRequest(method: .post, scheme: "https", authority: "example.invalid", path: "/"),
                body: nil, baseURL: URL(string: "https://example.invalid")!,
                operationID: "speechToText_transcribe"
            ) { request, _, _ in
                #expect(request.headerFields[.authorization] == expected)
                return (HTTPResponse(status: .ok), nil)
            }
        }
        #expect(await tokens.count == 2)
    }

    @Test func publicVoicesDoesNotResolveCredentials() async throws {
        let tokens = Tokens()
        let middleware = AuthenticationMiddleware(authentication: .bearer { await tokens.next() })
        _ = try await middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.invalid", path: "/"),
            body: nil, baseURL: URL(string: "https://example.invalid")!, operationID: "voices_getWavesVoices"
        ) { request, _, _ in
            #expect(request.headerFields[.authorization] == nil)
            return (HTTPResponse(status: .ok), nil)
        }
        #expect(await tokens.count == 0)
    }

    @Test func missingAndWrongSchemeCredentialsFailBeforeTransport() async throws {
        for authentication in [Authentication.none, .apiKey("offline-key"), .credentials(["wrong": .init("key")])] {
            do {
                _ = try await AuthenticationMiddleware(authentication: authentication).intercept(
                    HTTPRequest(method: .post, scheme: "https", authority: "example.invalid", path: "/"),
                    body: nil, baseURL: URL(string: "https://example.invalid")!,
                    operationID: "speechToText_transcribe"
                ) { _, _, _ in
                    Issue.record("Missing credentials must never reach the transport")
                    return (HTTPResponse(status: .ok), nil)
                }
                Issue.record("Expected authentication failure")
            } catch AuthenticationError.unsatisfiedSecurityRequirements(let operationID) {
                #expect(operationID == "speechToText_transcribe")
            }
        }
    }
}

private actor Tokens {
    var count = 0
    func next() -> String {
        count += 1
        return "offline-\(count)"
    }
}
