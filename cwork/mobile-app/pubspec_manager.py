#!/usr/bin/env python3
"""
pubspec_manager.py
Advanced dependency management and validation for Flutter projects
"""

import yaml
import subprocess
import json
import requests
from pathlib import Path
from typing import Dict, List, Any

class PubspecManager:
    def __init__(self, pubspec_path: str = 'pubspec.yaml'):
        self.pubspec_path = Path(pubspec_path)
        self.data = self._load_pubspec()
    
    def _load_pubspec(self) -> Dict:
        """Load pubspec.yaml file"""
        if not self.pubspec_path.exists():
            raise FileNotFoundError(f"pubspec.yaml not found at {self.pubspec_path}")
        
        with open(self.pubspec_path, 'r') as file:
            return yaml.safe_load(file)
    
    def get_dependencies(self) -> Dict:
        """Get all dependencies with versions"""
        deps = {}
        deps.update(self.data.get('dependencies', {}))
        deps.update(self.data.get('dev_dependencies', {}))
        deps.update(self.data.get('dependency_overrides', {}))
        return deps
    
    def check_outdated(self) -> List[Dict]:
        """Check for outdated packages"""
        try:
            result = subprocess.run(['flutter', 'pub', 'outdated', '--json'], 
                                  capture_output=True, text=True, check=True)
            outdated_data = json.loads(result.stdout)
            return outdated_data.get('outdated', {}).get('direct', [])
        except (subprocess.CalledProcessError, json.JSONDecodeError):
            return []
    
    def get_latest_version(self, package_name: str) -> str:
        """Get latest version of a package from pub.dev"""
        try:
            url = f"https://pub.dev/api/packages/{package_name}"
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                data = response.json()
                return data['latest']['version']
        except requests.RequestException:
            pass
        return "Unknown"
    
    def generate_dependency_report(self) -> str:
        """Generate comprehensive dependency report"""
        report = ["# Flutter Dependency Report\n"]
        deps = self.get_dependencies()
        
        report.append("## Current Dependencies\n")
        for package, version in deps.items():
            latest = self.get_latest_version(package)
            status = "✅ Up to date" if str(version) == latest else f"⚠️ Update available: {latest}"
            report.append(f"- **{package}**: {version} ({status})")
        
        report.append("\n## Outdated Packages (flutter pub outdated)\n")
        outdated = self.check_outdated()
        for package in outdated:
            report.append(f"- {package['name']}: {package['current']} → {package['latest']}")
        
        return "\n".join(report)
    
    def save_report(self, filename: str = "DEPENDENCY_REPORT.md"):
        """Save dependency report to file"""
        report = self.generate_dependency_report()
        with open(filename, 'w') as f:
            f.write(report)
        print(f"Report saved to {filename}")

def main():
    """Main function"""
    try:
        manager = PubspecManager()
        manager.save_report()
        print("Dependency report generated successfully!")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()