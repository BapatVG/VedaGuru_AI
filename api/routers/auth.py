from fastapi import APIRouter, HTTPException, status
import db
from api.schemas import (
    UserRegisterRequest,
    UserLoginRequest,
    UserProfileUpdateRequest,
    PasswordResetRequest,
    PasswordChangeRequest
)
import bcrypt

router = APIRouter(prefix="/auth", tags=["Authentication & Profile"])

@router.post("/register")
def register(req: UserRegisterRequest):
    success, msg = db.register_user(
        username=req.username,
        password=req.password,
        default_region=req.default_region,
        preferred_language=req.preferred_language,
        account_type=req.account_type,
        security_question=req.security_question or "",
        security_answer=req.security_answer or ""
    )
    if not success:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=msg)
    return {"status": "success", "message": msg, "username": req.username}

@router.post("/login")
def login(req: UserLoginRequest):
    is_valid, region, lang, acc_type = db.verify_login(req.username, req.password)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password"
        )
    return {
        "status": "success",
        "username": req.username,
        "default_region": region,
        "preferred_language": lang,
        "account_type": acc_type
    }

@router.put("/profile")
def update_profile(req: UserProfileUpdateRequest):
    success = db.update_profile(req.username, req.new_region, req.new_language)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update profile settings"
        )
    return {
        "status": "success",
        "message": "Profile updated successfully",
        "default_region": req.new_region,
        "preferred_language": req.new_language
    }

@router.get("/recovery-info/{username}")
def get_recovery_info(username: str):
    info = db.get_user_for_recovery(username)
    if not info:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return {
        "status": "success",
        "username": info["username"],
        "has_security_question": info["has_security_question"],
        "security_question": info["security_question"]
    }

@router.post("/reset-password")
def reset_password(req: PasswordResetRequest):
    success, msg = db.reset_user_password(
        username=req.username,
        new_password=req.new_password,
        security_answer=req.security_answer or "",
        verify_region=req.verify_region,
        verify_role=req.verify_role
    )
    if not success:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=msg)
    return {"status": "success", "message": msg}

@router.post("/change-password")
def change_password(req: PasswordChangeRequest):
    is_valid, _, _, _ = db.verify_login(req.username, req.old_password)
    if not is_valid:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Current password is incorrect.")
    salt = bcrypt.gensalt()
    new_hashed = bcrypt.hashpw(req.new_password.encode('utf-8'), salt).decode('utf-8')
    try:
        conn = db.get_connection()
        c = conn.cursor()
        c.execute('UPDATE users SET password_hash = ? WHERE username = ?', (new_hashed, req.username))
        conn.commit()
        conn.close()
        return {"status": "success", "message": "Password updated successfully."}
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))
