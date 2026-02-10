#!/bin/bash
# PDF Signing Helper - Opens PDF in Xournal++ for signing/annotation
# Usage: pdf-sign <file.pdf>
#        pdf-sign                  # Opens file picker

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if xournalpp is installed
if ! command -v xournalpp &> /dev/null; then
    print_error "Xournal++ is not installed"
    echo "Install with: sudo apt install xournalpp"
    exit 1
fi

# Get PDF file
PDF_FILE="$1"

if [[ -z "$PDF_FILE" ]]; then
    # No argument - try to use zenity file picker if available
    if command -v zenity &> /dev/null; then
        PDF_FILE=$(zenity --file-selection --title="Select PDF to sign" --file-filter="PDF files (*.pdf)|*.pdf" 2>/dev/null)
        if [[ -z "$PDF_FILE" ]]; then
            print_warn "No file selected"
            exit 0
        fi
    else
        echo "Usage: pdf-sign <file.pdf>"
        echo ""
        echo "Tips for signing in Xournal++:"
        echo "  1. Use Text tool (T) to add date"
        echo "  2. Use Pen tool to draw signature"
        echo "  3. Or Image tool to insert signature image"
        echo "  4. File > Export as PDF to save"
        exit 1
    fi
fi

# Validate file
if [[ ! -f "$PDF_FILE" ]]; then
    print_error "File not found: $PDF_FILE"
    exit 1
fi

if [[ "${PDF_FILE##*.}" != "pdf" && "${PDF_FILE##*.}" != "PDF" ]]; then
    print_warn "File may not be a PDF: $PDF_FILE"
fi

# Open in Xournal++
print_info "Opening in Xournal++: $PDF_FILE"
echo ""
echo "Quick tips:"
echo "  - Text tool (T): Add date/text"
echo "  - Pen tool: Draw signature"
echo "  - Image tool: Insert signature image"
echo "  - Export: File > Export as PDF"
echo ""

xournalpp "$PDF_FILE" &
disown

print_info "Xournal++ opened in background"
