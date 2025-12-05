# PDF Extractor CLI - Usage Guide

## Overview

This is a lightweight, CLI-only tool for extracting text from PDF files using predefined coordinate regions. It's optimized for minimal size and fast execution.

## Requirements

- A PDF file to extract data from
- A JSON file containing coordinate definitions (created manually or using the GUI tool)

## Usage

### Basic Command

```bash
PDF-Extractor-CLI.exe <pdf_file> <selections_json> <output_json>
```

### Arguments

- `pdf_file`: Path to the input PDF file
- `selections_json`: Path to JSON file with coordinate selections
- `output_json`: Path where extracted data will be saved
- `--x_tolerance` (optional): Tolerance for x-distance to insert spaces (default: 1)

### Example

```bash
PDF-Extractor-CLI.exe "invoice.pdf" "coordinates.json" "extracted_data.json"
```

With custom tolerance:
```bash
PDF-Extractor-CLI.exe "invoice.pdf" "coordinates.json" "extracted_data.json" --x_tolerance 2
```

## Coordinate JSON Format

The `selections_json` file should follow this format:

```json
[
  {
    "label": "customer_name",
    "page": 1,
    "coordinates": {
      "x0": 100.5,
      "y0": 200.3,
      "x1": 300.7,
      "y1": 220.8
    }
  },
  {
    "label": "invoice_date",
    "page": 1,
    "coordinates": {
      "x0": 400.0,
      "y0": 200.0,
      "x1": 500.0,
      "y1": 220.0
    }
  }
]
```

### Coordinate System

- **Origin**: Top-left corner of the page
- **Units**: Points (1/72 inch)
- **x0, y0**: Top-left corner of the selection box
- **x1, y1**: Bottom-right corner of the selection box
- **page**: Page number (1-indexed)

## Output Format

The extracted data is saved as JSON:

```json
{
  "customer_name": "John Doe",
  "invoice_date": "2025-12-05"
}
```

## Creating Coordinate Files

### Option 1: Manual Creation
Create a JSON file following the format above with your desired coordinates.

### Option 2: Using the GUI Tool
If you need to visually select regions, use the separate GUI tool (`PDF-Selector.exe`) to:
1. Open a PDF
2. Draw selection boxes on the document
3. Save coordinates to JSON
4. Use that JSON file with this CLI tool

## Performance Notes

- **Size**: ~20-50 MB (vs ~300 MB for GUI version)
- **Startup**: Near-instant (no GUI initialization)
- **Dependencies**: Minimal (only pdfplumber for text extraction)

## Troubleshooting

### "File not found" error
- Ensure all paths are correct
- Use quotes around paths with spaces

### No text extracted
- Verify coordinates are correct for your PDF
- Try adjusting `--x_tolerance` value
- Check that the page number is correct (1-indexed)

### Incorrect text extraction
- Increase `--x_tolerance` if words are merged
- Decrease `--x_tolerance` if unwanted spaces appear
- Verify coordinate boundaries include all desired text

## Examples

### Extract from multiple regions
```bash
# coordinates.json contains multiple selections
PDF-Extractor-CLI.exe "document.pdf" "coordinates.json" "output.json"
```

### Batch processing
```batch
@echo off
for %%f in (*.pdf) do (
    PDF-Extractor-CLI.exe "%%f" "template.json" "output_%%~nf.json"
)
```

## Exit Codes

- `0`: Success
- `1`: Error (file not found, invalid JSON, extraction error)
