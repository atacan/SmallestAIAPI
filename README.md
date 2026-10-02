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

## Live transcription example

Set `API_KEY` in your environment or add `API_KEY=your_actual_key` to a `.env`
file at the package root. Keep the key without a `Bearer` prefix; the test adds it.
Place `60s_speech.wav` at the package root, then run:

```sh
swift test --filter transcribeSpeechFile
```

The test streams the WAV file using UsefulThings' `FileHandle` async sequence
to `POST /waves/v1/stt/` with `model=pulse-pro`, `language=en`, and
`word_timestamps=true`. It checks for a nonempty transcription and prints every
response property with its Swift type, including every word, utterance, metadata
field, and emotion score. Missing optional values print as `nil`; some fields are
model-specific or require additional detection flags. The test makes a real,
billable request when a key is configured and is skipped otherwise.
