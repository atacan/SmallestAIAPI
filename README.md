# SmallestAIAPI

Swift package generated from `original_openapi.json` using
[swift-openapi-bootstrapper](https://github.com/atacan/swift-package-generator-based-on-openapi).

The package provides four libraries: `SmallestAIAPITypes` for API models,
`SmallestAIAPI` for the transport-independent client and shared authentication,
`SmallestAIAPIURLSession` for Foundation URLSession, and
`SmallestAIAPIAsyncHTTPClient` for Swift server applications. Platform settings
remain macOS 13, iOS 16, tvOS 16, and watchOS 9 or later.

The current resolved dependencies require **Swift 6.2 or later**, even though the
root manifest retains its Swift 5.9 tools-version. AsyncHTTPClient 1.36.2 and
several transitive dependencies declare tools-version 6.2. Migration was verified
with Apple Swift 6.4 on macOS; Swift 6.2 itself and other platforms were not tested.

```swift
import SmallestAIAPI
import SmallestAIAPITypes
import SmallestAIAPIURLSession

let client = Client.urlSession(
    serverURL: try Servers.Server1.url(),
    authentication: .bearer(apiKey)
)
```

For AsyncHTTPClient, import its convenience module. Import NIOCore and declare it
as a direct target dependency when using timeout values:

```swift
import SmallestAIAPI
import SmallestAIAPITypes
import SmallestAIAPIAsyncHTTPClient
import NIOCore

let client = Client.asyncHTTPClient(
    serverURL: try Servers.Server1.url(),
    authentication: .bearer(apiKey),
    transportConfiguration: .init(timeout: .seconds(120))
)
```

The overlaid specification declares `BearerAuth` as HTTP bearer authentication.
Pass an unprefixed API key or supported access token to `.bearer(...)`; the
middleware adds `Bearer `. Named credentials also take unprefixed values:
`Authentication.credentials(["BearerAuth": .init(apiKey)])`. Providers such as
`.bearer { ... }` are evaluated per authenticated request. The public voices
operation does not require credentials. Protected operations fail before transport
if credentials are missing or the wrong scheme is supplied.

The legacy `SmallestAIAPITypes.AuthenticationMiddleware(apiKey:)` API has been
retired. Custom transports can use the core client's `authentication:` initializer
or `SmallestAIAPI.AuthenticationMiddleware(authentication:)`. Transport imports
now belong in the corresponding convenience module or caller target. These are
source changes for downstream callers; generated public model types are unchanged
by this migration.

Both factories retain the runtime's default ISO 8601 date configuration. Pass
`configuration: .init(dateTranscoder: .iso8601WithFractionalSeconds)` explicitly
when a response contains fractional seconds. Runtime configuration, server URL,
transport configuration, and extra middleware remain caller-overridable. Middleware
runs before shared authentication; injected sessions/HTTP clients remain owned by
the caller.

```sh
make regenerate # Transform the original specification and generate Swift sources (requires uv)
make generate   # Generate Swift sources from the transformed openapi.json
swift build
swift test --filter 'AuthenticationTests|FactoryTests|ResponseDecodingTests|RequestSerializationTests'
```

Keep `original_openapi.json` as the source specification. Add manual schema fixes
to `openapi-overlay.json`, then run `make regenerate`. Generated files under
`Sources/*/GeneratedSources`, `Sources/SmallestAIAPI/Authentication/GeneratedSecurity`,
and `openapi.json` are replaced during regeneration. Factories, shared authentication
helpers, manifest, tests, documentation, configs, and the Makefile are preserved.
After changing dependencies, run `swift package resolve`, `make regenerate`, then
build and test the final generated output. `make generate` alone does not update
schema transformations or operation authentication metadata.

Offline suites use local fixtures and do not read `.env` or make HTTP requests.
Live environment credential loading is explicitly gated by `RUN_LIVE_TESTS=1`.
If authentication fails, check the exact security scheme and requirement in `openapi.json` before
editing helpers; use the overlay for persistent spec fixes.
When dependency resolution reports an unsupported tools-version, select a compatible
Swift toolchain and compare dependency manifest headers in `.build/checkouts`.

## Secret scanning

Following the [secret-scanning guide](https://actondon.com/blog/secret-scanning-for-git-repo),
commits are checked with Betterleaks for secret patterns and TruffleHog for active
credentials or credentials whose verification fails. Install the prerequisites
and activate the hooks in each clone:

```sh
brew install pre-commit go trufflehog
make install-hooks
```

pre-commit builds the pinned Betterleaks release using Go. TruffleHog uses the
installed executable (CI pins version 3.97.9). Betterleaks checks the staged diff;
TruffleHog checks staged files while pre-commit temporarily stashes unstaged
edits. Missing scanners and scan errors block the commit. TruffleHog contacts
credential providers for verification, so it requires network access.

Run the hooks manually on staged changes with `pre-commit run`. GitHub Actions
runs both scanners on pull requests targeting `main`, pushes to `main`, and
manual dispatches. Betterleaks scans all fetched refs; TruffleHog scans the full
history reachable from the checked-out commit. Findings in old commits also
fail CI, even if the secret was later removed. Scan output omits secret values.

Review false positives individually. Betterleaks supports fingerprints in
`.betterleaksignore` or a `betterleaks:allow` comment on the affected line;
TruffleHog supports `trufflehog:ignore` on the affected line. Keep exclusions
narrow and explain why the value is safe. Revoke and rotate any real leaked
credential before removing it; deleting it from the current file does not
remove it from Git history. Keep real credentials in the ignored `.env` file
or environment variables.

## Initial stable release and migration

The initial stable release is **1.0.0**. This release changes the pre-release
SDK's authentication contract: replace `.apiKey("Bearer \(apiKey)")` with
`.bearer(apiKey)`, and remove the prefix from named `BearerAuth` credentials.
STT now requires an explicit body, and its body enum includes `.json`; update
exhaustive body switches accordingly. These changes require caller migration.

Both Pulse and Pulse Pro accept audio URLs:

```swift
let response = try await client.speechToText_transcribe(.init(
    query: .init(model: .pulse, language: .en),
    body: .json(.init(url: "https://example.com/audio.wav"))
))
```

`TranscriptionResponse.diarization_segments` exposes Pulse speaker turns when
`diarize=true`. Pulse also returns words and utterances with diarization alone.
Pulse Pro accepted but ignored `diarize` and `keywords` in the 2026-10-25 captures.
Pass an explicit language for predictable behavior: Pulse Pro defaulted to `en`,
while Pulse omission returned `LANGUAGE_NOT_ENABLED_IN_REGION` in `ap-south-1`.
The individual `gu`, `mr`, `bn`, and `or` language values remain unverified and
are intentionally absent from the enum; no live verification was run for this release.

`Servers.Server1` retains `https://api.smallest.ai`. Use `Servers.Server2` for
Oregon (`https://api.us.smallest.ai`) or `Servers.Server3` for Mumbai
(`https://api.india.smallest.ai`). Mint and use access tokens in the same region.
The scheme accepts tokens only on routes documented by `auth_create_access_token`;
use an API key to mint tokens and for administrative routes.

The manifest retains `swift-openapi-generator` as a development-tool dependency:
`make generate` and the bootstrapper both invoke it through `swift run`.
UsefulThings and its branch dependency have been removed.

Offline response tests load unedited TranscriptionKit captures with provenance in
`Tests/SmallestAIAPITypesTests/Resources/README.md`. The acknowledgement fixture is
identified separately as a synthetic OpenAPI example. Run the complete offline
verification with:

```sh
swift build
swift test --filter 'AuthenticationTests|FactoryTests|ResponseDecodingTests|RequestSerializationTests'
```

## Live transcription example

Set `SMALLESTAI_API_KEY` (or `API_KEY`) in the process environment, without a
`Bearer` prefix. Place `60s_speech.wav` at the package root, then explicitly opt in:

```sh
RUN_LIVE_TESTS=1 swift test --filter transcribeSpeechFile
```

The test loads the WAV with `Data(contentsOf:)`, wraps it in `HTTPBody`, and sends
it to STT with `model=pulse-pro`, `language=en`, and `word_timestamps=true`.
It keeps the 120-second timeout, checks for a nonempty transcription, and prints
response fields. This makes a real, billable request and is skipped unless both
the explicit live gate and an environment credential are supplied. It does not
read `.env` files.
