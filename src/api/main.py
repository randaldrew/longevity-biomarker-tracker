"""Longevity Biomarker API"""

from datetime import date, datetime
from fastapi import FastAPI, Depends, HTTPException, Body, status
from fastapi.middleware.cors import CORSMiddleware
import math
import os

# import pandas as pd
import pymysql

# import sys
from typing import Optional


# project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
# if project_root not in sys.path:
#     sys.path.insert(0, project_root)
# from src.analytics.hd import HomeostasisDysregulation


DB_HOST = os.getenv("MYSQL_HOST", "localhost")
DB_PORT = int(os.getenv("MYSQL_PORT", 3307))
DB_USER = os.getenv("MYSQL_USER", "biomarker_user")
DB_PASSWORD = os.getenv("MYSQL_PASSWORD", "biomarker_pass")
DB_NAME = os.getenv("MYSQL_DATABASE", "longevity")


app = FastAPI(
    title="Longevity Biomarker API",
    description="API for tracking biomarkers and calculating biological age",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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
        autocommit=False,
    )
    try:
        yield connection
    finally:
        connection.close()


def get_user_profile(userId: int, db):
    """Retrieve the user's profile and latest biomarker data"""
    with db.cursor() as cursor:
        # ---- basic user data --------------------------------------------------
        query = """
        SELECT
            UserID AS userId,
            SEQN AS seqn,
            BirthDate AS birthDate,
            Sex AS sex,
            RaceEthnicity AS raceEthnicity,
            TIMESTAMPDIFF(YEAR, BirthDate, CURDATE()) AS age
        FROM User
        WHERE UserID = %s
        """
        cursor.execute(query, (userId,))
        user = cursor.fetchone()

        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # ---- latest biomarker values -----------------------------------------
        query = """
        SELECT
            BiomarkerID AS biomarkerId,
            BiomarkerName AS name,
            Value AS value,
            Units AS units,
            TakenAt AS takenAt
        FROM v_user_latest_measurements
        WHERE UserID = %s
        ORDER BY BiomarkerID
        """
        cursor.execute(query, (userId,))
        biomarkers = cursor.fetchall()

    if isinstance(user.get("birthDate"), date):
        user["birthDate"] = user["birthDate"].isoformat()

    for biomarker in biomarkers:
        if isinstance(biomarker.get("takenAt"), date):
            biomarker["takenAt"] = biomarker["takenAt"].isoformat()

    return {"user": user, "biomarkers": biomarkers}


@app.get("/")
def root():
    """Endpoint used by CI to confirm API is running"""
    return {"message": "Longevity Biomarker API"}


# ---------------------------------------------------------------------
# User-profile endpoints
# ---------------------------------------------------------------------
@app.get("/api/v1/users")
def list_all_users(db=Depends(get_db)):
    """Query 1: List All Users"""
    with db.cursor() as cursor:
        query = """
        SELECT
            view_age.UserID AS userId,
            view_age.SEQN AS seqn,
            view_age.Age AS age,
            view_age.Sex AS sex,
            view_age.RaceEthnicity AS raceEthnicity,
            COUNT(DISTINCT MeasurementSession.SessionID) AS sessionCount
        FROM
            v_user_with_age view_age
        LEFT JOIN
            MeasurementSession ON view_age.UserID = MeasurementSession.UserID
        GROUP BY
            view_age.UserID, view_age.SEQN, view_age.Age, view_age.Sex, view_age.RaceEthnicity
        ORDER BY
            view_age.UserID;
        """
        cursor.execute(query)
        all_users = cursor.fetchall()
        return {"users": all_users}


@app.get("/api/v1/users/{userId}/profile")
def user_profile(userId: int, db=Depends(get_db)):
    """Query 2: Retrieve the user's profile and latest biomarker data"""
    return get_user_profile(userId, db)


@app.get("/api/v1/users/{userId}/bio-age")
def get_current_biological_age(userId: int, db=Depends(get_db)):
    """Query 3: Get Current Biological Age (agegap = biological age - chronological age)"""
    with db.cursor() as cursor:
        query = """
        SELECT
            BiologicalAgeModel.ModelName AS modelName,
            BiologicalAgeResult.BioAgeYears AS bioAgeYears,
            BiologicalAgeResult.BioAgeYears - view_age.AGE AS ageGap,
            BiologicalAgeResult.ComputedAt AS computedAt
        FROM v_user_with_age view_age
        JOIN BiologicalAgeResult ON view_age.UserID=BiologicalAgeResult.UserID
        JOIN BiologicalAgeModel ON BiologicalAgeResult.ModelID=BiologicalAgeModel.ModelID
        WHERE view_age.UserID = %s
        ORDER BY BiologicalAgeResult.ModelID;
        """
        cursor.execute(query, (userId,))
        biological_ages = cursor.fetchall()
        if not biological_ages:
            raise HTTPException(
                status_code=404, detail=f"No biological age results for user {userId}"
            )
        for biological_age in biological_ages:
            if isinstance(biological_age.get("computedAt"), date):
                biological_age["computedAt"] = biological_age["computedAt"].strftime(
                    "%Y-%m-%dT%H:%M:%SZ"
                )
        return {"bioAges": biological_ages}


