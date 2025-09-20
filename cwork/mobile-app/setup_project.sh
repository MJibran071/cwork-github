#!/bin/bash
# setup_project.sh - Complete project setup script

echo "🚀 Setting up Flutter project..."

# Make scripts executable
chmod +x install_dependencies.sh
chmod +x pubspec_manager.py

# Install dependencies
./install_dependencies.sh

# Generate dependency report
python3 pubspec_manager.py

echo "✅ Project setup complete!"
echo "📊 Review DEPENDENCY_REPORT.md for package information"