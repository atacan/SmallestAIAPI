// Generated from the final OpenAPI specification. Regenerated; do not edit.

internal enum OperationSecurity {
    enum Scheme: Sendable {
        case bearer
        case apiKey(header: String)
        case unsupported
    }

    static let schemes: [String: Scheme] = ["BearerAuth": .apiKey(header: "authorization")]
    static let defaultRequirements: [[String]] = []
    static let operations: [String: [[String]]] = ["auth_create_access_token": [["BearerAuth"]], "textToSpeech_synthesizeSpeech": [["BearerAuth"]], "textToSpeech_synthesizeSpeechSse": [["BearerAuth"]], "voices_getWavesVoices": [], "voiceCloning_createVoiceClone": [["BearerAuth"]], "voiceCloning_listVoiceClones": [["BearerAuth"]], "pronunciationDictionaries_getPronunciationDicts": [["BearerAuth"]], "pronunciationDictionaries_createPronunciationDict": [["BearerAuth"]], "pronunciationDictionaries_updatePronunciationDict": [["BearerAuth"]], "pronunciationDictionaries_deletePronunciationDict": [["BearerAuth"]], "speechToText_transcribe": [["BearerAuth"]], "electron_complete": [["BearerAuth"]]]
}
