from fastapi import APIRouter, HTTPException
import db
from api.config import generate_ai_content
from api.schemas import (
    VratMealRequest,
    PrasadRecipeRequest,
    RecipeAskRequest,
    ChatMessageRequest,
    ChantingLogRequest,
    VastuRequest,
    TirthRequest
)

router = APIRouter(prefix="/lifestyle", tags=["Sacred Lifestyle & Wellness"])

@router.post("/annapurna/vrat")
def generate_vrat_meal(req: VratMealRequest):
    """
    Generates strict fasting (Vrat) meal plan and rules.
    """
    try:
        prompt = f"""
        You are an expert in Ayurvedic and Vedic Sattvic cooking.
        Provide a traditional, strict fasting (Vrat) recipe suitable for '{req.vrat_type}'.
        
        Format strictly in Markdown:
        - **Spiritual Significance**: Why is this specific food eaten during {req.vrat_type}? What ingredients are strictly forbidden (e.g. grains, onion, garlic, table salt)?
        - **Ingredients**: Detailed list with measurements and allowed fasting ingredients (e.g., Sendha Namak, Kuttu, Sabudana, Samak rice).
        - **Step-by-Step Procedure**: Clear cooking instructions with temperature/timing tips.
        - **Ayurvedic Nutritional Value**: How it balances the Doshas during fasting.
        
        Please provide the entire response strictly in {req.language or 'English'}.
        """
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_annapurna", f"Vrat: {req.vrat_type}", result)
            
        return {
            "status": "success",
            "vrat_type": req.vrat_type,
            "meal_plan": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/annapurna/prasad")
def generate_prasad_recipe(req: PrasadRecipeRequest):
    """
    Generates sacred temple-style deity prasad recipe.
    """
    try:
        prompt = f"""
        You are an expert in ancient Hindu temple cooking (Madapalli) and regional traditions.
        Provide the most beloved and traditional Prasad recipe for '{req.deity_name}' according to '{req.region}' traditions.
        
        Format strictly in Markdown:
        - **Recipe Name & Tradition**: (e.g., Panchamrit, Tirupati Laddu, Modak, Mahaprasad Khichdi)
        - **Sacred Significance**: Why this bhog is especially dear to {req.deity_name}.
        - **Pure Sattvic Ingredients**: Exact list with measurements (pure desi ghee, jaggery/sugar, cardamom, tulsi if applicable).
        - **Cooking Steps**: Holy, meditative preparation steps.
        - **Offering Vidhi**: Simple mantra to recite while offering naivedya to the deity.
        
        Please provide the entire response strictly in {req.language or 'English'}.
        """
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_annapurna", f"Prasad: {req.deity_name} ({req.region})", result)
            
        return {
            "status": "success",
            "deity_name": req.deity_name,
            "region": req.region,
            "recipe": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/annapurna/ask")
def ask_recipe_question(req: RecipeAskRequest):
    """
    Answers questions about substitutions or rules for a specific recipe.
    """
    try:
        prompt = f"""
        You are an expert Vedic chef and spiritual guide. 
        The user is currently preparing the following recipe:
        ---
        {req.recipe_context}
        ---
        The user has this question: "{req.question}"
        
        Provide a helpful, polite, and practical response regarding Sattvic cooking guidelines, ingredient substitutions, or techniques.
        Please respond strictly in {req.language or 'English'}.
        """
        result = generate_ai_content(prompt=prompt)
        return {
            "status": "success",
            "answer": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/ayurveda/chat")
def chat_ayurveda(req: ChatMessageRequest):
    """
    Interactive Ayurvedic counselor with persistent chat history.
    """
    try:
        # Load conversation history from DB
        history = db.get_chat_history(req.username, 'ayurveda')
        
        # Save user message
        db.save_chat_message(req.username, 'ayurveda', 'user', req.message)
        
        # Build prompt context
        formatted_history = ""
        for msg in history[-8:]:
            formatted_history += f"{msg['role'].capitalize()}: {msg['content']}\n"
            
        prompt = f"""
        You are an authentic Ayurvedic Doctor (Vaidya) and Wellness Consultant.
        You assist devotees in understanding their Dosha (Vata, Pitta, Kapha), Prakriti, Dinacharya (daily routine), Ritucharya (seasonal routine), and natural herbal remedies.
        
        Previous conversation:
        {formatted_history}
        User: {req.message}
        
        Provide a wise, compassionate, and practical Ayurvedic response in {req.language or 'English'}. Always include a gentle disclaimer to consult a certified Vaidya for acute medical conditions.
        """
        bot_response = generate_ai_content(prompt=prompt)
        
        # Save assistant message
        db.save_chat_message(req.username, 'ayurveda', 'assistant', bot_response)
        
        return {
            "status": "success",
            "username": req.username,
            "response": bot_response
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/ayurveda/history/{username}")
def get_ayurveda_history(username: str):
    try:
        msgs = db.get_chat_history(username, 'ayurveda')
        return {"status": "success", "history": msgs}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/ayurveda/history/{username}")
def clear_ayurveda_history(username: str):
    try:
        db.clear_chat_history(username, 'ayurveda')
        return {"status": "success", "message": "Ayurveda conversation cleared"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/chanting/log")
def log_chanting_session(req: ChantingLogRequest):
    """
    Logs completed Japa Mala chanting session.
    """
    try:
        db.log_history(
            req.username,
            "mod_chanting",
            req.chant_name,
            f"Completed {req.count} Japa chants session."
        )
        return {
            "status": "success",
            "message": f"Chanting session of {req.chant_name} ({req.count} beads) recorded successfully."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/vastu")
def analyze_vastu(req: VastuRequest):
    """
    Analyzes home layout directions based on Vastu Shastra.
    """
    try:
        prompt = f"""
        Act as an expert Vastu Shastra consultant. Analyze this home layout:
        - Main Door Direction: {req.main_door}
        - Kitchen Location: {req.kitchen}
        - Master Bedroom Location: {req.bedroom}
        - Pooja Room Location: {req.pooja_room}
        - Additional Details: {req.other_details or 'Standard residential apartment/house'}
        
        Provide the response strictly in {req.language or 'English'}.
        Structure the response cleanly with these sections:
        1. **Vastu Compliance Score**: An overall score out of 100% with brief justification.
        2. **Positives & Auspicious Placements**: What is correctly aligned and working well.
        3. **Doshas & Energy Blockages**: Identifiable flaws and potential impacts on health, peace, or wealth.
        4. **Easy Non-Structural Remedies**: Practical adjustments (e.g. Swastika, Copper wire, mirrors, lighting, specific indoor plants, color schemes).
        """
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_vastu", f"Door: {req.main_door}, Kitchen: {req.kitchen}", result)
            
        return {
            "status": "success",
            "analysis": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/tirth")
def plan_tirth_yatra(req: TirthRequest):
    """
    Plans sacred pilgrimage (Tirth Yatra) itinerary and rituals.
    """
    try:
        prompt = f"""
        Act as an expert Hindu Pilgrimage (Tirth Yatra) planner.
        Create a {req.days}-day comprehensive spiritual itinerary starting from '{req.start_city}' to '{req.destination}' for {req.people_count} travelers.
        
        Provide the response strictly in {req.language or 'English'}.
        Structure it beautifully:
        1. **Journey Overview & Sacred Significance**: History of the Tirth Kshetra and ideal season to visit.
        2. **Day-by-Day Itinerary**: Morning to evening schedule including temple darshan, special pujas, and local travel tips.
        3. **Essential Rituals & Customs**: Snan (holy bath), Sankalpa, dress codes, and temple etiquette.
        4. **Practical Guidance**: Pure vegetarian/Sattvic dining tips and accommodations.
        """
        result = generate_ai_content(prompt=prompt)
        if req.username:
            db.log_history(req.username, "mod_tirth", f"{req.start_city} to {req.destination}", result)
            
        return {
            "status": "success",
            "itinerary": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
