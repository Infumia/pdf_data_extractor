import tkinter as tk
from tkinter import filedialog, messagebox, simpledialog
import fitz  # pymupdf
from PIL import Image, ImageTk
import sys
import json
import os

def load_properties(filepath):
    """Load properties from a .properties file"""
    properties = {}
    if not os.path.exists(filepath):
        return properties
    
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                properties[key.strip()] = value.strip()
    return properties

def load_translations():
    """Load all translations from locale folder"""
    translations = {}
    locale_dir = os.path.join(os.path.dirname(__file__), 'locale')
    
    if os.path.exists(locale_dir):
        for filename in os.listdir(locale_dir):
            if filename.endswith('.properties'):
                lang_code = filename.replace('.properties', '').upper()
                filepath = os.path.join(locale_dir, filename)
                translations[lang_code] = load_properties(filepath)
    
    return translations

TRANSLATIONS = load_translations()

class PDFSelector:
    def __init__(self, root):
        self.root = root
        self.current_language = 'EN_US'
        self.root.title(self.t('title'))
        
        self.doc = None
        self.current_page_num = 0
        self.scale = 1.0
        self.image_ref = None # Keep reference to avoid garbage collection
        self.selections = []  # List to store all selections
        self.last_saved_file = None  # Track the last saved file path
        
        # UI Elements
        self.frame_controls = tk.Frame(root)
        self.frame_controls.pack(side=tk.TOP, fill=tk.X)
        
        self.btn_open = tk.Button(self.frame_controls, text=self.t('open_pdf'), command=self.open_pdf)
        self.btn_open.pack(side=tk.LEFT, padx=5, pady=5)
        
        self.btn_prev = tk.Button(self.frame_controls, text=self.t('prev'), command=self.prev_page, state=tk.DISABLED)
        self.btn_prev.pack(side=tk.LEFT, padx=5, pady=5)
        
        self.lbl_page = tk.Label(self.frame_controls, text=f"{self.t('page')}: 0/0")
        self.lbl_page.pack(side=tk.LEFT, padx=5, pady=5)
        
        self.btn_next = tk.Button(self.frame_controls, text=self.t('next'), command=self.next_page, state=tk.DISABLED)
        self.btn_next.pack(side=tk.LEFT, padx=5, pady=5)

        self.btn_save = tk.Button(self.frame_controls, text=self.t('save'), command=self.save_selections, bg="green", fg="white")
        self.btn_save.pack(side=tk.LEFT, padx=5, pady=5)

        self.btn_save_as = tk.Button(self.frame_controls, text=self.t('save_as'), command=self.save_as_selections, bg="darkgreen", fg="white")
        self.btn_save_as.pack(side=tk.LEFT, padx=5, pady=5)

        self.btn_extract = tk.Button(self.frame_controls, text=self.t('extract'), command=self.extract_data, bg="blue", fg="white")
        self.btn_extract.pack(side=tk.LEFT, padx=20, pady=5)

        self.lbl_selections = tk.Label(self.frame_controls, text=f"{self.t('selections')}: 0", font=("Consolas", 10, "bold"))
        self.lbl_selections.pack(side=tk.LEFT, padx=20, pady=5)

        # Language selector
        self.btn_language = tk.Button(self.frame_controls, text=self.t('language'), command=self.toggle_language)
        self.btn_language.pack(side=tk.RIGHT, padx=5, pady=5)
        
        self.canvas_frame = tk.Frame(root)
        self.canvas_frame.pack(fill=tk.BOTH, expand=True)

        self.v_scroll = tk.Scrollbar(self.canvas_frame, orient=tk.VERTICAL)
        self.h_scroll = tk.Scrollbar(self.canvas_frame, orient=tk.HORIZONTAL)
        
        self.canvas = tk.Canvas(self.canvas_frame, bg="gray", 
                                yscrollcommand=self.v_scroll.set, 
                                xscrollcommand=self.h_scroll.set,
                                cursor="cross")
        
        self.v_scroll.config(command=self.canvas.yview)
        self.h_scroll.config(command=self.canvas.xview)
        
        self.v_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        self.h_scroll.pack(side=tk.BOTTOM, fill=tk.X)
        self.canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        # Mouse events
        self.canvas.bind("<ButtonPress-1>", self.on_mouse_down)
        self.canvas.bind("<B1-Motion>", self.on_mouse_drag)
        self.canvas.bind("<ButtonRelease-1>", self.on_mouse_up)
        self.canvas.bind("<ButtonPress-3>", self.on_right_click)  # Right-click to remove selection
        self.canvas.bind("<Motion>", self.on_mouse_motion)  # Track mouse for tooltips
        
        # Zoom event
        self.canvas.bind("<Control-MouseWheel>", self.on_zoom)
        
        self.current_rect = None
        self.start_x = 0
        self.start_y = 0

    def t(self, key):
        """Get translation for the current language"""
        return TRANSLATIONS[self.current_language].get(key, key)

    def toggle_language(self):
        """Toggle between EN_US and TR"""
        self.current_language = 'TR' if self.current_language == 'EN_US' else 'EN_US'
        self.update_ui_language()

    def update_ui_language(self):
        """Update all UI text with current language"""
        self.root.title(self.t('title'))
        self.btn_open.config(text=self.t('open_pdf'))
        self.btn_prev.config(text=self.t('prev'))
        self.btn_next.config(text=self.t('next'))
        self.btn_save.config(text=self.t('save'))
        self.btn_save_as.config(text=self.t('save_as'))
        self.btn_extract.config(text=self.t('extract'))
        self.btn_language.config(text=self.t('language'))
        
        # Update page label if document is loaded
        if self.doc:
            self.lbl_page.config(text=f"{self.t('page')}: {self.current_page_num + 1}/{len(self.doc)} | {self.t('zoom')}: {int(self.scale * 100)}%")
        else:
            self.lbl_page.config(text=f"{self.t('page')}: 0/0")
        
        # Update selections label
        self.lbl_selections.config(text=f"{self.t('selections')}: {len(self.selections)}")

    def open_pdf(self):
        file_path = filedialog.askopenfilename(filetypes=[("PDF Files", "*.pdf")])
        if file_path:
            try:
                self.doc = fitz.open(file_path)
                self.current_page_num = 0
                self.scale = 1.0 # Reset scale on new file
                self.show_page(0)
                self.update_controls()
            except Exception as e:
                messagebox.showerror(self.t('error'), self.t('error_opening_pdf').format(error=e))

    def show_page(self, page_num):
        if not self.doc:
            return
            
        page = self.doc.load_page(page_num)
        # Use matrix for scaling
        mat = fitz.Matrix(self.scale, self.scale)
        pix = page.get_pixmap(matrix=mat)
        
        # Convert to PIL Image then ImageTk
        img_data = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
        self.image_ref = ImageTk.PhotoImage(img_data)
        
        self.canvas.delete("all")
        self.canvas.create_image(0, 0, image=self.image_ref, anchor=tk.NW)
        self.canvas.config(scrollregion=(0, 0, pix.width, pix.height))
        
        self.lbl_page.config(text=f"{self.t('page')}: {page_num + 1}/{len(self.doc)} | {self.t('zoom')}: {int(self.scale * 100)}%")
        
        # Redraw all selections for the current page
        self.redraw_selections()

    def prev_page(self):
        if self.current_page_num > 0:
            self.current_page_num -= 1
            self.show_page(self.current_page_num)
            self.update_controls()

    def next_page(self):
        if self.doc and self.current_page_num < len(self.doc) - 1:
            self.current_page_num += 1
            self.show_page(self.current_page_num)
            self.update_controls()
            
    def on_zoom(self, event):
        if not self.doc:
            return
            
        # Respond to Windows mouse wheel event
        if event.delta > 0:
            self.scale *= 1.1
        else:
            self.scale /= 1.1
            
        # Limit scale
        if self.scale < 0.1: self.scale = 0.1
        if self.scale > 5.0: self.scale = 5.0
        
        self.show_page(self.current_page_num)

    def redraw_selections(self):
        """Redraw all selection rectangles on the current page at the current scale"""
        for sel in self.selections:
            # Only draw selections for the current page
            if sel['page'] == self.current_page_num + 1:
                # Calculate canvas coordinates at current scale
                x0_canvas = sel['x0'] * self.scale
                y0_canvas = sel['y0'] * self.scale
                x1_canvas = sel['x1'] * self.scale
                y1_canvas = sel['y1'] * self.scale
                
                # Create new rectangle
                rect_id = self.canvas.create_rectangle(x0_canvas, y0_canvas, x1_canvas, y1_canvas, outline="red", width=2)
                
                # Update stored values
                sel['rect_id'] = rect_id
                sel['x0_canvas'] = x0_canvas
                sel['y0_canvas'] = y0_canvas
                sel['x1_canvas'] = x1_canvas
                sel['y1_canvas'] = y1_canvas

    def update_controls(self):
        if not self.doc:
            self.btn_prev.config(state=tk.DISABLED)
            self.btn_next.config(state=tk.DISABLED)
            return
            
        self.btn_prev.config(state=tk.NORMAL if self.current_page_num > 0 else tk.DISABLED)
        self.btn_next.config(state=tk.NORMAL if self.current_page_num < len(self.doc) - 1 else tk.DISABLED)

    def on_mouse_down(self, event):
        self.start_x = self.canvas.canvasx(event.x)
        self.start_y = self.canvas.canvasy(event.y)
        
        # Create new rectangle for new selection
        self.current_rect = self.canvas.create_rectangle(self.start_x, self.start_y, self.start_x, self.start_y, outline="red", width=2)

    def on_mouse_drag(self, event):
        cur_x = self.canvas.canvasx(event.x)
        cur_y = self.canvas.canvasy(event.y)
        
        if self.current_rect:
            self.canvas.coords(self.current_rect, self.start_x, self.start_y, cur_x, cur_y)

    def on_mouse_up(self, event):
        end_x = self.canvas.canvasx(event.x)
        end_y = self.canvas.canvasy(event.y)
        
        # Normalize coordinates (ensure x0 < x1, y0 < y1)
        x0_canvas = min(self.start_x, end_x)
        y0_canvas = min(self.start_y, end_y)
        x1_canvas = max(self.start_x, end_x)
        y1_canvas = max(self.start_y, end_y)
        
        # Adjust for scale to get PDF coordinates
        x0 = x0_canvas / self.scale
        y0 = y0_canvas / self.scale
        x1 = x1_canvas / self.scale
        y1 = y1_canvas / self.scale
        
        # Ask for label name
        label_name = simpledialog.askstring(self.t('label_prompt_title'), self.t('label_prompt_message'))
        
        if label_name:
            # Store the selection
            selection = {
                'rect_id': self.current_rect,
                'x0': x0,
                'y0': y0,
                'x1': x1,
                'y1': y1,
                'x0_canvas': x0_canvas,
                'y0_canvas': y0_canvas,
                'x1_canvas': x1_canvas,
                'y1_canvas': y1_canvas,
                'label': label_name,
                'page': self.current_page_num + 1
            }
            self.selections.append(selection)
            
            # Update UI
            self.lbl_selections.config(text=f"{self.t('selections')}: {len(self.selections)}")
            
            coords_str = f"x0={x0:.2f}, y0={y0:.2f}, x1={x1:.2f}, y1={y1:.2f}"
            cmd_args = f"--x0 {x0:.2f} --y0 {y0:.2f} --x1 {x1:.2f} --y1 {y1:.2f}"
            
            print(f"{self.t('added_selection')} '{label_name}' ({self.t('page')} {self.current_page_num + 1}): {coords_str}")
            print(f"Command Args: {cmd_args}")
        else:
            # Remove rectangle if no label provided
            if self.current_rect:
                self.canvas.delete(self.current_rect)
        
        self.current_rect = None

    def on_right_click(self, event):
        """Remove the selection at the click position"""
        click_x = self.canvas.canvasx(event.x)
        click_y = self.canvas.canvasy(event.y)
        
        # Find which selection was clicked
        for i, sel in enumerate(self.selections):
            if (sel['x0_canvas'] <= click_x <= sel['x1_canvas'] and 
                sel['y0_canvas'] <= click_y <= sel['y1_canvas']):
                # Remove the rectangle from canvas
                self.canvas.delete(sel['rect_id'])
                # Remove from selections list
                removed = self.selections.pop(i)
                print(f"{self.t('removed_selection')} '{removed['label']}'")
                
                # Update UI
                self.lbl_selections.config(text=f"{self.t('selections')}: {len(self.selections)}")
                break

    def on_mouse_motion(self, event):
        """Show tooltip when hovering over a selection"""
        # Remove all existing tooltips by tag
        self.canvas.delete("tooltip")
        
        # Get mouse position
        mouse_x = self.canvas.canvasx(event.x)
        mouse_y = self.canvas.canvasy(event.y)
        
        # Check if mouse is over any selection on current page
        for sel in self.selections:
            if sel['page'] == self.current_page_num + 1:
                if (sel['x0_canvas'] <= mouse_x <= sel['x1_canvas'] and 
                    sel['y0_canvas'] <= mouse_y <= sel['y1_canvas']):
                    # Show tooltip with label
                    text_id = self.canvas.create_text(
                        mouse_x, 
                        sel['y0_canvas'] - 10,  # Position above the selection
                        text=sel['label'],
                        fill="black",
                        font=("Arial", 10, "bold"),
                        tags="tooltip",
                        anchor="s"
                    )
                    # Add background rectangle for better visibility
                    bbox = self.canvas.bbox(text_id)
                    if bbox:
                        self.canvas.create_rectangle(
                            bbox[0] - 2, bbox[1] - 2,
                            bbox[2] + 2, bbox[3] + 2,
                            fill="yellow",
                            outline="black",
                            tags="tooltip"
                        )
                        # Raise text above background
                        self.canvas.tag_raise(text_id)
                    break

    def save_selections(self):
        """Save all selections to the last saved file or prompt for new file"""
        if not self.selections:
            messagebox.showwarning(self.t('no_selections_title'), self.t('no_selections_message'))
            return
        
        # If no file has been saved yet, prompt for file picker
        if self.last_saved_file is None:
            self.save_as_selections()
        else:
            # Save to the last saved file
            self._save_to_file(self.last_saved_file)

    def save_as_selections(self):
        """Always prompt for file picker and save selections"""
        if not self.selections:
            messagebox.showwarning(self.t('no_selections_title'), self.t('no_selections_message'))
            return
        
        file_path = filedialog.asksaveasfilename(
            defaultextension=".json",
            filetypes=[("JSON Files", "*.json"), ("All Files", "*.*")],
            title=self.t('save_title')
        )
        
        if file_path:
            self._save_to_file(file_path)

    def _save_to_file(self, file_path):
        """Internal method to save selections to a specific file"""
        # Prepare data for JSON (exclude canvas-specific data)
        output_data = []
        for sel in self.selections:
            output_data.append({
                'label': sel['label'],
                'page': sel['page'],
                'coordinates': {
                    'x0': round(sel['x0'], 2),
                    'y0': round(sel['y0'], 2),
                    'x1': round(sel['x1'], 2),
                    'y1': round(sel['y1'], 2)
                }
            })
        
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(output_data, f, indent=2, ensure_ascii=False)
            
            # Update last saved file
            self.last_saved_file = file_path
            
            messagebox.showinfo(self.t('success'), self.t('saved_message').format(count=len(self.selections), path=file_path))
            print(f"{self.t('saved_message').format(count=len(self.selections), path=file_path)}")
        except Exception as e:
            messagebox.showerror(self.t('error'), self.t('error_saving').format(error=e))

    def extract_data(self):
        """Extract data from the current PDF using selections"""
        if not self.doc:
            messagebox.showwarning(self.t('error'), self.t('extract_no_pdf'))
            return
        
        if not self.selections:
            messagebox.showwarning(self.t('no_selections_title'), self.t('extract_no_selections'))
            return
        
        try:
            # Import extraction function
            from pdf_data_extractor import extract_data_from_pdf
            import tempfile
            
            # Save current selections to a temporary file
            with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False, encoding='utf-8') as temp_file:
                temp_selections = []
                for sel in self.selections:
                    temp_selections.append({
                        'label': sel['label'],
                        'page': sel['page'],
                        'coordinates': {
                            'x0': round(sel['x0'], 2),
                            'y0': round(sel['y0'], 2),
                            'x1': round(sel['x1'], 2),
                            'y1': round(sel['y1'], 2)
                        }
                    })
                json.dump(temp_selections, temp_file, indent=2, ensure_ascii=False)
                temp_path = temp_file.name
            
            # Get the PDF file path
            pdf_path = self.doc.name
            
            # Extract data
            extracted_data = extract_data_from_pdf(pdf_path, temp_path, x_tolerance=1)
            
            # Clean up temp file
            import os
            os.unlink(temp_path)
            
            # Show extracted data in a dialog
            self.show_extracted_data_dialog(extracted_data)
            
        except Exception as e:
            messagebox.showerror(self.t('error'), self.t('extract_error').format(error=e))
            print(f"Error: {e}")

    def show_extracted_data_dialog(self, data):
        """Show extracted data in a dialog window"""
        dialog = tk.Toplevel(self.root)
        dialog.title(self.t('extract_title'))
        dialog.geometry("650x500")
        
        # Button frame at bottom
        btn_frame = tk.Frame(dialog)
        btn_frame.pack(side=tk.BOTTOM, fill=tk.X, padx=10, pady=10)
        
        # Copy to clipboard button
        def copy_to_clipboard():
            content = ""
            for label, value in data.items():
                content += f"{label}:\n  {value}\n\n"
            self.root.clipboard_clear()
            self.root.clipboard_append(content)
            messagebox.showinfo(self.t('success'), self.t('copied_to_clipboard'))
        
        # Save to file button
        def save_to_file():
            file_path = filedialog.asksaveasfilename(
                defaultextension=".json",
                filetypes=[("JSON Files", "*.json"), ("Text Files", "*.txt"), ("All Files", "*.*")],
                title=self.t('save_title')
            )
            if file_path:
                try:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        if file_path.endswith('.json'):
                            json.dump(data, f, indent=2, ensure_ascii=False)
                        else:
                            for label, value in data.items():
                                f.write(f"{label}:\n  {value}\n\n")
                    messagebox.showinfo(self.t('success'), self.t('saved_message').format(count=len(data), path=file_path))
                except Exception as e:
                    messagebox.showerror(self.t('error'), self.t('error_saving').format(error=e))
        
        btn_copy = tk.Button(btn_frame, text=self.t('copy_clipboard'), command=copy_to_clipboard, bg="orange", fg="white", font=("Arial", 10))
        btn_copy.pack(side=tk.LEFT, padx=5)
        
        btn_save = tk.Button(btn_frame, text=self.t('save'), command=save_to_file, bg="green", fg="white", font=("Arial", 10))
        btn_save.pack(side=tk.LEFT, padx=5)
        
        btn_close = tk.Button(btn_frame, text=self.t('close'), command=dialog.destroy, bg="gray", fg="white", font=("Arial", 10))
        btn_close.pack(side=tk.RIGHT, padx=5)
        
        # Create frame for scrollable content (fills remaining space)
        frame = tk.Frame(dialog)
        frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=(10, 0))
        
        # Add scrollbar
        scrollbar = tk.Scrollbar(frame)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Create text widget to display data
        text_widget = tk.Text(frame, wrap=tk.WORD, yscrollcommand=scrollbar.set, font=("Consolas", 10))
        text_widget.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.config(command=text_widget.yview)
        
        # Format and insert data
        for label, value in data.items():
            text_widget.insert(tk.END, f"{label}:\n", "label")
            text_widget.insert(tk.END, f"  {value}\n\n", "value")
        
        # Configure text tags for styling
        text_widget.tag_config("label", font=("Consolas", 11, "bold"), foreground="blue")
        text_widget.tag_config("value", font=("Consolas", 10))
        
        # Make text read-only
        text_widget.config(state=tk.DISABLED)


if __name__ == "__main__":
    root = tk.Tk()
    root.geometry("1000x800")
    app = PDFSelector(root)
    root.mainloop()
