// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;

class VoiceHelper {
  static bool _jsInjected = false;
  static bool _isCurrentlySpeaking = false;

  static void _ensureJsInjected() {
    if (_jsInjected && js.context.hasProperty('vedaguruVoice')) return;

    const jsCode = r'''
    (function() {
      if (window.vedaguruVoice) return;
      window.vedaguruVoice = {
        recognition: null,
        isListening: false,
        startListening: async function(lang, onResult, onStatus, onError) {
          try {
            this.stopListening();

            const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
            if (!SpeechRecognition) {
              if (onError) onError("Speech recognition is not supported in this browser. Please use Chrome, Edge, or Brave.");
              return;
            }

            // Prompt microphone permission
            if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
              try {
                const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                stream.getTracks().forEach(function(t) { t.stop(); });
              } catch (permErr) {
                console.warn("[VedaGuru Voice] Mic permission error:", permErr);
                if (onError) onError("Microphone access blocked. Please allow microphone permission in your browser address bar.");
                if (onStatus) onStatus(false);
                return;
              }
            }

            const rec = new SpeechRecognition();
            this.recognition = rec;
            rec.continuous = true;
            rec.interimResults = true;
            rec.lang = lang || 'en-IN';

            rec.onstart = function() {
              window.vedaguruVoice.isListening = true;
              if (onStatus) onStatus(true);
              console.log("[VedaGuru Voice] Listening started in:", rec.lang);
            };

            rec.onresult = function(event) {
              try {
                let finalStr = '';
                let interimStr = '';
                for (let i = 0; i < event.results.length; ++i) {
                  const res = event.results[i];
                  if (res.isFinal) {
                    finalStr += res[0].transcript;
                  } else {
                    interimStr += res[0].transcript;
                  }
                }
                const output = (finalStr + ' ' + interimStr).trim();
                if (output && onResult) {
                  console.log("[VedaGuru Voice] Recognized text:", output);
                  onResult(output, !!finalStr);
                }
              } catch (err) {
                console.error("[VedaGuru Voice] Parse error:", err);
              }
            };

            rec.onerror = function(event) {
              console.warn("[VedaGuru Voice] Error:", event.error);
              if (event.error === 'no-speech') return;
              window.vedaguruVoice.isListening = false;
              if (onStatus) onStatus(false);
              if (onError) {
                let msg = "Microphone error: " + event.error;
                if (event.error === 'not-allowed' || event.error === 'service-not-allowed') {
                  msg = "Microphone access blocked. Please allow microphone permission in your browser address bar.";
                } else if (event.error === 'audio-capture') {
                  msg = "No microphone hardware found. Please check your microphone.";
                } else if (event.error === 'network') {
                  msg = "Speech recognition network timeout. Check internet connection.";
                }
                onError(msg);
              }
            };

            rec.onend = function() {
              window.vedaguruVoice.isListening = false;
              if (onStatus) onStatus(false);
              console.log("[VedaGuru Voice] Listening stopped.");
            };

            rec.start();
          } catch (e) {
            console.error("[VedaGuru Voice] Start error:", e);
            window.vedaguruVoice.isListening = false;
            if (onStatus) onStatus(false);
            if (onError) onError(e.message || String(e));
          }
        },

        stopListening: function() {
          if (this.recognition) {
            try {
              this.recognition.stop();
            } catch (_) {}
            this.recognition = null;
          }
          this.isListening = false;
        },

        speak: function(text, lang, onStart, onEnd, onError) {
          try {
            this.stopSpeaking();
            if (!window.speechSynthesis) {
              if (onError) onError("Speech synthesis not supported.");
              return;
            }
            const utter = new SpeechSynthesisUtterance(text);
            utter.lang = lang || 'en-IN';
            utter.rate = 0.95;
            utter.pitch = 1.0;

            utter.onstart = function() {
              if (onStart) onStart();
            };
            utter.onend = function() {
              if (onEnd) onEnd();
            };
            utter.onerror = function() {
              if (onEnd) onEnd();
            };
            window.speechSynthesis.speak(utter);
          } catch (e) {
            if (onError) onError(e.message || String(e));
          }
        },

        stopSpeaking: function() {
          if (window.speechSynthesis) {
            window.speechSynthesis.cancel();
          }
        }
      };
    })();
    ''';

    try {
      final script = html.ScriptElement()..text = jsCode;
      html.document.head?.append(script);
      _jsInjected = true;
    } catch (_) {
      try {
        js.context.callMethod('eval', [jsCode]);
        _jsInjected = true;
      } catch (_) {}
    }
  }

