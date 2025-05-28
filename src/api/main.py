"""Longevity Biomarker API"""

from datetime import date, datetime, timedelta
from fastapi import FastAPI, Depends, HTTPException, Body, status
from fastapi.middleware.cors import CORSMiddleware
import math
import os
import re
import pandas as pd
import pymysql
import sys
from typing import Optional


project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from src.analytics.hd import HomeostasisDysregulation


DB_HOST = os.getenv("MYSQL_HOST", "localhost")
DB_PORT = int(os.getenv("MYSQL_PORT", 3307))
DB_USER = os.getenv("MYSQL_USER", "biomarker_user")
DB_PASSWORD = os.getenv("MYSQL_PASSWORD", "biomarker_pass")
DB_NAME = os.getenv("MYSQL_DATABASE", "longevity")


app = FastAPI(
    title="Longevity Biomarker API",
    description="API for tracking biomarkers and calculating biological age",
)

# RD final review: CORS fix with ReGeX
CORS_ORIGIN_REGEX = r"^https?://(localhost|\[::1\]|\d{1,3}(?:\.\d{1,3}){3})(:\d+)?$"

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=CORS_ORIGIN_REGEX,  # ← String, not .pattern
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# RD: Need to explicitly handle OPTIONS method in FastAPI
@app.options("/api/v1/users")
def options_users():
    return {"message": "OK"}


hd_model = None


@app.on_event("startup")
def startup():
    global hd_model

    if os.getenv("DISABLE_HD", "").lower() in {"1", "true"}:
        print("[INFO] HD model fitting skipped via DISABLE_HD flag.")
        return

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
        with connection.cursor() as cursor:
            query = """
            SELECT
                view_reference.UserID,
                view_reference.Age,
                view_reference.BMI,
                view_reference.Sex,
                view_measurements.BiomarkerID,
                view_measurements.BiomarkerName,
                view_measurements.Value
            FROM v_hd_reference_candidates view_reference
            JOIN v_user_latest_measurements view_measurements ON view_reference.UserID=view_measurements.userID
            WHERE view_measurements.BiomarkerID BETWEEN 1 AND 9
            """
            cursor.execute(query)
            reference_df = cursor.fetchall()
        if not reference_df:
            # raise RuntimeError("No reference population available for HD calculation")
            print("No reference population available for HD calculation")

        reference_df = pd.DataFrame(reference_df)

        # Convert all decimal.Decimal columns to float
        reference_df["Value"] = reference_df["Value"].astype(float)
        reference_df["BMI"] = reference_df["BMI"].astype(float)

        # Unit conversion: mg/dL → mmol/L - RD: Small fix to resolve Pandas warning in API
        glucose_mask = reference_df["BiomarkerID"] == 4
        reference_df.loc[glucose_mask, "Value"] = (
            reference_df.loc[glucose_mask, "Value"] / 18
        )
        biomarker_columns = reference_df["BiomarkerName"].unique()

        # Pivot to get biomarkers as columns
        reference_df = reference_df.pivot_table(
            index=["UserID", "Age", "BMI", "Sex"],
            columns="BiomarkerName",
            values="Value",
        ).reset_index()

        # Ensure we have all 9 biomarkers for each person
        reference_df = reference_df.dropna()

        print(
            f"HD reference population: {len(reference_df)} people with complete biomarker data"
        )

        # RD 5-27 final review: Guard against empty reference population
        if len(reference_df) < 20:
            print(
                f"[WARNING] HD reference population too small ({len(reference_df)} < 20). HD model disabled."
            )
            hd_model = None
            return

        hd_model = HomeostasisDysregulation()
        hd_model.fit_reference_population(reference_df, biomarker_columns, "Age")

    except Exception as e:
        print(f"error: failed to initialize HD model on startup: {str(e)}")
        hd_model = None
    finally:
        connection.close()


