#!/usr/bin/env python3
"""
PDF Watcher CLI Application

Continuously watches a directory and extracts structured metadata from PDF files.
Metadata includes: filename, SHA-256 hash, company name, and insurance type.
"""

import argparse
import hashlib
import json
import os
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import pdfplumber
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler, FileCreatedEvent, FileModifiedEvent, FileDeletedEvent


@dataclass
class MetaEntry:
    """Represents a single entry in the .meta file."""
    name: str
    file_hash: str
    company: str
    insurance_type: str


class PDFMetadataExtractor:
    """Handles PDF metadata extraction using pdfplumber."""
    
    def __init__(self, companies_config: list, x_tolerance: int = 1):
        """
        Initialize the extractor with company configuration.
        
        Args:
            companies_config: List of company configurations from companies.json
            x_tolerance: Tolerance for x-distance to insert spaces (default: 1)
        """
        self.companies_config = companies_config
        self.x_tolerance = x_tolerance
    
    @staticmethod
    def compute_file_hash(file_path: str) -> str:
        """
        Compute SHA-256 hash of a file.
        
        Args:
            file_path: Path to the file
            
        Returns:
            Hexadecimal string of the SHA-256 hash
        """
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()

    @staticmethod
    def extract_text_from_region(pdf_path: str, x1: float, y1: float, x2: float, y2: float, page_num: int = 0, x_tolerance: int = 1) -> Optional[str]:
        """
        Extract text from a specific region of a PDF page.
        
        Args:
            pdf_path: Path to the PDF file
            x1, y1: Top-left corner coordinates
            x2, y2: Bottom-right corner coordinates
            page_num: Page number (0-indexed)
            x_tolerance: Tolerance for x-distance to insert spaces (default: 1)
            
        Returns:
            Extracted text from the region, or None if page doesn't exist
        """
        try:
            with pdfplumber.open(pdf_path) as pdf:
                if page_num >= len(pdf.pages) or page_num < 0:
                    return None  # Page doesn't exist
                page = pdf.pages[page_num]
                # Crop coordinates: (x0, top, x1, bottom)
                cropped = page.crop((x1, y1, x2, y2))
                text = cropped.extract_text(x_tolerance=x_tolerance) or ""
                return text.strip()
        except Exception as e:
            print(f"Warning: Could not extract text from region: {e}")
            return None
    
    @staticmethod
    def extract_full_page_text(pdf_path: str, page_num: int = 0, x_tolerance: int = 1) -> str:
        """
        Extract all text from a PDF page.
        
        Args:
            pdf_path: Path to the PDF file
            page_num: Page number (0-indexed)
            x_tolerance: Tolerance for x-distance to insert spaces (default: 1)
            
        Returns:
            All text from the page
        """
        try:
            with pdfplumber.open(pdf_path) as pdf:
                if page_num >= len(pdf.pages):
                    return ""
                page = pdf.pages[page_num]
                text = page.extract_text(x_tolerance=x_tolerance) or ""
                return text
        except Exception as e:
            print(f"Warning: Could not extract page text: {e}")
            return ""
    
    def detect_company(self, pdf_path: str) -> Optional[str]:
        """
        Detect the company name by scanning coordinate regions.
        
        Args:
            pdf_path: Path to the PDF file
            
        Returns:
            Company name if detected, None otherwise
        """
        for company_config in self.companies_config:
            company_name = company_config.get("company", "")
            coordinates = company_config.get("coordinates", [])
            
            for coord in coordinates:
                # Support both coordinate formats:
                # Format: x0, y0, x1, y1 (from pdf_selector)
                
                x1 = coord.get("x0", 0)
                y1 = coord.get("y0", 0)
                x2 = coord.get("x1", 0)
                y2 = coord.get("y1", 0)
                
                # Page number is 1-indexed in config, convert to 0-indexed for internal use
                page = coord.get("page", 1) - 1
                
                text = self.extract_text_from_region(pdf_path, x1, y1, x2, y2, page_num=page, x_tolerance=self.x_tolerance)
                
                # Skip if page doesn't exist (not this company's format)
                if text is None:
                    continue
                
                # Check if company name appears in the extracted text (exact match)
                if company_name in text:
                    return company_name
        
        return None
    
    def detect_insurance_type(self, pdf_path: str, company_name: Optional[str]) -> Optional[str]:
        """
        Detect the insurance type by matching text representations.
        
        Args:
            pdf_path: Path to the PDF file
            company_name: Detected company name (used to get insurance type config)
            
        Returns:
            Insurance type ID if detected, None otherwise
        """
        if not company_name:
            return None
        
        # Find the company configuration
        company_config = None
        for config in self.companies_config:
            if config.get("company") == company_name:
                company_config = config
                break
        
        if not company_config:
            return None
        
        insurance_types = company_config.get("insurance_types", {})
        
        # Extract full page text for matching
        full_text = self.extract_full_page_text(pdf_path, x_tolerance=self.x_tolerance)
        
        # Try to match each insurance type
        for type_id, text_representations in insurance_types.items():
            for text_repr in text_representations:
                if text_repr in full_text:
                    return type_id
        
        print(f"  ❌ No insurance type matched for company '{company_name}'")
        return None
    
    def extract_metadata(self, pdf_path: str) -> Optional[MetaEntry]:
        """
        Extract all metadata from a PDF file.
        
        Args:
            pdf_path: Path to the PDF file
            
        Returns:
            MetaEntry with extracted metadata, or None if company/insurance type unknown
        """
        name = Path(pdf_path).name
        file_hash = self.compute_file_hash(pdf_path)

        company = self.detect_company(pdf_path)
        insurance_type = self.detect_insurance_type(pdf_path, company)
        
        # Skip if company or insurance type is unknown
        if not company or not insurance_type:
            return None
        
        return MetaEntry(
            name=name,
            file_hash=file_hash,
            company=company,
            insurance_type=insurance_type
        )


