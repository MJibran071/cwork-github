#!/bin/bash

# install_dependencies.sh
# Auto-dependency download and management script for Flutter projects
# Usage: ./install_dependencies.sh [--clean] [--force] [--ios] [--android]

set -e # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLUTTER_CMD="flutter"
POD_CMD="pod"
PLATFORMS=("ios" "android")
CLEAN=false
FORCE=false
TARGET_PLATFORMS=()

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --clean)
      CLEAN=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --ios)
      TARGET_PLATFORMS=("ios")
      shift
      ;;
    --android)
      TARGET_PLATFORMS=("android")
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

# If no specific platforms are targeted, use all
if [ ${#TARGET_PLATFORMS[@]} -eq 0 ]; then
    TARGET_PLATFORMS=("${PLATFORMS[@]}")
fi

# Function to print status messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
check_flutter() {
    if ! command -v $FLUTTER_CMD &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    print_status "Flutter found: $(which $FLUTTER_CMD)"
}

# Clean build directories if requested
clean_build() {
    if [ "$CLEAN" = true ]; then
        print_status "Cleaning build directories..."
        $FLUTTER_CMD clean
        rm -rf .dart_tool/
        rm -rf .packages
        rm -rf pubspec.lock
    fi
}

# Get Flutter dependencies
get_flutter_deps() {
    print_status "Getting Flutter dependencies..."
    
    if [ "$FORCE" = true ]; then
        $FLUTTER_CMD pub get --force
    else
        $FLUTTER_CMD pub get
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Flutter dependencies downloaded successfully"
    else
        print_error "Failed to get Flutter dependencies"
        exit 1
    fi
}

# Install iOS dependencies
install_ios_deps() {
    if [[ " ${TARGET_PLATFORMS[@]} " =~ " ios " ]]; then
        if [ -d "ios" ]; then
            print_status "Installing iOS CocoaPods dependencies..."
            cd ios
            if command -v $POD_CMD &> /dev/null; then
                $POD_CMD install --repo-update
                if [ $? -eq 0 ]; then
                    print_success "iOS dependencies installed successfully"
                else
                    print_error "Failed to install iOS dependencies"
                    exit 1
                fi
            else
                print_warning "CocoaPods not found, skipping iOS dependency installation"
            fi
            cd ..
        else
            print_warning "iOS directory not found, skipping iOS dependencies"
        fi
    fi
}

# Install Android dependencies
install_android_deps() {
    if [[ " ${TARGET_PLATFORMS[@]} " =~ " android " ]]; then
        if [ -d "android" ]; then
            print_status "Checking Android Gradle dependencies..."
            cd android
            ./gradlew build --refresh-dependencies || true
            cd ..
            print_success "Android dependencies checked"
        else
            print_warning "Android directory not found, skipping Android dependencies"
        fi
    fi
}

# Generate native platform files
generate_native_files() {
    print_status "Generating platform-specific files..."
    $FLUTTER_CMD pub run flutter_launcher_icons:main || true
    $FLUTTER_CMD pub run build_runner build --delete-conflicting-outputs || true
}

# Verify dependencies
verify_dependencies() {
    print_status "Verifying dependencies..."
    $FLUTTER_CMD pub outdated || true
    $FLUTTER_CMD pub deps > dependency_tree.txt
    print_success "Dependency tree saved to dependency_tree.txt"
}

# Main execution
main() {
    print_status "Starting dependency installation process..."
    check_flutter
    clean_build
    get_flutter_deps
    install_ios_deps
    install_android_deps
    generate_native_files
    verify_dependencies
    print_success "All dependencies installed successfully! 🚀"
    print_status "Run 'flutter run' to start the application"
}

# Run main function
main "$@"