  static bool get isSpeechRecognitionSupported {
    try {
      _ensureJsInjected();
      return js.context.hasProperty('SpeechRecognition') ||
             js.context.hasProperty('webkitSpeechRecognition') ||
             js.context.hasProperty('vedaguruVoice');
    } catch (_) {
      return false;
    }
  }

  static bool get isSpeechSynthesisSupported {
    try {
      _ensureJsInjected();
      return js.context.hasProperty('speechSynthesis');
    } catch (_) {
      return false;
    }
  }

  static bool get isSpeaking => _isCurrentlySpeaking;

  static String _resolveBcp47(String language) {
    switch (language.toLowerCase()) {
      case 'hindi':
        return 'hi-IN';
      case 'marathi':
        return 'mr-IN';
      case 'sanskrit':
        return 'hi-IN';
      case 'gujarati':
        return 'gu-IN';
      case 'bengali':
        return 'bn-IN';
      case 'tamil':
        return 'ta-IN';
      case 'telugu':
        return 'te-IN';
      case 'english':
      default:
        return 'en-IN';
    }
  }

  static void startListening({
    required String language,
    required void Function(String text, bool isFinal) onResult,
    required void Function(bool isListening) onStatusChange,
    void Function(String error)? onError,
  }) {
    try {
      _ensureJsInjected();
      final voice = js.context['vedaguruVoice'];
      if (voice != null) {
        voice.callMethod('startListening', [
          _resolveBcp47(language),
          js.allowInterop((dynamic text, dynamic isFinal) {
            if (text != null && text.toString().isNotEmpty) {
              onResult(text.toString(), isFinal == true);
            }
          }),
          js.allowInterop((dynamic isListening) {
            onStatusChange(isListening == true);
          }),
          js.allowInterop((dynamic error) {
            onStatusChange(false);
            if (error != null) {
              onError?.call(error.toString());
            }
          }),
        ]);
      } else {
        onError?.call("Voice recognition is not initialized. Please refresh the browser.");
      }
    } catch (e) {
      onStatusChange(false);
      onError?.call(e.toString());
    }
  }

  static void stopListening() {
    try {
      _ensureJsInjected();
      final voice = js.context['vedaguruVoice'];
      if (voice != null) {
        voice.callMethod('stopListening', []);
      }
    } catch (_) {}
  }

  static void speakText({
    required String text,
    required String language,
    void Function()? onStart,
    void Function()? onComplete,
    void Function(String error)? onError,
  }) {
    try {
      _ensureJsInjected();
      final clean = _sanitizeForSpeech(text);
      if (clean.isEmpty) {
        onComplete?.call();
        return;
      }
      final voice = js.context['vedaguruVoice'];
      if (voice != null) {
        _isCurrentlySpeaking = true;
        voice.callMethod('speak', [
          clean,
          _resolveBcp47(language),
          js.allowInterop((dynamic _) {
            _isCurrentlySpeaking = true;
            onStart?.call();
          }),
          js.allowInterop((dynamic _) {
            _isCurrentlySpeaking = false;
            onComplete?.call();
          }),
          js.allowInterop((dynamic error) {
            _isCurrentlySpeaking = false;
            if (error != null) {
              onError?.call(error.toString());
            }
          }),
        ]);
      } else {
        onError?.call("Speech synthesis unavailable.");
      }
    } catch (e) {
      _isCurrentlySpeaking = false;
      onError?.call(e.toString());
    }
  }

  static void stopSpeaking() {
    try {
      _ensureJsInjected();
      final voice = js.context['vedaguruVoice'];
      if (voice != null) {
        voice.callMethod('stopSpeaking', []);
      }
    } catch (_) {}
    _isCurrentlySpeaking = false;
  }

  static String _sanitizeForSpeech(String markdown) {
    var t = markdown;
    t = t.replaceAll(RegExp(r'#+\s*'), '');
    t = t.replaceAll(RegExp(r'[*_]{1,3}'), '');
    t = t.replaceAll(RegExp(r'\|'), ' ');
    t = t.replaceAll(RegExp(r'[-=]{2,}'), ' ');
    t = t.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m[1] ?? '');
    t = t.replaceAll('`', '');
    t = t.replaceAll(RegExp(r'[\u{1F300}-\u{1F6FF}|\u{1F900}-\u{1F9FF}|\u{2600}-\u{26FF}|\u{2700}-\u{27BF}]', unicode: true), '');
    t = t.replaceAll(RegExp(r'\n+'), '. ');
    t = t.replaceAll(RegExp(r'\s{2,}'), ' ');
    return t.trim();
  }
}
