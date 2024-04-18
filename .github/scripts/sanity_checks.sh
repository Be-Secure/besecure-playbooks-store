#!/bin/bash

# Define the required functions
required_functions=$(cat playbook_functions.txt)

# Get the list of modified or added files in the pull request
modified_files=$(git diff --name-only origin/main...HEAD)

# Flag to track if all required functions are present
all_functions_present=true

# Iterate over the modified files
for file in $modified_files; do
  # Check if the file is a Bash script
  if [[ $file == *.sh ]]; then
    # Check if all required functions are present in the file
    for function in "${required_functions[@]}"; do
      if ! grep -q "function $function" "$file"; then
        echo "Required function $function is missing in $file"
        all_functions_present=false
      fi
    done
  fi
done

# Exit with appropriate status code
if $all_functions_present; then
  echo "All required functions are present"
  exit 0
else
  echo "Some required functions are missing"
  exit 1
fi