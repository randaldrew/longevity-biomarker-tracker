"""Test for reference ranges"""

import pytest
from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


@pytest.fixture
def db_engine():
    """Database connection for testing"""
    # Provide defaults if env vars are not set
    host = os.getenv("MYSQL_HOST", "localhost")
    port = os.getenv("MYSQL_PORT", "3307")
    user = os.getenv("MYSQL_USER", "biomarker_user")
    password = os.getenv("MYSQL_PASSWORD", "biomarker_pass")
    database = os.getenv("MYSQL_DATABASE", "longevity")

    db_url = f"mysql+pymysql://{user}:{password}@{host}:{port}/{database}"
    return create_engine(db_url)


def test_reference_ranges_loaded(db_engine):
    """Test that reference ranges are loaded"""
    with db_engine.connect() as conn:
        # Check clinical ranges exist (10 rows)
        result = conn.execute(
            text(
                "SELECT COUNT(*) as count FROM ReferenceRange WHERE RangeType = 'clinical'"
            )
        ).fetchone()
        assert (
            result.count == 10
        ), f"Expected 10 clinical reference ranges, found {result.count}"

        # Check longevity ranges exist (10 rows)
        result = conn.execute(
            text(
                "SELECT COUNT(*) as count FROM ReferenceRange WHERE RangeType = 'longevity'"
            )
        ).fetchone()
        assert (
            result.count == 10
        ), f"Expected 10 longevity reference ranges, found {result.count}"

        # Check all 9 biomarkers have ranges
        result = conn.execute(
            text("SELECT COUNT(DISTINCT BiomarkerID) as count FROM ReferenceRange")
        ).fetchone()
        assert (
            result.count == 9
        ), f"Expected 9 biomarkers with ranges, found {result.count}"

        # Check creatinine has sex-specific ranges (2 sexes for each range type)
        result = conn.execute(
            text(
                "SELECT COUNT(DISTINCT Sex) as count FROM ReferenceRange WHERE BiomarkerID = 3"
            )
        ).fetchone()
        assert (
            result.count == 2
        ), f"Expected creatinine to have 2 sex-specific ranges, found {result.count}"


def test_biomarker_ranges_view(db_engine):
    """Test that the biomarker ranges view works"""
    with db_engine.connect() as conn:
        result = conn.execute(
            text(
                "SELECT COUNT(*) as count FROM v_biomarker_ranges WHERE RangeType IS NOT NULL"
            )
        ).fetchone()
        assert result.count > 0, "Biomarker ranges view returns no data"

        # Check view includes both range types
        result = conn.execute(
            text(
                "SELECT COUNT(DISTINCT RangeType) as count FROM v_biomarker_ranges WHERE RangeType IS NOT NULL"
            )
        ).fetchone()
        assert result.count == 2, "Expected both clinical and longevity ranges in view"
