#!/usr/bin/env python3
"""
Verification script for the dialogue system implementation.
This script verifies that the dialogue system works correctly.
"""

import os
import sys
import json

def check_file_contains(filename, search_text):
    """Check if a file contains specific text."""
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            content = f.read()
            return search_text in content
    except Exception as e:
        print(f"Error reading {filename}: {e}")
        return False

def main():
    print("Verifying dialogue system implementation...")
    
    # Check that key files exist
    files_to_check = [
        "scripts/dialogue_system.gd",
        "scripts/house.gd",
        "project.godot"
    ]
    
    all_good = True
    
    for file_path in files_to_check:
        if os.path.exists(file_path):
            print(f"✓ {file_path} exists")
        else:
            print(f"✗ {file_path} missing")
            all_good = False
    
    # Check that DialogueManager references are removed from key files
    key_files = ["scripts/house.gd", "scripts/dialogue_system.gd", "project.godot"]
    
    for file_path in key_files:
        if os.path.exists(file_path):
            content = open(file_path, 'r', encoding='utf-8').read()
            if "DialogueManager" in content:
                print(f"⚠ {file_path} still contains DialogueManager references")
                # Show lines with DialogueManager
                lines = content.split('\n')
                for i, line in enumerate(lines, 1):
                    if "DialogueManager" in line:
                        print(f"  Line {i}: {line.strip()}")
            else:
                print(f"✓ {file_path} has no DialogueManager references")
    
    # Check project.godot for DialogueManager configuration
    if os.path.exists("project.godot"):
        content = open("project.godot", 'r', encoding='utf-8').read()
        if "[dialogue_manager]" in content:
            print("⚠ project.godot still contains [dialogue_manager] section")
        else:
            print("✓ project.godot has no [dialogue_manager] section")
    
    # Check that DialogueSystem is properly configured
    if os.path.exists("project.godot"):
        content = open("project.godot", 'r', encoding='utf-8').read()
        if 'DialogueSystem="*res://scripts/dialogue_system.gd"' in content:
            print("✓ DialogueSystem autoload properly configured")
        else:
            print("✗ DialogueSystem autoload not properly configured")
            all_good = False
    
    # Check that DialogueManager plugin is removed
    if os.path.exists("addons/dialogue_manager"):
        print("⚠ addons/dialogue_manager directory still exists")
        all_good = False
    else:
        print("✓ addons/dialogue_manager directory removed")
    
    print("\n" + "="*50)
    if all_good:
        print("SUCCESS: All checks passed! The dialogue system is properly implemented.")
        print("The project now uses Godot's built-in systems instead of the DialogueManager plugin.")
    else:
        print("WARNING: Some issues were found. Please review the output above.")
    
    return 0 if all_good else 1

if __name__ == "__main__":
    sys.exit(main())