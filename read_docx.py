import sys
from docx import Document

def main():
    if len(sys.argv) < 3:
        print("Usage: python read_docx.py <path_to_docx> <output_txt>")
        return
    
    doc_path = sys.argv[1]
    out_path = sys.argv[2]
    try:
        doc = Document(doc_path)
        with open(out_path, 'w', encoding='utf-8') as f:
            for para in doc.paragraphs:
                f.write(para.text + "\n")
        print("Success")
    except Exception as e:
        print(f"Error reading docx: {e}")

if __name__ == "__main__":
    main()
