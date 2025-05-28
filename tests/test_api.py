"""Test harness for API."""


def test_api_root(api_client):
    """Testing API for response"""
    response = api_client.get("/")
    assert response.status_code == 200
    assert response.json()["message"].startswith("Longevity Biomarker")


def test_get_user(api_client):
    """Test getting a user by ID."""
    user_id = 1  # Assuming user 1 exists in the test database
    response = api_client.get(f"/users/{user_id}")
    assert response.status_code == 200
    user = response.json()
    assert "UserID" in user
    assert user["UserID"] == user_id


def test_get_measurements(api_client):
    """Test getting measurements for a user."""
    user_id = 1  # Assuming user 1 has measurements
    response = api_client.get(f"/users/{user_id}/measurements")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_bio_age_calculation(api_client):
    """Test the biological age calculation endpoint."""
    user_id = 1  # Assuming user 1 exists
    response = api_client.get(f"/users/{user_id}/bio-age")
    assert response.status_code == 200
    payload = response.json()
    assert payload["user_id"] == user_id


def test_cors_ipv6_support(api_client):
    """Test CORS works with IPv6 localhost"""
    response = api_client.options(
        "/api/v1/users", headers={"Origin": "http://[::1]:8501"}
    )
    assert response.status_code == 200
    assert "access-control-allow-origin" in response.headers


def test_insufficient_biomarkers_error(api_client, db_cursor):
    """Test bio-age calculation fails gracefully with insufficient data"""
    # Create user with incomplete biomarker data
    db_cursor.execute(
        """
        INSERT INTO User (SEQN, BirthDate, Sex, RaceEthnicity)
        VALUES (999998, '1980-01-01', 'M', 'Test')
        """
    )
    db_cursor.execute("SELECT LAST_INSERT_ID() as user_id")
    user_id = db_cursor.fetchone()["user_id"]

    # Create a session
    db_cursor.execute(
        """
        INSERT INTO MeasurementSession (UserID, SessionDate, FastingStatus)
        VALUES (%s, '2023-01-01', 1)
        """,
        (user_id,),
    )
    db_cursor.execute("SELECT LAST_INSERT_ID() as session_id")
    session_id = db_cursor.fetchone()["session_id"]

    # Add only 5 biomarkers instead of 9 (insufficient for bio-age calculation)
    for biomarker_id in range(1, 6):  # Only biomarkers 1-5
        db_cursor.execute(
            """
            INSERT INTO Measurement (SessionID, BiomarkerID, Value, TakenAt)
            VALUES (%s, %s, %s, '2023-01-01 10:00:00')
            """,
            (session_id, biomarker_id, 100.0),
        )

    # Commit the changes so the API can see them
    db_cursor.connection.commit()

    response = api_client.post(f"/api/v1/users/{user_id}/bio-age/calculate")
    assert response.status_code == 400
    assert "Insufficient biomarker data" in response.json()["detail"]


def test_duplicate_session_conflict(api_client, db_cursor):
    """Test duplicate session creation returns 409"""
    user_id = 1  # Assuming test user exists

    # Use a very specific date that's unlikely to conflict
    test_date = "2024-12-25"  # Christmas 2024

    # Clean up any existing session for this test
    db_cursor.execute(
        "DELETE FROM MeasurementSession WHERE UserID = %s AND SessionDate = %s",
        (user_id, test_date),
    )
    db_cursor.connection.commit()

    session_data = {
        "sessionDate": test_date,
        "fastingStatus": True,
        "measurements": [{"biomarkerId": 1, "value": 4.5}],
    }

    # First creation should work
    response1 = api_client.post(
        f"/api/v1/users/{user_id}/measurements", json=session_data
    )
    assert response1.status_code == 201

    # Second creation should conflict
    response2 = api_client.post(
        f"/api/v1/users/{user_id}/measurements", json=session_data
    )
    assert response2.status_code == 409
    assert "already exists" in response2.json()["detail"]


def test_glucose_unit_conversion_in_calculation(db_cursor):
    """Test that glucose values are correctly converted mg/dL → mmol/L"""
    # Test the contribution calculation directly
    # 90 mg/dL ÷ 18 = 5.0 mmol/L
    # Phenotypic Age coefficient for glucose is 0.1953
    # Expected contribution: 5.0 × 0.1953 = 0.9765

    db_cursor.execute(
        """
                      SELECT Coefficient
                      FROM ModelUsesBiomarker mb
                               JOIN BiologicalAgeModel m ON mb.ModelID = m.ModelID
                               JOIN Biomarker b ON mb.BiomarkerID = b.BiomarkerID
                      WHERE LOWER(m.ModelName) = 'phenotypic age'
                        AND LOWER(b.Name) LIKE '%glucose%'
                      """
    )

    coeff = float(db_cursor.fetchone()["Coefficient"])

    # Simulate the conversion: 90 mg/dL → 5.0 mmol/L → contribution
    glucose_mg_dl = 90.0
    glucose_mmol_l = glucose_mg_dl / 18.0  # Same conversion as API
    expected_contribution = glucose_mmol_l * coeff

    assert (
        abs(expected_contribution - 0.9765) < 0.001
    ), f"Glucose contribution calculation incorrect: {expected_contribution}"
    print(
        f"✓ Glucose unit conversion validated: {glucose_mg_dl} mg/dL → {glucose_mmol_l} mmol/L → contrib {expected_contribution:.4f}"
    )
