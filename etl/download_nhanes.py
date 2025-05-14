"""NHANES Data Downloader.

This script downloads NHANES data files needed for the Longevity Biomarker
Tracking System. It gets the 2017-2018 cycle files for demographics and the
nine biomarkers needed for the Phenotypic Age calculation.
"""

import urllib.request
import ssl
from pathlib import Path

# Create data directories if they don't exist
raw_dir = Path("data/raw")
raw_dir.mkdir(parents=True, exist_ok=True)

# URLs for the NHANES 2017-2018 (cycle J) XPT files we need
urls = {
    "DEMO_J.XPT": "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/DEMO_J.XPT",
    "BIOPRO_J.XPT": "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/BIOPRO_J.XPT",
    "GLU_J.XPT": "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/GLU_J.XPT",
    "HSCRP_J.XPT": "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/HSCRP_J.XPT",
    "CBC_J.XPT": "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/CBC_J.XPT",
    "BMX_J.XPT": "https://wwwn.cdc.gov/Nchs/Nhanes/2017-2018/BMX_J.XPT",
}


def download_file(url, filename):
    """Download a file from a URL to the specified filename."""
    try:
        # Create an SSL context that doesn't verify certificates (only if needed)
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        print(f"Downloading {filename}...")
        with urllib.request.urlopen(url, context=ctx) as response:
            with open(filename, "wb") as out_file:
                out_file.write(response.read())
        print(f"Downloaded {filename} successfully.")
    except Exception as e:
        print(f"Error downloading {filename}: {e}")


def main():
    """Main function to download all required NHANES files."""
    for filename, url in urls.items():
        download_file(url, raw_dir / filename)

    print("\nDownload complete. Files saved to data/raw/")


if __name__ == "__main__":
    main()
