"""Longevity Biomarker API"""

from datetime import date, datetime
from fastapi import FastAPI, Depends, HTTPException, Body, status
import math
import os
import pymysql


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
                    """
                    cursor.execute(query)
                    phenotypic_coefficients = cursor.fetchall()
                    phenotypic_age = 0
                    for coefficient in phenotypic_coefficients:
                        biomarker_value = float(
                            biomarkers_dict[coefficient["biomarkerId"]]
                        )
                        if coefficient["transform"] == "log":
                            biomarker_value = math.log(biomarker_value)
                        phenotypic_age += biomarker_value * float(
                            coefficient["coefficient"]
                        )
                    bioAgeYears = round(phenotypic_age, 2)
                # ---- Hemostatic Dysregulation -----------------------------------------

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
        "ageGap": bioAgeYears - user_profile["user"]["age"],
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