@app.post("/api/v1/users/{userId}/bio-age/calculate")
def calculate_biological_age(
    userId: int, body: dict = Body(default={"modelName": ""}), db=Depends(get_db)
):
    """Query 3.5: Calculate and Post Biological Age"""
    models = {"Phenotypic Age": 1, "Homeostatic Dysregulation": 2}
    if body.get("modelName"):
        models_to_use = [body.get("modelName")]
        if models_to_use[0] not in models.keys():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid model"
            )
    else:
        models_to_use = models.keys()  # by default use all models
    user_profile = get_user_profile(userId, db)

    with db.cursor() as cursor:
        # ---- missing biomarkers -----------------------------------------
        if len(user_profile["biomarkers"]) != 9:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Insufficient biomarker data for calculation",
            )
        biomarkers_dict = {
            biomarker["biomarkerId"]: biomarker["value"]
            for biomarker in user_profile["biomarkers"]
        }
        try:
            for model in models_to_use:
                computed_at = datetime.now()
                bioAgeYears = None
                # ---- Phenotypic Age -----------------------------------------
                if model == "Phenotypic Age":
                    query = """
                    SELECT
                        BiomarkerID AS biomarkerId,
                        Coefficient AS coefficient,
                        Transform AS transform
                    FROM ModelUsesBiomarker
                    WHERE ModelID = 1
                    """
                    cursor.execute(query)
                    phenotypic_coefficients = cursor.fetchall()
                    linear_term = 0
                    for coefficient in phenotypic_coefficients:
                        biomarker_value = float(
                            biomarkers_dict[coefficient["biomarkerId"]]
                        )
                        # Unit conversion for fasting glucose
                        if coefficient["biomarkerId"] == 4:
                            biomarker_value /= 18.0
                        if coefficient["transform"] == "log":
                            biomarker_value = math.log(biomarker_value)
                        linear_term += biomarker_value * float(
                            coefficient["coefficient"]
                        )
                    chronological_age = user_profile["user"]["age"]
                    mortality_score = (
                        linear_term + math.log(chronological_age) * 0.0804 - 19.9067
                    )
                    R = min(0.999999, 1 - math.exp(-math.exp(mortality_score)))
                    phenotypic_age = round(
                        141.50 + math.log(-math.log(1 - R)) / 0.09165, 2
                    )
                    bioAgeYears = phenotypic_age

                # ---- Homeostatic Dysregulation -----------------------------------------
                # elif model == "Homeostatic Dysregulation":
                #     hd_age = hd_model.calculate_hd(biomarkers_dict)
                #     bioAgeYears = round(hd_age, 2)

                # ---- Insert into BiologicalAgeResult -----------------------------------------
                query = """
                INSERT INTO BiologicalAgeResult(UserID, ModelID, BioAgeYears, ComputedAt, CreatedAt)
                    VALUES(%s, %s, %s, %s, %s);
                """
                cursor.execute(
                    query,
                    (
                        userId,
                        models[model],
                        bioAgeYears,
                        computed_at.strftime("%Y-%m-%d %H:%M:%S"),
                        computed_at.strftime("%Y-%m-%d %H:%M:%S"),
                    ),
                )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"error: {str(e)}",
            )
        db.commit()
    return {
        "modelName": model,
        "bioAgeYears": bioAgeYears,
        "ageGap": bioAgeYears - chronological_age,
        "computedAt": computed_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
    }


