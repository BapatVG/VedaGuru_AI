import datetime
import json
from fastapi import APIRouter, HTTPException
import db
from api.config import generate_ai_content
from api.schemas import MuhuratRequest, LivePanchangRequest, UpcomingFestivalsRequest

router = APIRouter(prefix="/panchang", tags=["Panchang & Muhurat"])

@router.post("/muhurat")
def find_muhurat(req: MuhuratRequest):
    try:
        loc_str = f" in {req.location}" if req.location else ""
        prompt = f"""
        You are an expert Vedic Astrologer (Jyotishi) with deep knowledge of Panchang, Tithi, Nakshatra, and Muhurat calculations.
        Please suggest auspicious dates and specific timings (Muhurat) for the event '{req.event_type}' around the date {req.target_date}{loc_str}.
        
        Format your response beautifully in Markdown:
        - List the best auspicious dates.
        - For each date, provide the specific auspicious time window (e.g., Abhijit Muhurat, Amrit Kaal).
        - Briefly explain the astrological reasoning (Nakshatra, Tithi, or Yoga).
        - List any inauspicious times (Rahu Kaal, Yamaganda) to avoid.
        
        Please provide the entire response strictly in {req.language or 'English'}.
        """
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_muhurat", f"{req.event_type} - {req.target_date}", result)
            
        return {
            "status": "success",
            "event_type": req.event_type,
            "target_date": req.target_date,
            "location": req.location,
            "muhurat_details": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/live")
def get_live_panchang(req: LivePanchangRequest):
    """
    Returns real-time Panchang details (Tithi, Nakshatra, Rahu Kaal, Yamaganda, Status) for a location.
    """
    try:
        now = datetime.datetime.now()
        current_dt_str = now.strftime("%Y-%m-%d %H:%M:%S")
        prompt = f"""
        You are an expert Vedic Astrologer. Calculate the Hindu Panchang for the following location and exact time:
        Location: {req.location}
        Current Date and Time: {current_dt_str}
        Language: {req.language or 'English'}
        
        Provide the output strictly as a JSON object with the following keys, and no other text or markdown formatting (do not wrap in ```json). 
        All descriptions, tithi names, and status must be translated into {req.language or 'English'}:
        {{
            "tithi": "Current Tithi (e.g. Shukla Paksha Ekadashi)",
            "nakshatra": "Current Nakshatra (e.g. Rohini)",
            "rahu_kaal": "Today's Rahu Kaal timing (e.g. 16:30 - 18:00)",
            "yamaganda": "Today's Yamaganda timing (e.g. 12:00 - 13:30)",
            "status": "Brief Auspicious Status (e.g. Good for new beginnings, Avoid travel)"
        }}
        """
        raw_text = generate_ai_content(prompt=prompt).strip()
        if raw_text.startswith("```json"):
            raw_text = raw_text[7:-3]
        elif raw_text.startswith("```"):
            raw_text = raw_text[3:-3]
            
        panchang_data = json.loads(raw_text.strip())
        return {
            "status": "success",
            "location": req.location,
            "datetime": current_dt_str,
            "panchang": panchang_data
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/festivals")
def get_upcoming_festivals(req: UpcomingFestivalsRequest):
    """
    Returns the top upcoming Hindu festivals or vrats in the next 30 days for a given city.
    """
    try:
        now = datetime.datetime.now()
        prompt = f"""
        You are an expert Vedic Astrologer. Based on the current date {now.strftime('%Y-%m-%d')} and location '{req.location}', 
        list the 4 most important upcoming Hindu festivals or Vrats (like Ekadashi, Pradosh, Purnima, Amavasya, or major Utsavs) occurring in the next 30 days.
        Provide the response strictly in {req.language or 'English'} with translated festival names and descriptions.
        
        Format the output strictly as a JSON array of objects (no markdown wrappers like ```json). 
        Each object must have:
        - "date": "The date (e.g. 24 July 2026)"
        - "name": "Name of Festival/Vrat in {req.language or 'English'}"
        - "desc": "One short sentence about its significance in {req.language or 'English'}"
        - "type": "Either 'Festival' or 'Vrat'"
        """
        raw_text = generate_ai_content(prompt=prompt).strip()
        if raw_text.startswith("```json"):
            raw_text = raw_text[7:-3]
        elif raw_text.startswith("```"):
            raw_text = raw_text[3:-3]
            
        festivals = json.loads(raw_text.strip())
        return {
            "status": "success",
            "location": req.location,
            "festivals": festivals
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/daily-wisdom")
def get_daily_wisdom(language: str = "English"):
    """
    Returns a short inspiring Vedic quote or Mantra for the day.
    """
    try:
        wisdom_prompt = f"Provide a single, very short inspiring Vedic quote or Mantra (with meaning) to start the day. Output directly without any intro. Language: {language}"
        quote = generate_ai_content(prompt=wisdom_prompt).strip()
        return {
            "status": "success",
            "wisdom": quote
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
