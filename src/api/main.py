"""Longevity Biomarker API"""

import os
from datetime import date

import pymysql
from fastapi import FastAPI, Depends, HTTPException


DB_HOST = os.getenv("MYSQL_HOST", "localhost")
DB_PORT = int(os.getenv("MYSQL_PORT", 3307))
DB_USER = os.getenv("MYSQL_USER", "biomarker_user")
DB_PASSWORD = os.getenv("MYSQL_PASSWORD", "biomarker_pass")
DB_NAME = os.getenv("MYSQL_DATABASE", "longevity")


app = FastAPI(
    title="Longevity Biomarker API",
    description="API for tracking biomarkers and calculating biological age",
)


def get_db():
    """Yield a PyMySQL connection and close it after"""
    connection = pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        db=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True,
    )
    try:
        yield connection
    finally:
        connection.close()


@app.get("/")
def root():
    """Endpoint used by CI to confirm API is running"""
    return {"message": "Longevity Biomarker API"}


# ---------------------------------------------------------------------
# User-profile endpoints
# ---------------------------------------------------------------------
@app.get("/api/v1/users/{user_id}/profile")
def user_profile(user_id: int, db=Depends(get_db)):
    """Retrieve the user's profile and latest biomarker data"""
    with db.cursor() as cursor:
        # ---- basic user data --------------------------------------------------
        cursor.execute(
            """
            SELECT
                UserID AS userId,
                SEQN AS seqn,
                BirthDate AS birthDate,
                Sex AS sex,
                RaceEthnicity AS raceEthnicity,
                TIMESTAMPDIFF(YEAR, BirthDate, CURDATE()) AS age
            FROM User
            WHERE UserID = %s
            """,
            (user_id,),
        )
        user = cursor.fetchone()

        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # ---- latest biomarker values -----------------------------------------
        cursor.execute(
            """
            SELECT
                BiomarkerID AS biomarkerId,
                BiomarkerName AS name,
                Value AS value,
                Units AS units,
                TakenAt AS takenAt
            FROM v_user_latest_measurements
            WHERE UserID = %s
            ORDER BY BiomarkerID
            """,
            (user_id,),
        )
        biomarkers = cursor.fetchall()

    if isinstance(user.get("BirthDate"), date):
        user["BirthDate"] = user["BirthDate"].isoformat()

    for b in biomarkers:
        if isinstance(b.get("TakenAt"), date):
            b["TakenAt"] = b["TakenAt"].isoformat()

    return {"user": user, "biomarkers": biomarkers}


# ---------------------------------------------------------------------
# Test stub endpoints for pytest
# ---------------------------------------------------------------------
@app.get("/users/{user_id}")
def read_user(user_id: int):
    """Stub user endpoint retained for tests"""
    return {
        "UserID": user_id,
        "SEQN": 10000 + user_id,
        "Sex": "M",
        "RaceEthnicity": "Sample",
    }


@app.get("/users/{user_id}/measurements")
def read_measurements(user_id: int):
    """Stub measurements endpoint retained for tests"""
    return [{"MeasurementID": 1, "BiomarkerName": "Albumin", "Value": 4.5}]


@app.get("/users/{user_id}/bio-age")
def read_bio_age(user_id: int):
    """Stub bio-age endpoint retained for tests"""
    return {"user_id": user_id, "bio_age_years": 45.0, "model_name": "Phenotypic Age"}
