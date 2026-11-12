from fastapi import APIRouter, HTTPException
import db
from api.config import generate_ai_content
from api.schemas import KundaliRequest, MatchmakingRequest, RashichakraRequest
try:
    from geopy.geocoders import Nominatim
    geolocator = Nominatim(user_agent="vedaguru_app_api")
except ImportError:
    geolocator = None

router = APIRouter(prefix="/astrology", tags=["Astrology & Jyotish Engine"])

def _safe_geocode(city_name: str):
    """
    Safely resolves coordinates for a city.
    """
    if not geolocator:
        return None, None, city_name
    try:
        loc = geolocator.geocode(city_name, timeout=5)
        if loc:
            return loc.latitude, loc.longitude, loc.address
    except Exception:
        pass
    return None, None, city_name

@router.post("/kundali")
def generate_kundali(req: KundaliRequest):
    """
    Calculates and interprets Vedic Birth Chart (Kundali).
    """
    try:
        lat, lon, resolved_address = _safe_geocode(req.birth_city)
        coord_str = f"Coordinates: Latitude {lat:.2f}, Longitude {lon:.2f}" if lat and lon else f"Place: {resolved_address}"
        
        prompt = f"""
        You are an expert Vedic Astrologer (Jyotishi). Calculate and interpret the Vedic Birth Chart (Kundali) for the following native:
        
        **Name:** {req.native_name}
        **Date of Birth:** {req.birth_date}
        **Time of Birth:** {req.birth_time}
        **Place of Birth:** {resolved_address}
        {coord_str}
        
        The user has requested a '{req.analysis_type}' reading.
        
        Format your response cleanly in Markdown:
        1. **Astrological Summary**: Identify the likely Ascendant (Lagna), Sun sign, Moon sign (Rashi), and Janma Nakshatra.
        2. **Planetary Placements & Houses**: Key planet positions and significance for {req.analysis_type}.
        3. **Major Influences & Doshas**: Examine Manglik Dosha, Sade Sati phase, or any other astrological factor.
        4. **Practical Guidance & Remedies**: Favorable mantras, auspicious gemstones, charitable remedies (*Daan*), and lifestyle suggestions.
        
        Please provide the entire reading strictly in {req.language or 'English'}.
        """
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_kundali", f"{req.native_name} - {req.analysis_type}", result)
            
        return {
            "status": "success",
            "native_name": req.native_name,
            "resolved_location": resolved_address,
            "latitude": lat,
            "longitude": lon,
            "reading": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/matchmaking")
def generate_matchmaking(req: MatchmakingRequest):
    """
    Generates 36-point Ashtakoot Guna Milan & Kundali Compatibility.
    """
    try:
        b_lat, b_lon, b_address = _safe_geocode(req.boy_city)
        g_lat, g_lon, g_address = _safe_geocode(req.girl_city)
        
        prompt = f"""
        You are an expert Vedic Astrologer (Jyotishi) specializing in Ashtakoot Guna Milan (Matchmaking).
        Calculate and interpret the compatibility based on the following exact birth details:
        
        **Boy's Details:**
        - Name: {req.boy_name}
        - Date of Birth: {req.boy_dob}
        - Time of Birth: {req.boy_tob}
        - Place of Birth: {b_address}
        
        **Girl's Details:**
        - Name: {req.girl_name}
        - Date of Birth: {req.girl_dob}
        - Time of Birth: {req.girl_tob}
        - Place of Birth: {g_address}
        
        Format the response cleanly in Markdown:
        1. **Ashtakoot Guna Milan Breakdown**:
           - Show points scored out of 36 (Varna, Vashya, Tara, Yoni, Graha Maitri, Gana, Bhakoot, Nadi).
           - State the Total Score (e.g. 26/36) and its general compatibility tier.
        2. **Manglik Dosha Assessment**: Check whether either partner has Mangal Dosha and whether cancellation (*Bhanga*) applies.
        3. **Mental & Emotional Harmony**: Spiritual alignment, longevity, and family prosperity analysis.
        4. **Remedies & Recommendations**: Simple Vedic remedies if any specific Koota has low points.
        
        Please provide the entire report strictly in {req.language or 'English'}.
        """
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_matchmaking", f"{req.boy_name} & {req.girl_name}", result)
            
        return {
            "status": "success",
            "boy_name": req.boy_name,
            "girl_name": req.girl_name,
            "report": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/rashichakra")
def explore_rashichakra(req: RashichakraRequest):
    """
    Provides deep Astrological and Spiritual profile for a Zodiac Sign (Rashi).
    """
    try:
        prompt = f"""
        Provide a detailed Astrological and Spiritual profile for the Zodiac Sign: {req.rashi_name}.
        
        The response must be beautifully formatted in Markdown and must include the following sections exactly:
        
        ### 🌌 Rashi Overview
        (Brief 2-3 line overview of the sign's nature, element, and quality)
        
        ### 🙏 Blessed Deity (Ishta Devata)
        (Which God or Goddess is blessed for this Zodiac Sign and why)
        
        ### 💎 Recommended Crystal (Ratna)
        (Which gemstone or crystal is suitable for this sign and its primary benefits)
        
        ### 🌿 Auspicious Plant (Aaradhya Vriksha)
        (Which sacred tree or plant the native should plant and nurture based on their sign)
        
        ### ✨ Astrological Essentials
        - **Ruling Planet (Swami Graha):** (Name of the planet)
        - **Lucky Colors & Numbers:** (e.g., Saffron, Yellow; 1, 9)
        - **Suitable Rudraksha:** (e.g., 3 Mukhi, 5 Mukhi)
        - **Daily Beej Mantra:** (A short, authentic mantra in Devanagari & transliteration)
        
        ### 📊 Conclusion Summary Table
        (Provide a clean Markdown table summarizing: Rashi, Ruling Planet, Deity, Gemstone, Tree, Lucky Colors)
        
        Please provide the explanations in {req.language or 'English'}, keeping mantras in authentic Sanskrit.
        """
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_rashichakra", req.rashi_name, result)
            
        return {
            "status": "success",
            "rashi_name": req.rashi_name,
            "profile": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