class MetaFileManager:
    """Manages the .meta file operations."""
    
    def __init__(self, watch_directory: str):
        """
        Initialize the meta file manager.
        Stats fresh (clears existing config) on startup.
        
        Args:
            watch_directory: Path to the watched directory
        """
        self.watch_directory = Path(watch_directory)
        self.meta_file_path = self.watch_directory / f"{self.watch_directory.name}.meta"
        self.entries: dict[str, MetaEntry] = {}
        # self.load() # Start fresh/clean on every run as requested
    
    def load(self) -> None:
        """Load existing entries from the .meta file."""
        # Method kept for reference but not used on startup to ensure clean state
        self.entries = {}
        
        if not self.meta_file_path.exists():
            return
        
        try:
            with open(self.meta_file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Split by separator
            blocks = content.split('---')
            
            for block in blocks:
                block = block.strip()
                if not block:
                    continue
                
                lines = block.split('\n')
                if len(lines) >= 4:
                    name = lines[0].strip()
                    file_hash = lines[1].strip()
                    company = lines[2].strip()
                    insurance_type = lines[3].strip()
                    
                    self.entries[name] = MetaEntry(
                        name=name,
                        file_hash=file_hash,
                        company=company,
                        insurance_type=insurance_type
                    )
        except Exception as e:
            print(f"Warning: Could not load .meta file: {e}")
    
    def save(self) -> None:
        """Save all entries to the .meta file."""
        try:
            with open(self.meta_file_path, 'w', encoding='utf-8') as f:
                for entry in self.entries.values():
                    f.write("---\n")
                    f.write(f"{entry.name}\n")
                    f.write(f"{entry.file_hash}\n")
                    f.write(f"{entry.company}\n")
                    f.write(f"{entry.insurance_type}\n")
        except Exception as e:
            print(f"Error: Could not save .meta file: {e}")
    
    def add_or_update(self, entry: MetaEntry, save_immediately: bool = True) -> None:
        """
        Add or update an entry in the .meta file.
        
        Args:
            entry: MetaEntry to add or update
            save_immediately: Whether to write to disk immediately
        """
        self.entries[entry.name] = entry
        if save_immediately:
            self.save()
        print(f"  ✓ Updated metadata for: {entry.name}")
    
    def remove(self, name: str) -> None:
        """
        Remove an entry from the .meta file.
        
        Args:
            name: Filename (without extension) to remove
        """
        if name in self.entries:
            del self.entries[name]
            self.save()
            print(f"  ✗ Removed metadata for: {name}")


class PDFEventHandler(FileSystemEventHandler):
    """Watchdog event handler for PDF file changes."""
    
    def __init__(self, extractor: PDFMetadataExtractor, meta_manager: MetaFileManager, watch_directory: str):
        """
        Initialize the event handler.
        
        Args:
            extractor: PDFMetadataExtractor instance
            meta_manager: MetaFileManager instance
            watch_directory: Path to the watched directory
        """
        super().__init__()
        self.extractor = extractor
        self.meta_manager = meta_manager
        self.watch_directory = Path(watch_directory)
    
    def _is_pdf_in_root(self, path: str) -> bool:
        """
        Check if a file is a PDF in the root directory (not subdirectory).
        
        Args:
            path: File path to check
            
        Returns:
            True if it's a PDF in the root directory
        """
        file_path = Path(path)
        
        # Check if it's a PDF file
        if file_path.suffix.lower() != '.pdf':
            return False
        
        # Check if it's in the root directory (not a subdirectory)
        if file_path.parent != self.watch_directory:
            return False
        
        return True
    
    def _process_pdf(self, path: str) -> None:
        """
        Process a PDF file and update metadata.
        
        Args:
            path: Path to the PDF file
        """
        try:
            print(f"\n📄 Processing: {Path(path).name}")
            entry = self.extractor.extract_metadata(path)
            
            if entry is None:
                print(f"  ⚠️ Skipped: Unknown company or insurance type")
                return
            
            print(f"  Company: {entry.company}")
            print(f"  Insurance Type: {entry.insurance_type}")
            self.meta_manager.add_or_update(entry)
        except Exception as e:
            print(f"Error processing {path}: {e}")
    
    def on_created(self, event) -> None:
        """Handle file creation events."""
        if event.is_directory:
            return
        
        if self._is_pdf_in_root(event.src_path):
            # Small delay to ensure file is fully written
            time.sleep(0.5)
            self._process_pdf(event.src_path)
    
    def on_modified(self, event) -> None:
        """Handle file modification events."""
        if event.is_directory:
            return
        
        if self._is_pdf_in_root(event.src_path):
            # Small delay to ensure file is fully written
            time.sleep(0.5)
            self._process_pdf(event.src_path)
    
    def on_deleted(self, event) -> None:
        """Handle file deletion events."""
        if event.is_directory:
            return
        
        file_path = Path(event.src_path)
        
        if file_path.suffix.lower() == '.pdf' and file_path.parent == self.watch_directory:
            name = file_path.stem
            print(f"\n🗑️ Deleted: {file_path.name}")
            self.meta_manager.remove(name)


def process_existing_pdfs(watch_directory: str, extractor: PDFMetadataExtractor, meta_manager: MetaFileManager) -> None:
    """
    Process all existing PDF files in the directory.
    
    Args:
        watch_directory: Path to the watched directory
        extractor: PDFMetadataExtractor instance
        meta_manager: MetaFileManager instance
    """
    watch_path = Path(watch_directory)
    pdf_files = list(watch_path.glob("*.pdf"))
    
    if pdf_files:
        print(f"\n📂 Processing {len(pdf_files)} existing PDF file(s)...")
        
        count = 0
        for pdf_file in pdf_files:
            try:
                print(f"\n📄 Processing: {pdf_file.name}")
                entry = extractor.extract_metadata(str(pdf_file))
                
                if entry is None:
                    print(f"  ⚠️ Skipped: Unknown company or insurance type")
                    continue
                
                print(f"  Company: {entry.company}")
                print(f"  Insurance Type: {entry.insurance_type}")
                # Don't save immediately, wait for batch
                meta_manager.add_or_update(entry, save_immediately=False)
                count += 1
            except Exception as e:
                print(f"Error processing {pdf_file}: {e}")
        
        # Save all at once after processing existing files
        if count > 0:
            meta_manager.save()
            print(f"\n💾 Saved {count} entries to .meta file")


def load_companies_config(config_path: str) -> list:
    """
    Load companies configuration from JSON file.
    
    Args:
        config_path: Path to companies.json
        
    Returns:
        List of company configurations
    """
    with open(config_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def main():
    parser = argparse.ArgumentParser(
        description='Watch a directory and extract metadata from PDF files'
    )
    parser.add_argument(
        'directory',
        help='Directory to watch for PDF files'
    )
    parser.add_argument(
        '--companies', '-c',
        default='companies.json',
        help='Path to companies.json configuration file (default: companies.json)'
    )
    parser.add_argument(
        '--x_tolerance', '-x',
        type=int,
        default=1,
        help='Tolerance for x-distance to insert spaces (default: 1)'
    )
    
    args = parser.parse_args()
    
    # Validate directory
    watch_directory = Path(args.directory).resolve()
    if not watch_directory.exists():
        print(f"Error: Directory does not exist: {watch_directory}")
        sys.exit(1)
    
    if not watch_directory.is_dir():
        print(f"Error: Path is not a directory: {watch_directory}")
        sys.exit(1)
    
    # Load companies configuration
    try:
        companies_config = load_companies_config(args.companies)
        print(f"✓ Loaded {len(companies_config)} company configuration(s)")
    except FileNotFoundError:
        print(f"Error: Companies config file not found: {args.companies}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in companies config: {e}")
        sys.exit(1)
    
    # Initialize components
    extractor = PDFMetadataExtractor(companies_config, x_tolerance=args.x_tolerance)
    meta_manager = MetaFileManager(str(watch_directory))
    event_handler = PDFEventHandler(extractor, meta_manager, str(watch_directory))
    
    # Process existing PDFs
    process_existing_pdfs(str(watch_directory), extractor, meta_manager)
    
    # Set up the observer
    observer = Observer()
    observer.schedule(event_handler, str(watch_directory), recursive=False)
    
    print(f"\n👁️ Watching directory: {watch_directory}")
    print(f"📋 Meta file: {meta_manager.meta_file_path}")
    print("\nPress Ctrl+C to stop...\n")
    
    observer.start()
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n\n🛑 Stopping watcher...")
        observer.stop()
    
    observer.join()
    print("✓ Watcher stopped.")


if __name__ == "__main__":
    main()
