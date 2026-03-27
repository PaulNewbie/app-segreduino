#!/bin/bash

# Ensure the script is run from the root of the Flutter project
if [ ! -d "lib" ]; then
  echo "❌ Error: 'lib' directory not found. Please run this inside your Flutter project root."
  exit 1
fi

echo "🚀 Refactoring API paths across all Dart files..."

# Define the endpoints that moved to controllers/Api/
API_ENDPOINTS=(
  "login_api.php"
  "facebook_login_api.php"
  "register_api.php"
  "tasks_api.php"
)

# Define the endpoints that moved to controllers/Actions/
ACTION_ENDPOINTS=(
  "add_kiosk.php"
  "update_profile.php"
  "verify_code.php"
  "verify_code_and_reset.php"
  "verification_email.php"
  "mark_task_done.php"
)

# Replace API Endpoints
# Note: We use # as the sed delimiter so we don't have to escape forward slashes
for endpoint in "${API_ENDPOINTS[@]}"; do
  echo "Mapping $endpoint -> controllers/Api/$endpoint"
  find lib/ -type f -name "*.dart" -exec sed -i 's#${ApiConfig.baseUrl}/'"$endpoint"'#${ApiConfig.baseUrl}/controllers/Api/'"$endpoint"'#g' {} +
done

# Replace Action Endpoints
for endpoint in "${ACTION_ENDPOINTS[@]}"; do
  echo "Mapping $endpoint -> controllers/Actions/$endpoint"
  find lib/ -type f -name "*.dart" -exec sed -i 's#${ApiConfig.baseUrl}/'"$endpoint"'#${ApiConfig.baseUrl}/controllers/Actions/'"$endpoint"'#g' {} +
done

echo "✅ Endpoint refactoring complete!"

