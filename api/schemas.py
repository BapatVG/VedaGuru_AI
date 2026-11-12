from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

# ==================== Auth Schemas ====================
class UserRegisterRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=4)
    default_region: str = "General/Standard"
    preferred_language: str = "English"
    account_type: str = "User"  # "User" or "Purohit"
    security_question: Optional[str] = ""
    security_answer: Optional[str] = ""

class UserLoginRequest(BaseModel):
    username: str
    password: str

class UserProfileUpdateRequest(BaseModel):
    username: str
    new_region: str
    new_language: str

class PasswordResetRequest(BaseModel):
    username: str
    new_password: str
    security_answer: Optional[str] = ""
    verify_region: Optional[str] = None
    verify_role: Optional[str] = None

class PasswordChangeRequest(BaseModel):
    username: str
    old_password: str
    new_password: str



# ==================== Chat Schemas ====================
class ChatMessageRequest(BaseModel):
    username: str
    message: str
    module_name: Optional[str] = "Ritual Knowledge Chatbot"
    language: Optional[str] = "English"

class ChatHistoryItem(BaseModel):
    id: int
    username: str
    module_name: str
    query_details: str
    response_text: str
    timestamp: str


# ==================== Pooja & Ritual Schemas ====================
class SamagriRequest(BaseModel):
    pooja_name: str
    region: Optional[str] = "General/Standard"
    people_count: Optional[int] = 5
    language: Optional[str] = "English"
    username: Optional[str] = None

class PoojaGuidanceRequest(BaseModel):
    pooja_name: str
    region: Optional[str] = "General/Standard"
    step_detail: Optional[str] = "Complete Detailed Vidhi"
    language: Optional[str] = "English"
    username: Optional[str] = None

class MasterPlanRequest(BaseModel):
    devotee_name: str
    location: str
    pooja_name: str
    start_date: str
    end_date: str
    region: Optional[str] = "General/Standard"
    language: Optional[str] = "English"
    username: Optional[str] = None


# ==================== Panchang & Festivals Schemas ====================
class MuhuratRequest(BaseModel):
    event_type: str
    target_date: str
    location: Optional[str] = "India"
    language: Optional[str] = "English"
    username: Optional[str] = None

class LivePanchangRequest(BaseModel):
    location: str
    language: Optional[str] = "English"

class UpcomingFestivalsRequest(BaseModel):
    location: str
    language: Optional[str] = "English"


# ==================== Wisdom & Chanting Schemas ====================
class LibraryExploreRequest(BaseModel):
    category: str
    book_name: str
    language: Optional[str] = "English"
    username: Optional[str] = None

class LibraryQuestionRequest(BaseModel):
    book_name: str
    question: str
    language: Optional[str] = "English"
    username: Optional[str] = None

class AartiRequest(BaseModel):
    deity_name: str
    language: Optional[str] = "English"
    username: Optional[str] = None

class MantraRequest(BaseModel):
    mantra_name: str
    language: Optional[str] = "English"
    username: Optional[str] = None

class KathaRequest(BaseModel):
    topic: str
    source: Optional[str] = "Any"
    language: Optional[str] = "English"
    username: Optional[str] = None


# ==================== Astrology & Horoscope Schemas ====================
class KundaliRequest(BaseModel):
    native_name: str
    birth_date: str  # YYYY-MM-DD
    birth_time: str  # HH:MM
    birth_city: str
    analysis_type: Optional[str] = "Detailed Life Horoscope"
    language: Optional[str] = "English"
    username: Optional[str] = None

class MatchmakingRequest(BaseModel):
    boy_name: str
    boy_dob: str
    boy_tob: str
    boy_city: str
    girl_name: str
    girl_dob: str
    girl_tob: str
    girl_city: str
    language: Optional[str] = "English"
    username: Optional[str] = None

class RashichakraRequest(BaseModel):
    rashi_name: str
    language: Optional[str] = "English"
    username: Optional[str] = None


# ==================== Sacred Lifestyle & Wellness Schemas ====================
class VratMealRequest(BaseModel):
    vrat_type: str
    language: Optional[str] = "English"
    username: Optional[str] = None

class PrasadRecipeRequest(BaseModel):
    deity_name: str
    region: Optional[str] = "General/Standard"
    language: Optional[str] = "English"
    username: Optional[str] = None

class RecipeAskRequest(BaseModel):
    recipe_context: str
    question: str
    language: Optional[str] = "English"

class ChantingLogRequest(BaseModel):
    username: str
    chant_name: str
    count: Optional[int] = 108

class VastuRequest(BaseModel):
    main_door: str
    kitchen: str
    bedroom: str
    pooja_room: Optional[str] = "East"
    other_details: Optional[str] = ""
    language: Optional[str] = "English"
    username: Optional[str] = None

class TirthRequest(BaseModel):
    start_city: str
    destination: str
    days: Optional[int] = 3
    people_count: Optional[int] = 2
    language: Optional[str] = "English"
    username: Optional[str] = None


# ==================== Workspace & CRM Schemas ====================
class YajmanCreateRequest(BaseModel):
    purohit_username: str
    client_name: str
    contact_number: str
    pooja_date: str
    pooja_type: str
    address: Optional[str] = "Not Provided"
    latitude: Optional[float] = 0.0
    longitude: Optional[float] = 0.0

class BookingCreateRequest(BaseModel):
    user_username: str
    pooja_type: str
    pooja_date: str
    purohit_username: Optional[str] = ""
    contact_number: Optional[str] = "Not Provided"
    address: Optional[str] = "Not Provided"
    latitude: Optional[float] = 0.0
    longitude: Optional[float] = 0.0

class BookingCompleteRequest(BaseModel):
    rating: Optional[int] = 5
    feedback: Optional[str] = ""

class BlockDateRequest(BaseModel):
    purohit_username: str
    blocked_date: str
    reason: Optional[str] = "Busy"

class YagyaBoardCreateRequest(BaseModel):
    title: str
    event_date: str
    created_by: str

class YagyaCollaboratorRequest(BaseModel):
    board_id: int
    username: str

class YagyaTaskCreateRequest(BaseModel):
    board_id: int
    task_desc: str
    assigned_to: Optional[str] = ""

class YagyaTaskStatusRequest(BaseModel):
    is_completed: bool

class CommunityVidhiCreateRequest(BaseModel):
    username: str
    title: str
    region: str
    content: str

class PDFReportRequest(BaseModel):
    title: str
    content: str
    language: Optional[str] = "English"
    subtitle: Optional[str] = ""
