from fastapi import APIRouter, HTTPException
import db
from api.config import generate_ai_content
from api.schemas import (
    LibraryExploreRequest,
    LibraryQuestionRequest,
    AartiRequest,
    MantraRequest,
    KathaRequest
)

router = APIRouter(prefix="/wisdom", tags=["Sacred Wisdom & Chanting"])

@router.post("/library/explore")
def explore_scripture(req: LibraryExploreRequest):
    """
    Explores an ancient Hindu scripture with structure, core message, and famous verses.
    """
    try:
        prompt = f"""
        You are an expert Hindu scholar and spiritual guide.
        The user has selected the '{req.category}' text: '{req.book_name}'.
        
        Provide a comprehensive, inspiring, and beautiful overview of this text formatted cleanly in Markdown:
        1. **Introduction & Historical Context**: What is this text, when was it composed, and who is the traditional author/seer (Rishi)?
        2. **Core Philosophy & Central Message**: What are the main spiritual or philosophical teachings?
        3. **Key Themes / Structure**: How is the book divided (e.g. Chapters, Cantos, Mandalas)?
        4. **Famous Quote / Shloka**: Provide one iconic verse in original Sanskrit (Devanagari) along with its translation and profound meaning.
        5. **Relevance in Modern Life**: How can someone apply its wisdom today?
        
        Please provide the response strictly in {req.language or 'English'}.
        """
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_library", req.book_name, result)
            
        return {
            "status": "success",
            "category": req.category,
            "book_name": req.book_name,
            "content": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/library/ask")
def ask_scripture(req: LibraryQuestionRequest):
    """
    Answers a specific user question grounded in a specific scripture text.
    """
    try:
        prompt = f"""
        You are an expert Hindu scholar. Based on the sacred text '{req.book_name}', please answer:
        
        Question: '{req.question}'
        
        Format your response cleanly in Markdown:
        - Cite specific chapters, cantos, or verses from '{req.book_name}' where this is addressed.
        - Explain the contextual and philosophical meaning clearly.
        - Conclude with practical takeaway wisdom.
        
        Please answer strictly in {req.language or 'English'}.
        """
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_library", f"{req.book_name}: {req.question}", result)
            
        return {
            "status": "success",
            "book_name": req.book_name,
            "question": req.question,
            "answer": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/aarti")
def fetch_aarti(req: AartiRequest):
    """
    Fetches traditional Aarti lyrics and significance for a Deity.
    """
    try:
        prompt = f"""
        You are an expert Hindu scholar.
        Please provide the traditional Aarti for '{req.deity_name}'.
        
        Format the output using Markdown:
        - Provide the Aarti lyrics beautifully formatted with line breaks in original Devanagari script.
        - Provide the English transliteration for non-Hindi speakers.
        - Provide the verse-by-verse translation and philosophical meaning.
        - Briefly explain the spiritual significance of this Aarti at the end.
        
        Please provide the translation and significance strictly in {req.language or 'English'}.
        """
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_aarti", req.deity_name, result)
            
        return {
            "status": "success",
            "deity_name": req.deity_name,
            "content": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/mantra")
def fetch_mantra(req: MantraRequest):
    """
    Fetches Vedic Mantra with Devanagari script, transliteration, pronunciation guide, and meaning.
    """
    try:
        prompt = f"""
        You are an expert Sanskrit scholar and Hindu Purohit.
        Please provide the '{req.mantra_name}'.
        
        Format the output exactly with these clear sections:
        
        ### Devanagari Script
        (Provide the mantra in original Sanskrit Devanagari script)
        
        ### English Transliteration & Pronunciation
        (Provide the English transliteration with syllable breaks for accurate phonetic chanting)
        
        ### Word-by-Word Meaning
        (Provide breakdown of key Sanskrit roots and words)
        
        ### Overall Meaning & Spiritual Benefits
        (Provide a concise translation and explanation of its benefits and ideal chanting rules)
        
        Please provide the translation and meaning strictly in {req.language or 'English'}, while keeping the Devanagari script authentic.
        """
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_mantra", req.mantra_name, result)
            
        return {
            "status": "success",
            "mantra_name": req.mantra_name,
            "content": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/katha")
def generate_katha(req: KathaRequest):
    """
    Generates Pauranik Katha with origin, narrative, and moral lessons.
    """
    try:
        prompt = f"Act as a knowledgeable Hindu storyteller (Kathavachak). Tell me the detailed story about: '{req.topic}'. "
        if req.source and req.source != "Any":
            prompt += f"Base the story on the {req.source} if applicable. "
        prompt += f"Provide the response in {req.language or 'English'}. Structure it beautifully with these sections: 1. Origin/Background, 2. The Main Story, 3. Moral & Spiritual Takeaway."
        
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_katha", req.topic, result)
            
        return {
            "status": "success",
            "topic": req.topic,
            "source": req.source,
            "katha": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
