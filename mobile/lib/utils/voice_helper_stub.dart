class VoiceHelper {
  static bool get isSpeechRecognitionSupported => false;
  static bool get isSpeechSynthesisSupported => false;
  static bool get isSpeaking => false;

  static void startListening({
    required String language,
    required void Function(String text, bool isFinal) onResult,
    required void Function(bool isListening) onStatusChange,
    void Function(String error)? onError,
  }) {
    onError?.call("Voice recognition is not supported on this platform.");
  }

  static void stopListening() {}

  static void speakText({
    required String text,
    required String language,
    void Function()? onStart,
    void Function()? onComplete,
    void Function(String error)? onError,
  }) {
    onError?.call("Voice readout is not supported on this platform.");
  }

  static void stopSpeaking() {}
}
