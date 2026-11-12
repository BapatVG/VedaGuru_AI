from fastapi import APIRouter, HTTPException, status
from typing import Optional
import urllib.request
import json
import db
from api.schemas import YajmanCreateRequest, BookingCreateRequest, BookingCompleteRequest

router = APIRouter(prefix="/yajman", tags=["Yajman CRM & Bookings"])

# --- Reverse Geocode ---
@router.get("/reverse-geocode")
def reverse_geocode(lat: float, lng: float):
    try:
        url = f"https://nominatim.openstreetmap.org/reverse?format=json&lat={lat}&lon={lng}&zoom=18&addressdetails=1"
        req = urllib.request.Request(url, headers={'User-Agent': 'VedaGuruAI/1.0 (vedaguru.ai@gmail.com)'})
        with urllib.request.urlopen(req, timeout=2.0) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                display_name = data.get("display_name", "")
                address_parts = data.get("address", {})
                city = (
                    address_parts.get("city") or 
                    address_parts.get("town") or 
                    address_parts.get("village") or 
                    address_parts.get("suburb") or 
                    address_parts.get("state_district") or 
                    address_parts.get("state") or 
                    ""
                )
                return {
                    "status": "success",
                    "display_name": display_name,
                    "city": city,
                    "address": address_parts
                }
    except Exception:
        pass
    return {"status": "fallback", "display_name": f"Location ({lat:.4f}°N, {lng:.4f}°E)", "city": ""}

# --- Purohit Yajman CRM ---
@router.get("/list/{purohit_username}")
def list_clients(purohit_username: str):
    clients = db.get_clients(purohit_username)
    return {"status": "success", "count": len(clients), "clients": clients}

@router.post("/add")
def add_new_client(req: YajmanCreateRequest):
    success = db.add_client(
        purohit_username=req.purohit_username,
        client_name=req.client_name,
        contact_number=req.contact_number,
        pooja_date=req.pooja_date,
        pooja_type=req.pooja_type,
        address=req.address or "Not Provided",
        latitude=req.latitude or 0.0,
        longitude=req.longitude or 0.0
    )
    if not success:
        raise HTTPException(status_code=400, detail="Failed to add Yajman client.")
    return {"status": "success", "message": "Client added successfully."}

@router.delete("/delete/{client_id}")
def delete_client(client_id: int):
    success = db.delete_client(client_id)
    if not success:
        raise HTTPException(status_code=400, detail="Failed to delete client.")
    return {"status": "success", "message": "Client deleted successfully."}

# --- User Bookings ---
@router.get("/bookings/{username}")
def get_user_bookings(username: str):
    bookings = db.get_user_bookings(username)
    return {"status": "success", "count": len(bookings), "bookings": bookings}

@router.post("/bookings")
def create_booking(req: BookingCreateRequest):
    success = db.add_user_booking(
        user_username=req.user_username,
        pooja_type=req.pooja_type,
        pooja_date=req.pooja_date,
        contact_number=req.contact_number or "Not Provided",
        address=req.address or "Not Provided",
        purohit_username=req.purohit_username or "",
        latitude=req.latitude or 0.0,
        longitude=req.longitude or 0.0
    )
    if not success:
        raise HTTPException(status_code=400, detail="Failed to create booking.")
    return {"status": "success", "message": "Booking submitted successfully."}

@router.get("/pending-bookings")
def list_pending_bookings(purohit_username: Optional[str] = None):
    pending = db.get_all_pending_bookings(purohit_username=purohit_username)
    return {"status": "success", "count": len(pending), "bookings": pending}

@router.get("/purohit-bookings/{purohit_username}")
def list_purohit_bookings(purohit_username: str, status: Optional[str] = None):
    bookings = db.get_purohit_bookings(purohit_username, status=status)
    return {"status": "success", "count": len(bookings), "bookings": bookings}

@router.put("/bookings/{booking_id}/accept")
def accept_booking(booking_id: int, purohit_username: str):
    success = db.accept_booking(booking_id, purohit_username)
    if not success:
        raise HTTPException(status_code=400, detail="Failed to accept booking.")
    return {"status": "success", "message": f"Booking {booking_id} accepted by {purohit_username}."}

@router.put("/bookings/{booking_id}/complete")
def complete_booking(booking_id: int, req: Optional[BookingCompleteRequest] = None):
    rating = req.rating if req and req.rating is not None else 5
    feedback = req.feedback if req and req.feedback is not None else ""
    success = db.complete_booking(booking_id, rating=rating, feedback=feedback)
    if not success:
        raise HTTPException(status_code=400, detail="Failed to mark booking completed.")
    return {"status": "success", "message": f"Booking {booking_id} marked as completed."}

@router.put("/bookings/{booking_id}/cancel")
def cancel_booking(booking_id: int):
    success = db.cancel_booking(booking_id)
    if not success:
        raise HTTPException(status_code=400, detail="Failed to cancel booking.")
    return {"status": "success", "message": f"Booking {booking_id} cancelled."}

@router.get("/purohits-directory")
def get_purohits_directory():
    try:
        conn = db.get_connection()
        c = conn.cursor()
        c.execute("""
            SELECT username, default_region, preferred_language 
            FROM users 
            WHERE account_type = 'Purohit'
        """)
        rows = c.fetchall()
        result = []
        for r in rows:
            uname, region, lang = r[0], r[1], r[2]
            c.execute("""
                SELECT rating, feedback, pooja_type, pooja_date, user_username 
                FROM user_bookings 
                WHERE purohit_username = ? AND status = 'Completed' AND rating > 0
                ORDER BY timestamp DESC
            """, (uname,))
            reviews_rows = c.fetchall()
            ratings = [rev[0] for rev in reviews_rows]
            avg_rating = round(sum(ratings) / len(ratings), 1) if ratings else 4.9
            review_items = [
                {
                    "rating": rev[0],
                    "feedback": rev[1],
                    "pooja_type": rev[2],
                    "pooja_date": rev[3],
                    "devotee": rev[4]
                } for rev in reviews_rows
            ]
            result.append({
                "username": uname,
                "region": region,
                "language": lang,
                "rating": avg_rating,
                "review_count": len(ratings),
                "reviews": review_items
            })
        conn.close()
        return {"status": "success", "purohits": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

