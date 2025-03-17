
#!/bin/bash
# Encoding fix script
# This corrects any encoding issues in JavaScript files

# A better approach: convert all files to UTF-8
for file in $(find ./app/javascript -name "*.js" -type f 2>/dev/null); do
  # First, create a backup
  cp "$file" "${file}.bak"
  
  # Try to ensure UTF-8 encoding
  iconv -f ISO-8859-1 -t UTF-8 "${file}.bak" > "$file" 2>/dev/null || cp "${file}.bak" "$file"
  
  # Use tr to remove any problematic characters
  tr -cd '\11\12\15\40-\176\u00C0-\u00ff' < "$file" > "${file}.clean"
  mv "${file}.clean" "$file"
  
  # Remove backup
  rm "${file}.bak"
done

echo "Encoding conversion complete"

