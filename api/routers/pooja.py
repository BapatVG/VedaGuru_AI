from fastapi import APIRouter, HTTPException, Response
from fastapi.responses import StreamingResponse
import io
import db
from api.config import generate_ai_content, text_to_audio_bytes
from api.schemas import SamagriRequest, PoojaGuidanceRequest, MasterPlanRequest, PDFReportRequest
import pdf_engine

router = APIRouter(prefix="/pooja", tags=["Pooja & Ritual Engine"])

@router.post("/master-plan")
def generate_master_plan(req: MasterPlanRequest):
    """
    Unified 3-in-1 Master Pooja Planner: Muhurat + Samagri + Vidhi.
    """
    try:
        loc_str = f" for {req.devotee_name} in {req.location}" if req.location else ""
        prompt = f"""
        You are an expert Hindu Purohit and Vedic Astrologer.
        Please provide a comprehensive Master Plan for the '{req.pooja_name}' according to '{req.region}' traditions.
        The event is planned between {req.start_date} and {req.end_date}{loc_str}.
        
        Format the output using Markdown with the following clearly defined sections:
        
        # Master Pooja Plan: {req.pooja_name}
        
        ## 1. Auspicious Timings (Muhurat)
        Suggest the best dates and specific time windows within the given range. Briefly explain the astrological reasoning.
        
        ## 2. Comprehensive Samagri List
        List all essential sacred items categorized (e.g. Basic Setup, Offerings, Havan items if applicable) with realistic quantities.
        
        ## 3. Step-by-Step Pooja Vidhi (Procedure)
        Provide an ordered sequence of ritual steps with short Sanskrit mantras (with simple pronunciation guides) and actions for the devotee.
        
        ## 4. Key Do's and Don'ts
        Provide 3-4 vital cultural and spiritual tips for this ceremony.
        
        Please provide the entire response strictly in {req.language or 'English'}.
        """
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_master", f"{req.pooja_name} ({req.region})", result)
            
        return {
            "status": "success",
            "pooja_name": req.pooja_name,
            "devotee_name": req.devotee_name,
            "region": req.region,
            "master_plan": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/samagri")
def generate_samagri(req: SamagriRequest):
    try:
        prompt = f"""
        You are an expert Hindu Purohit (Priest) with deep knowledge of Vedas, Agamas, and regional traditions.
        Please provide a comprehensive and accurate Samagri (items) checklist required for performing the '{req.pooja_name}' according to '{req.region}' traditions for approximately {req.people_count} attendees.
        
        Format the output cleanly in markdown:
        - Categorize items (e.g., Idols/Pictures, Basic Pooja Items, Offerings/Prasad, Havan Kund items if applicable, etc.)
        - Include estimated quantities.
        - Briefly explain the significance of 1 or 2 unique items for this specific tradition.
        
        Please provide the entire response strictly in {req.language or 'English'}.
        """
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_samagri", f"{req.pooja_name} ({req.region})", result)
            
        return {
            "status": "success",
            "pooja_name": req.pooja_name,
            "region": req.region,
            "language": req.language,
            "samagri_list": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/guidance")
def generate_pooja_guidance(req: PoojaGuidanceRequest):
    try:
        prompt = f"""
        You are an expert Hindu Purohit (Priest). 
        Provide a detailed, step-by-step Vidhi (procedure) to perform the '{req.pooja_name}' according to '{req.region}' traditions.
        
        Format the output using Markdown:
        - Break the ritual down into logical, numbered steps (e.g., 1. Sankalpa, 2. Ganesh Pujan, 3. Kalash Sthapana, etc.).
        - For each step, provide a brief explanation of what actions the priest and devotee must take.
        - If a specific short mantra is commonly chanted during a step, include it in Sanskrit with pronunciation.
        
        Please provide the entire response strictly in {req.language or 'English'}.
        """
        vidhi = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_guidance", f"{req.pooja_name} ({req.region})", vidhi)
            
        return {
            "status": "success",
            "pooja_name": req.pooja_name,
            "region": req.region,
            "language": req.language,
            "vidhi": vidhi
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/audio")
def get_audio_stream(text: str, lang: str = "hi"):
    """
    Generates TTS audio stream for ritual mantras or guidance.
    """
    try:
        audio_data = text_to_audio_bytes(text=text, lang=lang)
        return StreamingResponse(
            io.BytesIO(audio_data),
            media_type="audio/mpeg",
            headers={"Content-Disposition": "inline; filename=ritual_audio.mp3"}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/pdf-report")
def export_pdf_report(req: PDFReportRequest):
    """
    Generates a stylized VedaGuru PDF report.
    """
    try:
        pdf_bytes = pdf_engine.create_pdf(
            title=req.title,
            content=req.content,
            language=req.language or "English",
            subtitle=req.subtitle or ""
        )
        safe_filename = "".join(c for c in req.title if c.isalnum() or c in (' ', '_', '-')).strip().replace(' ', '_')
        if not safe_filename:
            safe_filename = "VedaGuru_Report"
        return Response(
            content=pdf_bytes,
            media_type="application/pdf",
            headers={
                "Content-Disposition": f'attachment; filename="{safe_filename}.pdf"',
                "Access-Control-Expose-Headers": "Content-Disposition"
            }
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
