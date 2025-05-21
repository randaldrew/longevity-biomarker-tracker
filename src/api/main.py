"""Main API module for the longevity biomarker tracker."""
# above line required for flake8?

from fastapi import FastAPI
import mysql.connector
import os
from datetime import date

DB_HOST = os.getenv("DB_HOST_LOCAL", "127.0.0.1")
DB_PORT = int(os.getenv("DB_PORT_LOCAL", "3307"))
DB_USER = os.getenv("MYSQL_USER", "biomarker_user")
DB_PASSWORD = os.getenv("MYSQL_PASSWORD", "biomarker_pass")
DB_NAME = os.getenv("MYSQL_DATABASE", "longevity")


app = FastAPI()


def get_cursor():
    connection = mysql.connector.connect(
        host=DB_HOST, port=DB_PORT, user=DB_USER, password=DB_PASSWORD, database=DB_NAME
    )
    cursor = connection.cursor(dictionary=True)
    return connection, cursor


@app.get("/api/v1/users/{userId}/profile")
async def user_profile(userId: int):
    connection, cursor = get_cursor()

    query = """
    SELECT
        BiomarkerID AS biomarkerId,
        BiomarkerName AS name,
        Value AS value,
        Units AS units,
        TakenAt AS takenAt
    FROM v_user_latest_measurements
    WHERE UserID = %s
    ORDER BY biomarkerId;
    """
    cursor.execute(query, (userId,))
    biomarkers = cursor.fetchall()

    query = """
    SELECT
        UserID AS userId,
        SEQN AS seqn,
        BirthDate AS birthDate,
        Sex AS sex,
        RaceEthnicity AS raceEthnicity,
        Age AS age
    FROM v_user_with_age
    WHERE UserID = %s;
    """
    cursor.execute(query, (userId,))
    user_data = cursor.fetchall()

    biomarkers_formatted = []
    for biomarker in biomarkers:
        if isinstance(biomarker.get("takenAt"), date):
            biomarker["takenAt"] = biomarker["takenAt"].strftime("%Y-%m-%d")
        biomarkers_formatted.append(biomarker)

    if user_data:
        user_data = user_data[0]
        if isinstance(user_data.get("birthDate"), date):
            user_data["birthDate"] = user_data["birthDate"].strftime("%Y-%m-%d")

    return {"user": user_data, "biomarkers": biomarkers_formatted}
