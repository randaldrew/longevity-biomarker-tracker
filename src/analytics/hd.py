"""
Homeostatic Dysregulation (HD) Calculation Module.

Implementation for Longevity Biomarker Tracker

Based on Cohen et al. 2013 and Belsky et al. 2015 methodology
"""

import numpy as np
import pandas as pd
from typing import Dict, List, Optional
from dataclasses import dataclass


@dataclass
class HDResult:
    """Container for HD calculation results"""

    hd_score: float
    hd_years: Optional[float] = None
    reference_n: Optional[int] = None
    biomarkers_used: Optional[List[str]] = None


class HomeostasisDysregulation:
    """
    Homeostatic Dysregulation calculator using Mahalanobis distance

    Reference:
    - Cohen, A.A. et al. (2013). A novel statistical approach shows evidence for multi-system
      physiological dysregulation during aging. PMC 3964022
    - Belsky, D.W. et al. (2015). Quantification of biological aging in young adults.
      PMC 4693454
    """

    def __init__(self):
        """Intialize the class"""
        self.reference_means_ = None
        self.reference_stds_ = None
        self.reference_cov_inv_ = None
        self.biomarker_names_ = None
        self.age_regression_slope_ = None
        self.age_regression_intercept_ = None

    def fit_reference_population(
        self,
        reference_df: pd.DataFrame,
        biomarker_columns: List[str],
        age_column: str = "Age",
    ) -> "HomeostasisDysregulation":
        """
        Fit HD model using a healthy young reference population

        Args:
            reference_df: DataFrame with reference population data
            biomarker_columns: List of biomarker column names
            age_column: Name of age column for optional HD-to-years conversion

        Returns:
            self (fitted)
        """
        # Store biomarker names
        self.biomarker_names_ = biomarker_columns.copy()

        # Extract biomarker data
        biomarker_data = reference_df[biomarker_columns].copy()

        # Remove rows with any missing biomarkers
        biomarker_data = biomarker_data.dropna()

        print(f"HD reference population: {len(biomarker_data)} individuals")
        print(f"Using biomarkers: {biomarker_columns}")

        # Calculate reference means and standard deviations
        self.reference_means_ = biomarker_data.mean()
        self.reference_stds_ = biomarker_data.std()

        # Z-score the biomarker data
        z_scored = (biomarker_data - self.reference_means_) / self.reference_stds_

        # Calculate covariance matrix and its inverse
        cov_matrix = np.cov(z_scored.T)
        self.reference_cov_inv_ = np.linalg.inv(cov_matrix)

        # Optional: fit HD score to chronological age for "HD years" conversion
        if age_column in reference_df.columns:
            ages = reference_df.loc[biomarker_data.index, age_column]
            hd_scores = self._compute_hd_scores(z_scored.values)

            # Simple linear regression: HD_score = slope * age + intercept
            A = np.vstack([ages, np.ones(len(ages))]).T
            (
                self.age_regression_slope_,
                self.age_regression_intercept_,
            ) = np.linalg.lstsq(A, hd_scores, rcond=None)[0]

            print(
                f"HD-to-age conversion fitted: HD_years = {self.age_regression_slope_:.4f} * HD_score + {self.age_regression_intercept_:.4f}"
            )

        return self

    def _compute_hd_scores(self, z_scores: np.ndarray) -> np.ndarray:
        """
        Compute HD scores using Mahalanobis distance

        Args:
            z_scores: Array of z-scored biomarker values (n_samples, n_biomarkers)

        Returns:
            Array of HD scores
        """
        if self.reference_cov_inv_ is None:
            raise ValueError("Must fit model first using fit_reference_population()")

        # Mahalanobis distance formula: sqrt((x - μ)ᵀ Σ⁻¹ (x - μ))
        # Since we're using z-scores, μ = 0, so it's just: sqrt(xᵀ Σ⁻¹ x)
        md_squared = np.sum(z_scores @ self.reference_cov_inv_ * z_scores, axis=1)
        return np.sqrt(md_squared)

    def calculate_hd(
        self, individual_biomarkers: Dict[str, float], convert_to_years: bool = True
    ) -> HDResult:
        """
        Calculate HD score for an individual

        Args:
            individual_biomarkers: Dict mapping biomarker names to values
            convert_to_years: Whether to convert HD score to "HD years"

        Returns:
            HDResult with HD score and optionally HD years
        """
        if self.reference_means_ is None:
            raise ValueError("Must fit model first using fit_reference_population()")

        # Extract biomarker values in correct order
        biomarker_values = []
        used_biomarkers = []

        for name in self.biomarker_names_:
            if name in individual_biomarkers:
                biomarker_values.append(individual_biomarkers[name])
                used_biomarkers.append(name)
            else:
                raise ValueError(f"Missing biomarker: {name}")

        # Convert to numpy array and z-score
        values = np.array(biomarker_values)
        z_scores = (values - self.reference_means_.values) / self.reference_stds_.values

        # Calculate HD score
        hd_score = self._compute_hd_scores(z_scores.reshape(1, -1))[0]

        # Convert to years if requested and possible
        hd_years = None
        if convert_to_years and self.age_regression_slope_ is not None:
            hd_years = (
                self.age_regression_slope_ * hd_score + self.age_regression_intercept_
            )

        return HDResult(
            hd_score=hd_score, hd_years=hd_years, biomarkers_used=used_biomarkers
        )

    def batch_calculate_hd(
        self, biomarker_df: pd.DataFrame, convert_to_years: bool = True
    ) -> pd.DataFrame:
        """
        Calculate HD scores for multiple individuals

        Args:
            biomarker_df: DataFrame with biomarker columns
            convert_to_years: Whether to convert HD scores to "HD years"

        Returns:
            DataFrame with HD_score and optionally HD_years columns
        """
        if self.reference_means_ is None:
            raise ValueError("Must fit model first using fit_reference_population()")

        # Ensure we have all required biomarkers
        missing_cols = set(self.biomarker_names_) - set(biomarker_df.columns)
        if missing_cols:
            raise ValueError(f"Missing biomarker columns: {missing_cols}")

        # Extract and z-score biomarker data
        biomarker_data = biomarker_df[self.biomarker_names_].copy()
        z_scores = (biomarker_data - self.reference_means_) / self.reference_stds_

        # Calculate HD scores for all individuals
        hd_scores = self._compute_hd_scores(z_scores.values)

        # Create results DataFrame
        results = pd.DataFrame({"HD_score": hd_scores}, index=biomarker_df.index)

        # Add HD years if requested
        if convert_to_years and self.age_regression_slope_ is not None:
            results["HD_years"] = (
                self.age_regression_slope_ * results["HD_score"]
                + self.age_regression_intercept_
            )

        return results


