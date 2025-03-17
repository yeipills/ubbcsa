#!/bin/bash
set -e

echo "Starting assets precompilation..."

# Double check JavaScript file encoding
echo "Double checking JavaScript file encoding..."
if [ -f "/app/docker_fix_encoding.sh" ]; then
  bash /app/docker_fix_encoding.sh
fi

# First try - normal precompile
echo "Running assets:precompile in development mode..."
RAILS_ENV=development bundle exec rake assets:precompile || {
  echo "Assets precompilation failed, trying alternate approach..."
  
  # Try a different approach - compile only what's needed
  RAILS_ENV=development bundle exec rake assets:precompile:primary || {
    echo "All attempts to precompile assets failed."
    exit 1
  }
}

echo "Assets precompilation completed successfully!"
exit 0