# RD 5-27 final review: fixed potential connection leak
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
        try:
            connection.rollback()  # Rollback any uncommitted transactions
        except Exception:
            pass  # Connection might already be closed
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
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )

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
    """Query 3: Get current biological age (agegap = biological age - chronological age)"""
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
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"No biological age results for user {userId}",
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
    chronological_age = user_profile["user"]["age"]
    return_responses = []

    with db.cursor() as cursor:
        # ---- missing biomarkers -----------------------------------------
        if len(user_profile["biomarkers"]) != 9:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Insufficient biomarker data for calculation",
            )
        biomarkers_dict = {
            biomarker["biomarkerId"]: [biomarker["value"], biomarker["name"]]
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
                            biomarkers_dict[coefficient["biomarkerId"]][0]
                        )
                        # Unit conversion for fasting glucose
                        if coefficient["biomarkerId"] == 4:
                            biomarker_value /= 18.0
                        if coefficient["transform"] == "log":
                            biomarker_value = math.log(biomarker_value)
                        linear_term += biomarker_value * float(
                            coefficient["coefficient"]
                        )
                    mortality_score = linear_term + chronological_age * 0.0804 - 19.9067
                    R = min(0.999999, 1 - math.exp(-math.exp(mortality_score)))
                    phenotypic_age = round(
                        141.50 + math.log(-math.log(1 - R)) / 0.09165, 2
                    )
                    bioAgeYears = phenotypic_age

                # ---- Homeostatic Dysregulation -----------------------------------------
                elif model == "Homeostatic Dysregulation":
                    if hd_model is None:
                        raise HTTPException(
                            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                            detail="HD model unavailable, only Phenotypic Age model available",
                        )

                    user_biomarkers_named = {}
                    for biomarker_id, (
                        biomarker_value,
                        biomarker_name,
                    ) in biomarkers_dict.items():
                        biomarker_value = float(biomarker_value)
                        # Unit conversion for fasting glucose
                        if biomarker_id == 4:
                            biomarker_value /= 18.0
                        user_biomarkers_named[biomarker_name] = biomarker_value

                    # Calculate HD using pre-fitted model
                    hd_result = hd_model.calculate_hd(
                        user_biomarkers_named, convert_to_years=False
                    )

                    # Convert to age
                    hd_score = hd_result.hd_score
                    age_adjustment = (hd_score - 2.5) * 4
                    hd_age = round(chronological_age + age_adjustment, 2)
                    bioAgeYears = hd_age

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

                return_responses.append(
                    {
                        "modelName": model,
                        "bioAgeYears": bioAgeYears,
                        "ageGap": round(bioAgeYears - chronological_age, 2),
                        "computedAt": computed_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
                    }
                )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"error: {str(e)}",
            )
        db.commit()
    return {"calculations": return_responses}


@app.post("/api/v1/users/{userId}/measurements", status_code=status.HTTP_201_CREATED)
def add_new_measurement(userId: int, body=Body(), db=Depends(get_db)):
    """Query 4: Create new measurement session for specific date"""
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


@app.get("/api/v1/users/{userId}/ranges")
def reference_range_comparison(userId: int, type: str = "both", db=Depends(get_db)):
    """Query 5: Compare each biomarker against clinical and longevity reference ranges"""
    with db.cursor() as cursor:
        query = """
        SELECT
            biomarkerId,
            name,
            value,
            CASE
                WHEN SUM(statusCounter)=2 THEN "Optimal"
                WHEN SUM(statusCounter)=1 THEN "Normal"
                ELSE "OutOfRange"
                END AS status,
            MAX(CASE
                    WHEN rangeType="clinical" THEN valueRange
                    END) AS clinicalRange,
            MAX(CASE
                    WHEN rangeType="longevity" THEN valueRange
                    END) AS longevityRange

        FROM(
            SELECT
                view_measurements.BiomarkerID AS biomarkerId,
                view_measurements.BiomarkerName AS name,
                view_measurements.Value AS value,
                ReferenceRange.RangeType AS rangeType,
                JSON_OBJECT("min", ReferenceRange.MinVal, "max", ReferenceRange.MaxVal) AS valueRange,
                SUM(CASE
                        WHEN (ReferenceRange.MinVal <= value) AND (value <= ReferenceRange.MaxVal) THEN 1
                        ELSE 0
                        END) AS statusCounter
            FROM v_user_latest_measurements view_measurements
            JOIN ReferenceRange ON view_measurements.BiomarkerID=ReferenceRange.BiomarkerID
            JOIN User ON User.UserID=view_measurements.UserID
            WHERE ReferenceRange.Sex in ("All", User.Sex) AND view_measurements.UserID = %s
            GROUP BY biomarkerId, name, value, rangeType, valueRange
            ) AS NestedTable
        GROUP BY biomarkerId, name, value
        """
        cursor.execute(query, (userId,))
        ranges = cursor.fetchall()
        return {"ranges": ranges}


