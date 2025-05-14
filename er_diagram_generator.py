#!/usr/bin/env python3

"""
ER Diagram Generator for Longevity Biomarker Tracker.

Generates an ER diagram from the MySQL schema using Python
"""

import os
import subprocess
from pathlib import Path
from sqlalchemy import create_engine, MetaData
from eralchemy2 import render_er
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database connection settings
DB_CONFIG = {
    "host": os.getenv("MYSQL_HOST", "localhost"),
    "port": os.getenv("MYSQL_PORT", "3307"),
    "user": os.getenv("MYSQL_USER", "biomarker_user"),
    "password": os.getenv("MYSQL_PASSWORD", "biomarker_pass"),
    "database": os.getenv("MYSQL_DATABASE", "longevity"),
}


def ensure_graphviz():
    """Ensure Graphviz is installed (required for ER diagram generation)"""
    try:
        subprocess.run(["dot", "-V"], capture_output=True, check=True)
        print("✓ Graphviz is installed")
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("✗ Graphviz not found. Installing...")
        if os.system("which brew") == 0:  # macOS with Homebrew
            os.system("brew install graphviz")
        else:
            print("Please install Graphviz manually:")
            print("  macOS: brew install graphviz")
            print("  Ubuntu: sudo apt-get install graphviz")
            raise SystemExit(1)


def generate_er_diagram():
    """Generate ER diagram from the live database schema"""
    # Ensure output directory exists
    docs_dir = Path("docs")
    docs_dir.mkdir(exist_ok=True)

    # Create database connection URL
    db_url = f"mysql+pymysql://{DB_CONFIG['user']}:{DB_CONFIG['password']}@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"

    # Output file paths
    er_diagram_path = docs_dir / "er_diagram.png"
    er_diagram_pdf = docs_dir / "er_diagram.pdf"

    print(f"Connecting to database at {DB_CONFIG['host']}:{DB_CONFIG['port']}")

    try:
        # Generate ER diagram directly from database
        render_er(db_url, str(er_diagram_path))
        print(f"✓ ER diagram generated: {er_diagram_path}")

        # Also generate PDF version for document submission
        render_er(db_url, str(er_diagram_pdf))
        print(f"✓ ER diagram PDF generated: {er_diagram_pdf}")

        # Generate a simple text-based schema summary
        engine = create_engine(db_url)
        metadata = MetaData()
        metadata.reflect(bind=engine)

        schema_summary_path = docs_dir / "schema_summary.md"
        with open(schema_summary_path, "w") as f:
            f.write("# Database Schema Summary\n\n")
            f.write("## Tables\n\n")

            for table_name, table in metadata.tables.items():
                f.write(f"### {table_name}\n\n")
                f.write("| Column | Type | Constraints |\n")
                f.write("|--------|------|-------------|\n")

                for column in table.columns:
                    constraints = []
                    if column.primary_key:
                        constraints.append("PK")
                    if not column.nullable:
                        constraints.append("NOT NULL")
                    if column.autoincrement:
                        constraints.append("AUTO_INCREMENT")

                    f.write(
                        f"| {column.name} | {column.type} | {', '.join(constraints)} |\n"
                    )

                # List foreign keys
                if table.foreign_keys:
                    f.write("\n**Foreign Keys:**\n")
                    for fk in table.foreign_keys:
                        f.write(
                            f"- {fk.parent.name} → {fk.column.table.name}.{fk.column.name}\n"
                        )
                f.write("\n")

        print(f"✓ Schema summary generated: {schema_summary_path}")

    except Exception as e:
        print(f"✗ Error generating ER diagram: {e}")
        print("Make sure the database is running and accessible")
        return False

    return True


def main():
    """Main function"""
    print("=== ER Diagram Generator ===\n")

    # Check if database is accessible
    print("Checking database connection...")

    # Ensure Graphviz is installed
    ensure_graphviz()

    # Generate the ER diagram
    if generate_er_diagram():
        print("\n✓ ER diagram generation completed successfully!")
        print("\nFiles generated:")
        print("  - docs/er_diagram.png (for README/presentations)")
        print("  - docs/er_diagram.pdf (for submission)")
        print("  - docs/schema_summary.md (human-readable schema)")
    else:
        print("\n✗ ER diagram generation failed")
        return 1

    return 0


if __name__ == "__main__":
    exit(main())
