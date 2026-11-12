from fastapi import APIRouter, HTTPException, Query
import db
from api.config import generate_ai_content
from api.schemas import ChatMessageRequest

router = APIRouter(prefix="/chat", tags=["Ritual Knowledge Chatbot"])

RITUAL_SYSTEM_PROMPT = """You are VedaGuru AI, an authentic, highly knowledgeable, and respectful Vedic assistant and digital Purohit guide.
You specialize in Sanatana Dharma rituals, Pooja Vidhi, Mantras, Muhurats, Samagri requirements, and Vedic cultural guidance.
Always answer with reverence, clarity, and accuracy according to Vedic tradition.
Respond in the language requested: {language}.
"""

@router.post("/ask")
def ask_ritual_question(req: ChatMessageRequest):
    try:
        # Fetch previous recent conversation for context if available
        past_msgs = db.get_chat_history(req.username, bot_type="ritual_chat")
        
        # Build prompt with conversation history context
        history_context = ""
        if past_msgs:
            recent_turns = past_msgs[-6:]  # last 3 turns
            for item in recent_turns:
                if isinstance(item, dict):
                    role = item.get("role", "user")
                    text = item.get("content", "")
                elif isinstance(item, (list, tuple)):
                    role = item[0]
                    text = item[1]
                else:
                    continue
                history_context += f"{str(role).capitalize()}: {text}\n"

        prompt = f"""{RITUAL_SYSTEM_PROMPT.format(language=req.language or 'English')}

Recent Conversation History:
{history_context}

User's New Question: {req.message}

Please provide an authentic, structured, and insightful response:"""

        reply = generate_ai_content(prompt=prompt)
        
        # Save to chat memory
        db.save_chat_message(req.username, "ritual_chat", "user", req.message)
        db.save_chat_message(req.username, "ritual_chat", "assistant", reply)
        
        # Log to general user history
        db.log_history(req.username, req.module_name or "Ritual Knowledge Chatbot", req.message, reply)

        return {
            "status": "success",
            "reply": reply,
            "username": req.username
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/history/{username}")
def get_user_chat_history(username: str, bot_type: str = Query("ritual_chat")):
    try:
        history = db.get_chat_history(username, bot_type=bot_type)
        formatted = []
        for item in history:
            if isinstance(item, dict):
                formatted.append({
                    "role": item.get("role", "user"),
                    "content": item.get("content", ""),
                    "timestamp": item.get("timestamp", "")
                })
            elif isinstance(item, (list, tuple)):
                formatted.append({
                    "role": item[0],
                    "content": item[1],
                    "timestamp": item[2] if len(item) > 2 else ""
                })
        return {
            "status": "success",
            "username": username,
            "bot_type": bot_type,
            "history": formatted
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/history/{username}")
def clear_user_chat_history(username: str, bot_type: str = Query("ritual_chat")):
    try:
        db.clear_chat_history(username, bot_type=bot_type)
        return {
            "status": "success",
            "message": f"Chat history for {bot_type} cleared."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
