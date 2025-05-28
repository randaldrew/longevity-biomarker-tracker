"""Test HD model mathematical correctness"""
import numpy as np
import pandas as pd
from src.analytics.hd import HomeostasisDysregulation


def test_hd_mahalanobis_calculation():
    """Test HD Mahalanobis distance calculation against manual numpy calculation"""
    # Create tiny reference dataset (30 people, 3 biomarkers for simplicity)
    np.random.seed(42)  # Reproducible
    reference_data = pd.DataFrame(
        {
            "Biomarker1": np.random.normal(100, 15, 30),
            "Biomarker2": np.random.normal(50, 10, 30),
            "Biomarker3": np.random.normal(200, 30, 30),
            "Age": np.random.uniform(20, 30, 30),
        }
    )

    # Fit HD model
    hd_model = HomeostasisDysregulation()
    hd_model.fit_reference_population(
        reference_data, ["Biomarker1", "Biomarker2", "Biomarker3"], "Age"
    )

    # Test individual with known values
    test_individual = {"Biomarker1": 110.0, "Biomarker2": 45.0, "Biomarker3": 220.0}

    # Calculate HD score using our model
    hd_result = hd_model.calculate_hd(test_individual, convert_to_years=False)

    # Manual numpy calculation for verification
    means = reference_data[["Biomarker1", "Biomarker2", "Biomarker3"]].mean()
    stds = reference_data[["Biomarker1", "Biomarker2", "Biomarker3"]].std()

    # Z-score the test individual
    z_scores = np.array(
        [
            (test_individual["Biomarker1"] - means["Biomarker1"]) / stds["Biomarker1"],
            (test_individual["Biomarker2"] - means["Biomarker2"]) / stds["Biomarker2"],
            (test_individual["Biomarker3"] - means["Biomarker3"]) / stds["Biomarker3"],
        ]
    )

    # Calculate covariance matrix manually
    z_ref = (reference_data[["Biomarker1", "Biomarker2", "Biomarker3"]] - means) / stds
    cov_matrix = np.cov(z_ref.T)
    cov_inv = np.linalg.inv(cov_matrix)

    # Manual Mahalanobis distance: sqrt(z' * Σ^(-1) * z)
    manual_hd = np.sqrt(z_scores.T @ cov_inv @ z_scores)

    # Should match our model's calculation
    assert (
        abs(hd_result.hd_score - manual_hd) < 0.001
    ), f"HD calculation mismatch: model={hd_result.hd_score:.6f}, manual={manual_hd:.6f}"
    print(f"✓ HD Mahalanobis calculation validated: {hd_result.hd_score:.4f}")
