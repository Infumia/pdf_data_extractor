import argparse
import json
import sys
import pdfplumber

def extract_text_from_coordinates(input_file, x0, y0, x1, y1, page_number=None, x_tolerance=3):
    """
    Extract text from a PDF file at specific coordinates.

    Args:
        input_file (str): Path to the input PDF file
        x0, y0, x1, y1 (float): Bounding box coordinates
        page_number (int, optional): Specific page number to extract from (1-indexed).
        x_tolerance (float, optional): Tolerance for x-distance to insert spaces. Defaults to 3.

    Returns:
        str: String containing extracted text from the specified region
    """
    full_text = ""
    with pdfplumber.open(input_file) as pdf:
        if page_number:
            if 1 <= page_number <= len(pdf.pages):
                pages_to_process = [pdf.pages[page_number - 1]]
            else:
                print(f"Warning: Page number {page_number} is out of range (1-{len(pdf.pages)}). Processing all pages.")
                pages_to_process = pdf.pages
        else:
            pages_to_process = pdf.pages

        for page in pages_to_process:
            try:
                # crop_coords is expected to be (x0, top, x1, bottom)
                cropped_page = page.crop((x0, y0, x1, y1))
                page_text = cropped_page.extract_text(x_tolerance=x_tolerance)
                if page_text:
                    full_text += page_text + "\n"
            except ValueError as e:
                print(f"Warning: Could not crop page {page.page_number}: {e}")
                continue
    
    return full_text.strip()

def extract_data_from_pdf(pdf_file, selections_json, x_tolerance=1):
    """
    Extract data from a PDF using coordinates defined in a JSON file.
    
    Args:
        pdf_file (str): Path to the PDF file
        selections_json (str): Path to the JSON file with selections
        x_tolerance (float): Tolerance for x-distance to insert spaces
    
    Returns:
        dict: Dictionary with labels as keys and extracted text as values
    """
    # Load selections from JSON
    with open(selections_json, 'r', encoding='utf-8') as f:
        selections = json.load(f)
    
    # Extract data for each selection
    extracted_data = {}
    
    for selection in selections:
        label = selection['label']
        page = selection['page']
        coords = selection['coordinates']
        
        x0 = coords['x0']
        y0 = coords['y0']
        x1 = coords['x1']
        y1 = coords['y1']
        
        print(f"Extracting '{label}' from page {page} at ({x0}, {y0}, {x1}, {y1})...")
        
        # Extract text from the specified coordinates
        text = extract_text_from_coordinates(
            pdf_file, 
            x0, y0, x1, y1, 
            page_number=page,
            x_tolerance=x_tolerance
        )
        
        extracted_data[label] = text
        print(f"  → '{text}'")
    
    return extracted_data

def main():
    parser = argparse.ArgumentParser(description='Extract data from PDF using selection coordinates')
    parser.add_argument('pdf_file', help='Input PDF file to process')
    parser.add_argument('selections_json', help='JSON file with selections from pdf_selector')
    parser.add_argument('output_json', help='Output JSON file for extracted data')
    parser.add_argument('--x_tolerance', type=float, default=1, help='Tolerance for x-distance to insert spaces (default: 1)')
    
    args = parser.parse_args()
    
    try:
        # Extract data
        extracted_data = extract_data_from_pdf(args.pdf_file, args.selections_json, args.x_tolerance)
        
        # Save to output JSON
        with open(args.output_json, 'w', encoding='utf-8') as f:
            json.dump(extracted_data, f, indent=2, ensure_ascii=False)
        
        print(f"\n✓ Successfully extracted {len(extracted_data)} fields and saved to {args.output_json}")
        
    except FileNotFoundError as e:
        print(f"Error: File not found - {e}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON format - {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
