# BC Record Link Manager

A utility for Microsoft Dynamics 365 Business Central to easily manage, backup, and migrate Record Links (Notes).

Unlike standard CSV exports, this tool uses **JSON** and **AL Reflection** (`RecordRef`/`KeyRef`) to ensure that Notes, URLs, and their specific Record Linkage are preserved accurately across different environments or tables without hardcoding table logic.

## 🚀 Features

*   **Generic Support:** Works with **any** table (Standard or Custom) automatically. No hardcoded Table IDs.
*   **JSON Format:** handling of multi-line text and special characters compared to CSV.
*   **Binary Support:** Preserves rich text/blob data within Notes using Base64 encoding.
*   **Smart Mapping:** Dynamically reconstructs `RecordID` based on Primary Keys during import.

## 📦 Installation

1.  Clone this repository.
2.  Open the folder in **VS Code**.
3.  Publish to your Business Central Sandbox or Docker container (`F5`).

## 🛠 Usage

1.  Search for **"Record Link Administration"** in Business Central.
2.  **Export:** Select specific records (or all) and click **Export to JSON**.
3.  **Import:** Click **Import from JSON** to upload a previously exported file.
    *   *Note:* The import logic attempts to find the record based on the Primary Key. If the target record does not exist, the note is skipped to prevent orphan links.

## ⚙️ Technical Details

*   **Codeunit `Record Link Mgt.`:** Handles the serialization of `RecordRef` and Primary Keys into a JSON structure.
*   **Page `Record Link Admin List`:** Provides a user-friendly interface to view target table names and descriptions instead of raw Record IDs.

## ⚠️ Disclaimer

This tool allows for the bulk deletion and modification of system data (Record Links). Always test in a **Sandbox** environment before using in Production.

---
*Created by Erik Seiter*
