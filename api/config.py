import os
import io
from dotenv import load_dotenv
from google import genai
from google.genai import types
from gtts import gTTS

# Load environment variables
load_dotenv()

API_KEY = os.getenv("GEMINI_API_KEY")

if API_KEY:
    gemini_client = genai.Client(
        api_key=API_KEY,
        http_options=types.HttpOptions(
            retry_options=types.HttpRetryOptions(attempts=1),
            timeout=60000
        )
    )
else:
    gemini_client = None

def generate_ai_content(prompt: str = None, contents=None) -> str:
    """
    Calls Gemini API with automated fallback across available models.
    """
    if not gemini_client:
        raise RuntimeError("GEMINI_API_KEY is not configured in .env")

    models_to_try = [
        'gemini-3.1-flash-lite',
        'gemini-3.5-flash',
        'gemini-3.5-flash-lite',
        'gemini-3-flash-preview',
        'gemini-2.5-flash',
        'gemini-flash-latest',
        'gemini-pro-latest'
    ]

    content_to_send = contents if contents is not None else prompt
    last_error = None

    for model_name in models_to_try:
        try:
            res = gemini_client.models.generate_content(
                model=model_name,
                contents=content_to_send,
            )
            if res and res.text:
                return res.text
        except Exception as inner_e:
            last_error = inner_e
            err_str = str(inner_e).lower()
            if any(code in err_str for code in ["503", "429", "504", "404", "not found", "resource_exhausted", "unavailable"]):
                continue
            else:
                raise inner_e

    if last_error:
        raise last_error

    return "No response generated."

def text_to_audio_bytes(text: str, lang: str = 'hi') -> bytes:
    """
    Converts text to speech audio bytes using gTTS.
    """
    tts = gTTS(text=text, lang=lang)
    fp = io.BytesIO()
    tts.write_to_fp(fp)
    return fp.getvalue()
