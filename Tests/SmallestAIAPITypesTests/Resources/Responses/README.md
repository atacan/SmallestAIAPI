# Smallest AI response fixtures

Live captures, all unedited. The SmallestAIAPI SDK (`cf6200c`) has no response resources: its only
fixture is an inline JSON string in `ResponseDecodingTests`, written by hand, and its live test prints
fields without saving the response.

Captured on 2026-10-25 by `../../capture-fixtures.sh` from `https://api.smallest.ai` (which served
from `ap-south-1`, per the region error below), uploading `../speech.wav` (4.5 s, one speaker) as
the raw `application/octet-stream` body, as the SDK sends it, or Deepgram's florist call (11.1 s, two
speakers), uploaded the same way or fetched by Smallest AI from a `{"url": …}` JSON body. Query
parameters are encoded the way the runtime encodes them (`,` as `%2C`, `:` as `%3A`, space as
`%20`). `statuses.txt` has each request's HTTP status.

| File | Request | Returned |
| --- | --- | --- |
| `captured-pulse-pro-word.json` | `pulse-pro`, `language=en`, `word_timestamps=true` | 13 words with `confidence`, no `utterances`; `language: "en"`, `request_id`, `totalBytes`, `metadata.{duration, processing_time_ms, rtfx, num_chunks}` |
| `captured-pulse-pro-text.json` | `pulse-pro`, `language=en` | `words: []` |
| `captured-pulse-pro-no-language.json` | `pulse-pro`, no `language` | 200, `language: "en"` |
| `captured-pulse-word.json` | `pulse`, `language=en`, `word_timestamps=true` | 13 words and two utterances; no `language`, `request_id` or `totalBytes`; `metadata.{duration, fileSize}` |
| `captured-pulse-text.json` | `pulse`, `language=en` | `words: []`, `utterances: []` |
| `captured-pulse-no-language.json` | `pulse`, no `language` | 400 `LANGUAGE_NOT_ENABLED_IN_REGION`: "Language 'multi' has not been enabled in this region", `region: "ap-south-1"` |
| `captured-pulse-multi-eu.json` | `pulse`, `language=multi-eu`, `word_timestamps=true` | Words and utterances; no detected language in the response |
| `captured-pulse-language-zh.json` | `pulse`, `language=zh` | 200 (documented as US region only), English text |
| `captured-pulse-multi-indic.json` | `pulse`, `language=multi-indic` | 200 (documented as India region only) |
| `captured-pulse-diarize-word-remote.json` | `pulse`, `word_timestamps=true`, `diarize=true`, the call by URL | Words with `speaker` and `speaker_confidence`, five utterances with `speaker` (0, 1), and `diarization_segments` (speaker turns), which the SDK's type doesn't have |
| `captured-pulse-diarize-remote.json` | `diarize=true` without `word_timestamps`, by URL | The same body: diarization alone returns words and utterances |
| `captured-pulse-diarize-word.json` | `word_timestamps=true`, `diarize=true`, the call uploaded | The same body as by URL |
| `captured-pulse-pro-diarize.json` | `pulse-pro`, `word_timestamps=true`, `diarize=true`, the call uploaded | 200, words without speakers: Pro ignores `diarize` |
| `captured-pulse-url-as-octet-stream.json` | `pulse`, the URL JSON as an `application/octet-stream` body (what the SDK can send) | 400 `AudioDecodeError`, "Failed to decode audio." |
| `captured-pulse-pro-remote.json` | `pulse-pro` with a URL body | 200, transcribed: the docs say Pro takes raw bytes only |
| `captured-pulse-keywords.json` | `pulse`, `keywords=TranscriptionKit%2CSpeechall` | "TranscriptionKit" in the text |
| `captured-pulse-keywords-phrase.json` | `keywords=Transcription%20Kit%3A2%2CSpeechall` | 200, the text unchanged |
| `captured-pulse-pro-keywords.json` | `pulse-pro`, `keywords=TranscriptionKit` | 200, "Transcription Kit": Pro ignores `keywords` |
| `captured-pulse-detection.json` | `pulse`, `word_timestamps=true`, `emotion_detection=true`, `gender_detection=true` | `gender: "female"`, `emotions` with five labels |
| `captured-pulse-us-host.json` | `pulse` at `https://api.us.smallest.ai` | 200 |
| `captured-pulse-india-host.json` | `pulse` at `https://api.india.smallest.ai` | 200 |
| `captured-pulse-access-token.json` | `pulse` with an access token from `POST /waves/v1/auth/token` (`ttl_seconds: 60`, 201) | 200: the STT route accepts tokens, though the spec's security scheme says it doesn't |
| `captured-error-pulse-pro-language-de.json` | `pulse-pro`, `language=de` | 400 `{"status":"error","message":"Invalid query parameters","errors":[{"path":["language"],"message":…}]}` |
| `captured-error-unknown-model.json` | `model=pulse-9999` | 400, "Invalid model query parameter.", `errors[0].options: ["pulse","pulse-pro"]` |
| `captured-error-word-timestamps-capitalized.json` | `word_timestamps=True` | 400, `invalid_enum_value` |
| `captured-error-keywords-101.json` | 101 keywords | 400, `errors[0].message`: "keywords too large (max 100)" |
| `captured-error-empty-audio.json` | an empty body | 400, `errors` a string: "Empty request body" |
| `captured-error-401.json` | `Authorization: Bearer invalid` | 401 `{"error":"unauthorized"}` |
| `captured-error-no-auth.json` | no `Authorization` header | 401 `{"message":"Unauthorized: No tokens provided"}` |

The access token itself was kept in a temporary file and isn't in this directory.

Smallest AI's error bodies come in the three documented shapes: `{"error": …}` (a bad key),
`{"message": …}` (no key), and `{"status":"error","message": …}` with optional `errors` (an array
of `{path, message, code, …}` or a string), `error_code`, `code`, `language` and `region`. The SDK's
`SttErrorResponse` decodes all of them.
