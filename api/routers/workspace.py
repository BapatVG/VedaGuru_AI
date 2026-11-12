from fastapi import APIRouter, HTTPException
from typing import Optional
import db
from api.schemas import (
    YagyaBoardCreateRequest,
    YagyaCollaboratorRequest,
    YagyaTaskCreateRequest,
    YagyaTaskStatusRequest,
    CommunityVidhiCreateRequest,
    BlockDateRequest
)

router = APIRouter(prefix="/workspace", tags=["Workspace, CRM & Community"])

# ==================== User Audit Trail & History ====================
@router.get("/history/{username}")
def get_user_history(username: str):
    try:
        logs = db.get_user_history(username)
        return {"status": "success", "history": logs}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Yagya Collaborative Ritual Board ====================
@router.get("/yagya/boards/{username}")
def get_boards(username: str):
    try:
        boards = db.get_user_yagya_boards(username)
        return {"status": "success", "boards": boards}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/yagya/boards")
def create_board(req: YagyaBoardCreateRequest):
    try:
        board_id = db.create_yagya_board(req.title, req.event_date, req.created_by)
        return {"status": "success", "board_id": board_id, "message": "Board created successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/yagya/boards/{board_id}")
def delete_board(board_id: int):
    try:
        db.delete_yagya_board(board_id)
        return {"status": "success", "message": "Board deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/yagya/collaborators/{board_id}")
def get_collaborators(board_id: int):
    try:
        collabs = db.get_board_collaborators(board_id)
        return {"status": "success", "collaborators": collabs}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/yagya/collaborators")
def add_collaborator(req: YagyaCollaboratorRequest):
    try:
        db.add_collaborator(req.board_id, req.username)
        return {"status": "success", "message": f"User {req.username} added as collaborator"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/yagya/collaborators/{board_id}/{username}")
def remove_collaborator(board_id: int, username: str):
    try:
        db.remove_collaborator(board_id, username)
        return {"status": "success", "message": f"User {username} removed"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/yagya/tasks/{board_id}")
def get_board_tasks(board_id: int):
    try:
        tasks = db.get_board_tasks(board_id)
        return {"status": "success", "tasks": tasks}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/yagya/tasks")
def add_board_task(req: YagyaTaskCreateRequest):
    try:
        task_id = db.add_yagya_task(req.board_id, req.task_desc, req.assigned_to)
        return {"status": "success", "task_id": task_id, "message": "Task added"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/yagya/tasks/{task_id}/status")
def update_task_status(task_id: int, req: YagyaTaskStatusRequest):
    try:
        db.update_task_status(task_id, req.is_completed)
        return {"status": "success", "message": "Task updated"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/yagya/tasks/{task_id}")
def delete_task(task_id: int):
    try:
        db.delete_task(task_id)
        return {"status": "success", "message": "Task deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Community Vidhi Feed ====================
@router.get("/community")
def get_community_feed():
    try:
        posts = db.get_all_community_vidhi()
        return {"status": "success", "posts": posts}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/community")
def create_community_post(req: CommunityVidhiCreateRequest):
    try:
        db.add_community_vidhi(req.username, req.title, req.region, req.content)
        return {"status": "success", "message": "Vidhi shared with community"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/community/{vidhi_id}")
def delete_community_post(vidhi_id: int):
    try:
        db.delete_community_vidhi(vidhi_id)
        return {"status": "success", "message": "Post deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Purohit Calendar & Reviews ====================
@router.get("/blocked-dates/{purohit_username}")
def get_purohit_blocked_dates(purohit_username: str):
    try:
        dates = db.get_blocked_dates(purohit_username)
        return {"status": "success", "blocked_dates": dates}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/blocked-dates")
def add_blocked_date(req: BlockDateRequest):
    try:
        db.add_blocked_date(req.purohit_username, req.blocked_date, req.reason)
        return {"status": "success", "message": "Date blocked successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/blocked-dates/{blocked_id}")
def remove_blocked_date(blocked_id: int):
    try:
        db.remove_blocked_date(blocked_id)
        return {"status": "success", "message": "Date unblocked"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/reviews/{purohit_username}")
def get_purohit_reviews(purohit_username: str):
    try:
        reviews = db.get_purohit_reviews(purohit_username)
        return {"status": "success", "reviews": reviews}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Admin System Analytics ====================
@router.get("/admin/stats")
def get_admin_stats():
    try:
        summary = db.get_analytics_summary()
        modules = db.get_module_usage_stats()
        roles = db.get_user_role_stats()
        regions = db.get_region_stats()
        return {
            "status": "success",
            "summary": summary,
            "module_usage": modules,
            "role_distribution": roles,
            "region_distribution": regions
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/admin/users")
def get_admin_users():
    try:
        users = db.get_all_users()
        return {"status": "success", "users": users}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
