from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import db
from api.routers import (
    auth,
    chat,
    pooja,
    panchang,
    yajman,
    wisdom,
    astrology,
    lifestyle,
    workspace
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize SQLite database on startup
    db.init_db()
    yield

app = FastAPI(
    title="VedaGuru AI - Core Backend API",
    description="The centralized REST API for VedaGuru AI powering both the Flutter Mobile App and Streamlit Web Dashboard.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Enable CORS for Flutter mobile, web clients (localhost:3000), and all devices
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ],
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check & root endpoints
@app.get("/")
def root():
    return {
        "app": "VedaGuru AI Backend",
        "status": "online",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

# Mount API Routers
app.include_router(auth.router, prefix="/api")
app.include_router(chat.router, prefix="/api")
app.include_router(pooja.router, prefix="/api")
app.include_router(panchang.router, prefix="/api")
app.include_router(yajman.router, prefix="/api")
app.include_router(wisdom.router, prefix="/api")
app.include_router(astrology.router, prefix="/api")
app.include_router(lifestyle.router, prefix="/api")
app.include_router(workspace.router, prefix="/api")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
