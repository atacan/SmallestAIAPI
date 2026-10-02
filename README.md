# SmallestAIAPI

Swift package generated from `original_openapi.json` using
[swift-openapi-bootstrapper](https://github.com/atacan/swift-package-generator-based-on-openapi).

The package provides two libraries: `SmallestAIAPITypes` for API models and
`SmallestAIAPI` for the generated client. It supports macOS 13, iOS 16,
tvOS 16, and watchOS 9 or later.

```sh
make regenerate # Transform the original specification and generate Swift sources (requires uv)
make generate   # Generate Swift sources from the transformed openapi.json
swift build
swift test
```

Keep `original_openapi.json` as the source specification. Add manual schema fixes
to `openapi-overlay.json`, then run `make regenerate`. Generated files under
`Sources/*/GeneratedSources` and `openapi.json` are replaced during regeneration.
