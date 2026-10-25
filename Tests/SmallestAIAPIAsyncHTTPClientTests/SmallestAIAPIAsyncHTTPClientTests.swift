import Foundation
import HTTPTypes
import OpenAPIRuntime
import SmallestAIAPI
import SmallestAIAPIAsyncHTTPClient
import Testing

struct AsyncHTTPClientFactoryTests {
    @Test func defaultConfigurationDecodesISO8601() async throws {
        let client = Client.asyncHTTPClient(
            serverURL: URL(string: "https://example.invalid/custom")!,
            middlewares: [TokenResponse(timestamp: "2026-10-24T12:00:00Z")]
        )
        let response = try await client.auth_create_access_token(.init(body: .json(.init(ttl_seconds: 300))))
        let token = try response.created.body.json
        #expect(token.access_token == "wat_offline")
        #expect(token.expires_in == 300)
        #expect(token.expires_at == Date(timeIntervalSince1970: 1792843200))
    }

    @Test func explicitConfigurationOverrideDecodesFractionalSeconds() async throws {
        let client = Client.asyncHTTPClient(
            serverURL: URL(string: "https://example.invalid/custom")!,
            configuration: .init(dateTranscoder: .iso8601WithFractionalSeconds),
            middlewares: [TokenResponse(timestamp: "2026-10-24T12:00:00.125Z")]
        )
        let response = try await client.auth_create_access_token(.init(body: .json(.init(ttl_seconds: 300))))
        let token = try response.created.body.json
        #expect(token.expires_at == Date(timeIntervalSince1970: 1792843200.125))
    }

    @Test func factoryInstallsAuthenticationAndPropagatesProviderFailures() async throws {
        let client = Client.asyncHTTPClient(
            serverURL: URL(string: "https://example.invalid")!,
            authentication: .bearer { throw OfflineCredentialError.expected }
        )
        do {
            _ = try await client.auth_create_access_token(.init())
            Issue.record("Expected provider failure before transport")
        } catch let error as ClientError {
            #expect(error.underlyingError is OfflineCredentialError)
        }
    }

    @Test func missingCredentialsFailsBeforeNetwork() async throws {
        let client = Client.asyncHTTPClient(serverURL: URL(string: "https://example.invalid")!)
        do {
            _ = try await client.auth_create_access_token(.init())
            Issue.record("Expected missing credentials failure before transport")
        } catch let error as ClientError {
            guard case AuthenticationError.unsatisfiedSecurityRequirements(let id) = error.underlyingError else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(id == "auth_create_access_token")
        }
    }
}

private enum OfflineCredentialError: Error { case expected }

/// Terminates the middleware chain with a fixture; no transport or network is used.
private struct TokenResponse: ClientMiddleware {
    var timestamp: String

    func intercept(
        _ request: HTTPRequest, body: HTTPBody?, baseURL: URL, operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        #expect(baseURL.absoluteString == "https://example.invalid/custom")
        #expect(operationID == "auth_create_access_token")
        #expect(request.method == .post)
        #expect(request.path == "/waves/v1/auth/token")
        let body = try #require(body)
        let requestData = try await Data(collecting: body, upTo: 1024)
        let object = try #require(JSONSerialization.jsonObject(with: requestData) as? [String: Int])
        #expect(object["ttl_seconds"] == 300)
        return (
            HTTPResponse(status: .created, headerFields: [.contentType: "application/json"]),
            HTTPBody("{\"access_token\":\"wat_offline\",\"token_type\":\"Bearer\",\"expires_in\":300,\"expires_at\":\"\(timestamp)\"}")
        )
    }
}
