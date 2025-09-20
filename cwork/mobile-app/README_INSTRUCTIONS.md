# Flutter Dependency Management Scripts

## Quick Start

1. **Make scripts executable:**
   ```bash
   chmod +x install_dependencies.sh setup_project.sh
   ```

2. **Run complete setup:**
   ```bash
   ./setup_project.sh
   ```

3. **Or run individually:**
   ```bash
   ./install_dependencies.sh
   python3 pubspec_manager.py
   ```

## Script Options

### install_dependencies.sh
- `--clean`: Clean build before installing
- `--force`: Force refresh of all dependencies
- `--ios`: Only install iOS dependencies
- `--android`: Only install Android dependencies

### Examples:
```bash
# Clean install everything
./install_dependencies.sh --clean

# Only iOS with force refresh
./install_dependencies.sh --ios --force

# Normal installation
./install_dependencies.sh
```

## Features

✅ Automatic Flutter pub get  
✅ iOS CocoaPods installation  
✅ Android Gradle dependency check  
✅ Build runner code generation  
✅ Flutter launcher icons generation  
✅ Dependency version checking  
✅ Outdated package detection  
✅ Comprehensive reporting  
✅ Cross-platform support  
✅ Error handling and validation

## Script Details

### install_dependencies.sh
Main installation script that handles:
- Flutter dependency management
- Platform-specific dependency installation (iOS/Android)
- Build cleaning and force refresh options
- Error handling and colored output

### pubspec_manager.py
Advanced dependency management tool that:
- Analyzes pubspec.yaml dependencies
- Checks for outdated packages via pub.dev API
- Generates comprehensive dependency reports
- Provides version comparison and update recommendations

### setup_project.sh
Complete project setup script that:
- Makes all scripts executable
- Runs full dependency installation
- Generates dependency report
- Provides completion status

## Usage Tips

- Run `./install_dependencies.sh --clean` when experiencing build issues
- Use `--force` flag to refresh all dependencies from remote sources
- Review `DEPENDENCY_REPORT.md` regularly to keep dependencies updated
- The scripts include proper error handling and will exit on critical failures

## File Outputs

- `dependency_tree.txt`: Detailed dependency tree from `flutter pub deps`
- `DEPENDENCY_REPORT.md`: Comprehensive report with version status and update recommendations

## Requirements

- Flutter SDK installed and in PATH
- Python 3.x for pubspec_manager.py
- CocoaPods (for iOS development)
- Android SDK (for Android development)

## Troubleshooting

If you encounter issues:
1. Ensure Flutter is properly installed: `flutter doctor`
2. Check Python is available: `python3 --version`
3. Verify CocoaPods installation: `pod --version`
4. Review error messages in the terminal output