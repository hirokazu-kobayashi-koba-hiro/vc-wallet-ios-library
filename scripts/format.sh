#!/bin/bash

# Check if swift-format is installed
if ! command -v swift-format &> /dev/null
then
    echo "swift-format could not be found. Please install it using 'brew install swift-format'."
    exit
fi

# Directory to format, default to current directory if none provided
TARGET_DIR=${1:-.}

# Find all .swift files in the target directory and apply swift-format to them
echo "Formatting all Swift files in $TARGET_DIR..."
find "$TARGET_DIR" -name "*.swift" | while read file; do
    echo "Formatting $file..."
    swift-format format --in-place "$file"
done

echo "Swift format completed."
