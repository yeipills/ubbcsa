#!/bin/bash
set -e

echo "Starting JavaScript file encoding fix..."

# List of files to check and fix
FILES=(
  /app/app/javascript/controllers/quiz_form_controller.js
  /app/app/javascript/controllers/quiz_preguntas_controller.js
  /app/app/javascript/controllers/quiz_timer_controller.js
  /app/app/javascript/controllers/quiz_controller.js
)

# Function to check if a file has encoding issues
check_file() {
  local file=$1
  echo "Checking encoding for $file"
  
  # Use iconv to check if file has invalid UTF-8 sequences
  if ! iconv -f UTF-8 -t UTF-8 "$file" >/dev/null 2>&1; then
    echo "Found encoding issues in $file"
    return 0
  else
    echo "No encoding issues found in $file"
    return 1
  fi
}

# Function to fix encoding issues
fix_file() {
  local file=$1
  echo "Fixing encoding for $file"
  
  # Create a backup
  cp "$file" "${file}.bak"
  
  # Try to convert from ISO-8859-1 (Latin1) to UTF-8
  iconv -f ISO-8859-1 -t UTF-8 "${file}.bak" > "$file" || echo "Warning: Could not convert file $file"
  
  # Remove backup
  rm "${file}.bak"
}

# Check and fix each file
for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    if check_file "$file"; then
      fix_file "$file"
      echo "Fixed encoding for $file"
    fi
  else
    echo "File $file not found, skipping"
  fi
done

echo "JavaScript encoding fix completed"