# Example usage function for the team
def calculate_hd_for_user(
    user_biomarkers: Dict[str, float], reference_population_df: pd.DataFrame
) -> HDResult:
    """
    Convenience function to calculate HD for a single user

    Example:
        biomarkers = {
            'Albumin': 4.2,
            'Alkaline Phosphatase': 85,
            'Creatinine': 0.9,
            'Fasting Glucose': 88,
            'High-Sensitivity CRP': 1.2,
            'White Blood Cell Count': 6.5,
            'Lymphocyte Percentage': 30,
            'Mean Corpuscular Volume': 90,
            'Red Cell Distribution Width': 13.0
        }

        result = calculate_hd_for_user(biomarkers, reference_df)
        print(f"HD Score: {result.hd_score:.3f}")
        print(f"HD Years: {result.hd_years:.1f}")
    """
    # Define the 9 biomarkers used for HD calculation
    biomarker_names = [
        "Albumin",
        "Alkaline Phosphatase",
        "Creatinine",
        "Fasting Glucose",
        "High-Sensitivity CRP",
        "White Blood Cell Count",
        "Lymphocyte Percentage",
        "Mean Corpuscular Volume",
        "Red Cell Distribution Width",
    ]

    # Initialize and fit HD model
    hd_model = HomeostasisDysregulation()
    hd_model.fit_reference_population(
        reference_df=reference_population_df,
        biomarker_columns=biomarker_names,
        age_column="Age",  # Assuming age column exists
    )

    # Calculate HD for the user
    return hd_model.calculate_hd(user_biomarkers, convert_to_years=True)