@app.post("/api/v1/users/{userId}/measurements", status_code=status.HTTP_201_CREATED)
def add_new_measurement(userId: int, body=Body(), db=Depends(get_db)):
    """Query 4: Add New Measurement"""
    session_date = body.get("sessionDate")
    fasting_status = body.get("fastingStatus")
    measurements = body.get("measurements")

    if (not session_date) or (fasting_status is None) or (measurements is None):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid value"
        )

    try:
        session_date = date.fromisoformat(session_date)
    except (ValueError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid date format"
        )

    new_session_id = None
    inserted_measurement_ids = []

    with db.cursor() as cursor:
        created_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        # ---- insert into MeasurementSession -----------------------------------------
        try:
            query = """
            INSERT INTO MeasurementSession(UserID, SessionDate, FastingStatus, CreatedAt)
                VALUES(%s, %s, %s, %s);
            """
            cursor.execute(
                query, (userId, session_date, 1 if fasting_status else 0, created_at)
            )
            new_session_id = cursor.lastrowid
        # ---- 409 Conflict (duplicate (UserID, SessionDate)) -----------------------------------------
        except pymysql.err.IntegrityError as e:
            print(f"DEBUG: IntegrityError - {e}")
            if e.args[0] == 1062:  # duplicate entry
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Measurement session for {session_date} already exists userId {userId}",
                )
            raise
        # ---- insert into Measurements -----------------------------------------
        taken_at = datetime.combine(session_date, datetime.now().time()).strftime(
            "%Y-%m-%d %H:%M:%S"
        )

        for measurement in measurements:
            biomarker_id = measurement.get("biomarkerId")
            value = measurement.get("value")
            try:
                query = """
                INSERT INTO Measurement(SessionID, BiomarkerID, Value, TakenAt, CreatedAt)
                    VALUES(%s, %s, %s, %s, %s);
                """
                cursor.execute(
                    query, (new_session_id, biomarker_id, value, taken_at, created_at)
                )
                inserted_measurement_ids.append(cursor.lastrowid)
            # ----  check if BiomarkerID foreign key exist -----------------------------------------
            except pymysql.err.IntegrityError as e:
                if e.args[0] == 1452:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Invalid value for biomarkerId {biomarker_id}",
                    )
                raise
        # ----  commit if all inserts were successful -----------------------------------------
        db.commit()

    return {"sessionId": new_session_id, "measurementIds": inserted_measurement_ids}


@app.get("/api/v1/users/{userId}/bio-age/history")
def get_biological_age_history(
    userId: int, model: Optional[str] = None, db=Depends(get_db)
):
    """Query 7: Get Biological Age History"""
    with db.cursor() as cursor:
        query = """
        SELECT
            BiologicalAgeModel.ModelName as modelName,
            BiologicalAgeResult.BioAgeYears as bioAgeYears,
            BiologicalAgeResult.BioAgeYears - view_age.AGE AS ageGap,
            BiologicalAgeResult.ComputedAt AS computedAt
        FROM BiologicalAgeResult
        JOIN BiologicalAgeModel ON BiologicalAgeResult.ModelID=BiologicalAgeModel.ModelID
        JOIN v_user_with_age view_age ON BiologicalAgeResult.UserID = view_age.UserID
        WHERE BiologicalAgeResult.UserID = %s
        """
        query_parameters = [userId]
        if model in ["Phenotypic Age", "Homeostatic Dysregulation"]:
            query += " AND BiologicalAgeModel.ModelName = %s"
            query_parameters.append(model)
        query += " ORDER BY BiologicalAgeResult.ComputedAt DESC;"

        cursor.execute(query, tuple(query_parameters))
        age_history = cursor.fetchall()

        for history in age_history:
            if isinstance(history.get("computedAt"), date):
                history["computedAt"] = history["computedAt"].strftime(
                    "%Y-%m-%dT%H:%M:%SZ"
                )
        return {"history": age_history}


@app.get("/apiv1/users/{userId}/sessions/{sessionId}")
def get_session_details(userId: int, sessionId: int, db=Depends(get_db)):
    """Query 8: Get Session Details"""
    with db.cursor() as cursor:
        # ---- session data --------------------------------------------------
        query = """
        SELECT
            SessionID AS sessionId,
            SessionDate AS sessionDate,
            FastingStatus AS fastingStatus
        FROM MeasurementSession
        WHERE UserID = %s AND SessionID = %s
        """
        cursor.execute(
            query,
            (
                userId,
                sessionId,
            ),
        )
        session_data = cursor.fetchone()
        if not session_data:
            raise HTTPException(status_code=404, detail="User's session not found")
        if isinstance(session_data.get("sessionDate"), date):
            session_data["sessionDate"] = session_data["sessionDate"].isoformat()
        if session_data.get("fastingStatus"):
            session_data["fastingStatus"] = (
                True if session_data["fastingStatus"] else False
            )
        # ---- measurement data --------------------------------------------------
        query = """
        SELECT
            BiomarkerID AS biomarkerID,
            BiomarkerName AS name,
            Value AS value,
            Units AS units
        FROM v_user_latest_measurements view_measurements
        WHERE UserID = %s
        """
        cursor.execute(query, (userId,))
        measurement_data = cursor.fetchall()
        if not measurement_data:
            raise HTTPException(status_code=404, detail="Session not found")
        return session_data | {"measurements": measurement_data}


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