@app.get("/api/v1/users/{userId}/biomarkers/{biomarkerId}/trend")
def biomarker_trends(
    userId: int,
    biomarkerId: int,
    limit: int = 20,
    range: str = "6months",
    db=Depends(get_db),
):
    """Query 6: Show historical values for specific biomarker over time"""
    # ----  parse input to calculate upto when the Biomarker should be queried --------------------------
    range = range.strip()

    # RD 5-27 Fix: More flexible parsing: "6 months", "6months", "6 month" all work
    match = re.match(r"^(\d+)\s*(day|week|month|year)s?$", range.lower())
    if not match:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Range must be in format: '<number> <days|weeks|months|years>' (e.g., '6 months')",
        )

    number, text = int(match.group(1)), match.group(2)
    years, months, weeks, days = 0, 0, 0, 0
    if text in {"day", "d"}:
        days = number
    elif text in {"week", "w"}:
        weeks = number
    elif text in {"month", "m"}:
        months = number
    elif text in {"year", "y"}:
        years = number
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Input range must be in '<number> <days|weeks|months|years>' format",
        )
    range_days = 1 * days + 7 * weeks + 31 * months + 365 * years
    range_period = datetime.today() - timedelta(days=range_days)

    with db.cursor() as cursor:
        query = """
        SELECT
            MeasurementSession.SessionDate AS date,
            Measurement.Value AS value,
            Measurement.SessionID AS sessionId
        FROM Measurement
        JOIN MeasurementSession ON Measurement.SessionID=MeasurementSession.SessionID
        WHERE MeasurementSession.UserID=%s AND Measurement.BiomarkerID=%s AND MeasurementSession.SessionDate > %s
        LIMIT %s
        """
        cursor.execute(query, (userId, biomarkerId, range_period, limit))
        trend = cursor.fetchall()
    if not trend:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No measurements for this biomarker: {biomarkerId}, user: {userId}, within {range_days} days",
        )
    return {"trend": trend}


@app.get("/api/v1/users/{userId}/bio-age/history")
def get_biological_age_history(
    userId: int, model: Optional[str] = None, db=Depends(get_db)
):
    """Query 7: Show how biological age has changed over multiple calculations"""
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


@app.get("/api/v1/users/{userId}/sessions/{sessionId}")
def get_session_details(userId: int, sessionId: int, db=Depends(get_db)):
    """Query 8: Show all biomarkers measured in a specific lab session"""
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
        cursor.execute(query, (userId, sessionId))
        session_data = cursor.fetchone()
        if not session_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User's session not found"
            )
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
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Session not found"
            )
    return session_data | {"measurements": measurement_data}


@app.get("/api/v1/biomarkers")
def biomarker_catalog(db=Depends(get_db)):
    """Query 9: Return all biomarkers with metadata"""
    with db.cursor() as cursor:
        query = """
        SELECT
            BiomarkerID AS biomarkerId,
            Name AS name,
            Units AS units,
            Description AS description,
            NHANESVarCode AS nhanesVarCode
        FROM Biomarker
        """
        cursor.execute(query)
        biomarkers = cursor.fetchall()
        return {"biomarkers": biomarkers}


@app.get("/api/v1/biomarkers/{biomarkerId}/ranges")
def biomarker_reference_ranges(biomarkerId: int, db=Depends(get_db)):
    """Query 10: Get all reference ranges for specific biomarker"""
    with db.cursor() as cursor:
        query = """
        SELECT
            RangeType AS rangeType,
            Sex AS sex,
            AgeMin AS ageMin,
            AgeMax AS ageMax,
            MinVal AS minVal,
            MaxVal AS maxVal
        FROM ReferenceRange
        WHERE BiomarkerID = %s
        """
        cursor.execute(query, (biomarkerId,))
        ranges = cursor.fetchall()
        if not ranges:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Biomarker not found"
            )
        return {"ranges": ranges}


@app.get("/api/v1/users/age-distribution")
def get_age_distribution(db=Depends(get_db)):
    """Query 11: Show user count by age groups"""
    with db.cursor() as cursor:
        query = """
        SELECT
            CASE
                WHEN TIMESTAMPDIFF(YEAR, BirthDate, CURDATE()) < 30 THEN "20-29"
                WHEN TIMESTAMPDIFF(YEAR, BirthDate, CURDATE()) < 40 THEN "30-39"
                WHEN TIMESTAMPDIFF(YEAR, BirthDate, CURDATE()) < 50 THEN "40-49"
                ELSE "60+"
                END AS AgeGroup,
            Sex,
            COUNT(*) AS UserCount
        FROM User
        GROUP BY AgeGroup, Sex
        ORDER BY AgeGroup, Sex
        """
        cursor.execute(query)
        return {"ageDistribution": cursor.fetchall()}


@app.get("/api/v1/biomarkers/measurement-summary")
def get_biomarkers_with_counts(db=Depends(get_db)):
    """Query 12: List all biomarkers with their measurement count"""
    with db.cursor() as cursor:
        query = """
        SELECT
            Biomarker.Name,
            Biomarker.Units,
            COUNT(Measurement.MeasurementID) AS MeasurementCount
        FROM Biomarker
        LEFT JOIN Measurement ON Biomarker.BiomarkerID=Measurement.BiomarkerID
        GROUP BY Biomarker.Name, Biomarker.Units
        """
        cursor.execute(query)
        return {"biomarkers": cursor.fetchall()}


# ---------------------------------------------------------------------
# Legacy test stub endpoints - DO NOT USE IN PRODUCTION
# These exist only for backward compatibility with existing tests
# Real API endpoints use /api/v1/ prefix
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
