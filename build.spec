# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

# CLI-only optimized spec file for PDF data extractor
# This version excludes all GUI dependencies for minimal size and fast startup

a = Analysis(
    ['pdf_data_extractor.py'],
    pathex=[],
    binaries=[],
    datas=[],  # No locale files needed for CLI
    hiddenimports=[
        'pdfplumber',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        # GUI frameworks
        'tkinter',
        'tk',
        '_tkinter',
        'Tkinter',
        # Image processing (not needed for text extraction)
        'PIL',
        'Pillow',
        'PIL.Image',
        'PIL.ImageTk',
        # PDF rendering (using pdfplumber instead)
        'fitz',
        'pymupdf',
        'PyMuPDF',
        # Scientific/data libraries
        'matplotlib',
        'numpy',
        'pandas',
        'scipy',
        'sklearn',
        'cv2',
        'opencv',
        # Development/testing
        'pytest',
        'IPython',
        'jupyter',
        'notebook',
        'sphinx',
        'test',
        'unittest',
        'doctest',
        # Other heavy dependencies
        'PyQt5',
        'PyQt6',
        'PySide2',
        'PySide6',
        'wx',
        'wxPython',
    ],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='PDF-Extractor-CLI',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,  # Disabled to prevent DLL loading issues
    upx=True,     # Keep UPX compression for size reduction
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,  # Console application
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
