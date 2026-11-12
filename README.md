# 🕉️ VedaGuru AI - Full-Stack Mobile & Web Platform

**VedaGuru AI** is an authentic, intelligent digital assistant for Sanatana Dharma rituals, Vedic astrology (Jyotishi), and Hindu priesthood (Purohits).

The project is structured as a **Monorepo** consisting of a high-performance **FastAPI Backend** and a cross-platform **Flutter Mobile App**, maintaining 100% feature parity with the **Streamlit Web Dashboard**.

---

## 📁 Project Architecture

```text
VedaGuru_AI/
├── backend/                  # Python FastAPI Backend & Streamlit Web App
│   ├── api/                  # Modular FastAPI routers & services (68 endpoints)
│   │   ├── config.py         # Gemini AI Client with fallback & TTS configuration
│   │   ├── schemas.py        # Pydantic data models for all 25 modules
│   │   └── routers/
│   │       ├── auth.py       # Authentication, Profiles & Recovery
│   │       ├── chat.py       # Vedic AI Chatbot with conversation memory
│   │       ├── pooja.py      # Master 3-in-1 planner, Samagri, Vidhi, Audio, PDF
│   │       ├── panchang.py   # Live Panchang, Muhurat, Upcoming Festivals, Daily Wisdom
│   │       ├── wisdom.py     # Scripture Library, Aarti Sangrah, Mantras, Katha
│   │       ├── astrology.py  # Janam Kundali, Matchmaking (36 Gunas), Rashichakra
│   │       ├── lifestyle.py  # Annapurna Vrat & Prasad, Ayurveda, Japa, Vastu, Tirth
│   │       ├── workspace.py  # Yagya Board, Community Vidhi Feed, Audit Log, Admin Stats
│   │       └── yajman.py     # Purohit CRM, Client Bookings & Calendar
│   ├── app.py                # Legacy Streamlit Web Application
│   ├── db.py                 # SQLite Database Operations
│   ├── vedaguru.db           # SQLite Database (users, history, bookings, boards, etc.)
│   ├── pdf_engine.py         # Unicode PDF generation with Devanagari support
│   ├── assets/               # Fonts, icons, and background artwork
│   ├── .env                  # GEMINI_API_KEY configuration
│   └── main.py               # FastAPI server entrypoint
│
└── mobile/                   # Flutter Mobile Client (Android & iOS)
    ├── lib/
    │   ├── constants/        # Sacred Vedic Palette & Typography Theme
    │   ├── models/           # Dart data models (UserModel, ChatMessage)
    │   ├── services/         # Full REST ApiService connecting to FastAPI
    │   ├── providers/        # State Management (AuthProvider, ChatProvider)
    │   ├── screens/          # Complete Suite of UI Screens:
    │   │   ├── splash_screen.dart          # Spiritual animated splash
    │   │   ├── auth_screen.dart            # Dual-tab Sign In & Registration
    │   │   ├── main_navigation_shell.dart  # 5-Tab Bottom Nav Shell + Workspace
    │   │   ├── home_screen.dart            # Live Panchang, Wisdom, Festivals, Consult
    │   │   ├── rituals_screen.dart         # Rituals & Pujas Hub
    │   │   ├── master_planner_screen.dart  # 3-in-1 Ceremony Master Planner
    │   │   ├── samagri_screen.dart         # Regional Samagri checklist generator
    │   │   ├── pooja_guidance_screen.dart  # Step-by-Step Pooja Vidhi with Mantras
    │   │   ├── muhurat_screen.dart         # Auspicious Muhurat calculator
    │   │   ├── wisdom_screen.dart          # Granths & Mantras Hub
    │   │   ├── chat_screen.dart            # Real-time Vedic AI Chat interface
    │   │   ├── library_screen.dart         # Vedic Scripture Library & "Ask Granth"
    │   │   ├── aarti_screen.dart           # Aarti Sangrah in Devanagari & meanings
    │   │   ├── mantra_screen.dart          # Vedic Mantras with swaras & phonetics
    │   │   ├── katha_screen.dart           # Pauranik Katha Explorer & Moral takeaways
    │   │   ├── astrology_screen.dart       # Jyotish Kendra Hub
    │   │   ├── kundali_screen.dart         # Janam Kundali & Birth Chart reader
    │   │   ├── matchmaking_screen.dart     # 36-point Ashtakoot Guna Milan
    │   │   ├── rashichakra_screen.dart     # 12 Rashis: Deity, Ratna, Trees, Beej Mantra
    │   │   ├── lifestyle_screen.dart       # Sadhana & Lifestyle Hub
    │   │   ├── japa_mala_screen.dart       # Digital 108 Japa Mala with haptics
    │   │   ├── annapurna_screen.dart       # Vrat Meals & Deity Temple Prasad
    │   │   ├── ayurveda_screen.dart        # Doshas & Dinacharya Consultation
    │   │   ├── vastu_screen.dart           # Vastu Shastra home layout consultant
    │   │   ├── tirth_screen.dart           # Tirth Yatra pilgrimage planner
    │   │   ├── workspace_screen.dart       # User Profile & Workspace Hub
    │   │   ├── yajman_crm_screen.dart      # Purohit CRM, WhatsApp reminders & Calendar
    │   │   ├── booking_screen.dart         # Devotee Ritual Reservations & Status
    │   │   ├── yagya_board_screen.dart     # Collaborative ritual event planner
    │   │   ├── community_screen.dart       # Community Vidhi & custom traditions feed
    │   │   └── history_screen.dart         # Audit trail & past activity history
    │   └── main.dart         # Flutter application entrypoint
    └── pubspec.yaml          # Flutter dependencies
```

---

## 🚀 Running the Project

### 1. Launch the FastAPI Backend
```powershell
cd d:\VedaGuru_AI\backend
python -m uvicorn main:app --reload --port 8000
```
* **Interactive API Playground (Swagger UI):** [`http://127.0.0.1:8000/docs`](http://127.0.0.1:8000/docs)
* **ReDoc Documentation:** [`http://127.0.0.1:8000/redoc`](http://127.0.0.1:8000/redoc)

---

### 2. Launch the Flutter Mobile App
```powershell
cd d:\VedaGuru_AI\mobile
flutter run
```
* **Choose device:** Choose your Android device/emulator, Windows desktop, or Chrome browser.

---

### 3. Launch the Streamlit Web Dashboard (Alternative)
```powershell
cd d:\VedaGuru_AI\backend
streamlit run app.py
```
