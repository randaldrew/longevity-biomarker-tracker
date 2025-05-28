"""Test seed data integrity"""


def test_exact_seed_counts(db_cursor):
    """Verify exact counts of critical seed data"""
    # Test biomarkers
    db_cursor.execute("SELECT COUNT(*) as count FROM Biomarker")
    biomarker_count = db_cursor.fetchone()["count"]
    assert biomarker_count == 9, f"Expected 9 biomarkers, found {biomarker_count}"

    # Test models
    db_cursor.execute("SELECT COUNT(*) as count FROM BiologicalAgeModel")
    model_count = db_cursor.fetchone()["count"]
    assert model_count == 2, f"Expected 2 models, found {model_count}"

    # Test phenotypic age coefficients
    db_cursor.execute(
        """
                      SELECT COUNT(*) as count
                      FROM ModelUsesBiomarker mb
                          JOIN BiologicalAgeModel m
                      ON mb.ModelID = m.ModelID
                      WHERE LOWER (m.ModelName) = 'phenotypic age'
                      """
    )
    pheno_coeffs = db_cursor.fetchone()["count"]
    assert (
        pheno_coeffs == 9
    ), f"Expected 9 Phenotypic Age coefficients, found {pheno_coeffs}"

    # Test reference ranges (10 clinical + 10 longevity = 20)
    db_cursor.execute("SELECT COUNT(*) as count FROM ReferenceRange")
    range_count = db_cursor.fetchone()["count"]
    assert range_count == 20, f"Expected 20 reference ranges, found {range_count}"


def test_critical_biomarkers_present(db_cursor):
    """Verify all 9 required biomarkers exist"""
    expected_codes = [
        "LBXSAL",
        "LBXSAPSI",
        "LBXSCR",
        "LBXGLU",
        "LBXHSCRP",
        "LBXWBCSI",
        "LBXLYPCT",
        "LBXMCVSI",
        "LBXRDW",
    ]

    db_cursor.execute("SELECT NHANESVarCode FROM Biomarker ORDER BY BiomarkerID")
    actual_codes = [row["NHANESVarCode"] for row in db_cursor.fetchall()]

    assert actual_codes == expected_codes, f"Biomarker codes mismatch: {actual_codes}"
