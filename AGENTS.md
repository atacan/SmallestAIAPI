We generate the Swift code using swift-openapi-generator. As we apply complex transformations to the original OpenAPI specification, we use a Python tool to do this. Run the generation with 

```bash
make regenerate
```

As this is a Swift package, you can find the code of the Swift package dependencies in the ".build/checkouts/" directory. Look at that folder when you need to understand how to use the code from the Swift package dependencies.


The HTTP package exposes four products: SmallestAIAPITypes (models), SmallestAIAPI
(core client and shared authentication), SmallestAIAPIURLSession, and
SmallestAIAPIAsyncHTTPClient. Keep core independent of concrete transports. The
current resolved dependencies require Swift 6.2+, verified here with Swift 6.4;
the root tools-version alone does not represent dependency compiler requirements.

URLSession example:

```swift
import SmallestAIAPI
import SmallestAIAPITypes
import SmallestAIAPIURLSession

let client = Client.urlSession(
    serverURL: try Servers.Server1.url(),
    authentication: .apiKey("Bearer \(apiKey)")
)
```

AsyncHTTPClient example (declare NIOCore directly when using timeouts):

```swift
import SmallestAIAPI
import SmallestAIAPITypes
import SmallestAIAPIAsyncHTTPClient
import NIOCore

let client = Client.asyncHTTPClient(
    serverURL: try Servers.Server1.url(),
    authentication: .apiKey("Bearer \(apiKey)"),
    transportConfiguration: .init(timeout: .seconds(120))
)
```

BearerAuth is a header API key in the final overlaid specification. Preserve the
complete Bearer prefix through `.apiKey(...)`; `.bearer(...)` is the wrong scheme.
Shared middleware lives in the core module; the old Types middleware API is retired.
The public voices operation has no security requirement. Regenerate authentication
metadata from the original spec/overlay instead of editing GeneratedSecurity.
Factory defaults use runtime ISO 8601 dates; fractional seconds can be requested
with `configuration: .init(dateTranscoder: .iso8601WithFractionalSeconds)`.

After dependency changes run `swift package resolve`, then `make regenerate`,
`swift build`, and the offline suites:

```sh
swift test --filter 'AuthenticationTests|FactoryTests|ResponseDecodingTests'
```

Live tests load credentials only with explicit RUN_LIVE_TESTS=1. Do not run them
or read local secrets during offline verification. Keep the UsefulThings streaming
body and live transcription test's 120-second timeout when changing client setup.
Preserve original spec, overlays, configs, editable factories, tests, platform
settings, and custom Makefile recipes on reruns. `make generate` only regenerates
Swift code; `make regenerate` also updates transformations and operation security.
For authentication failures inspect the final scheme and operation requirements;
for toolchain failures check resolved dependency tools-version headers.
