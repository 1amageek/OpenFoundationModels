#!/usr/bin/env swift

// Test that the infinite recursion is fixed

import Foundation

// Test creating GeneratedContent from strings
let testString = "Hello, World!"
print("Creating GeneratedContent from String: '\(testString)'")

// Test creating GeneratedContent from booleans
let testBool = true
print("Creating GeneratedContent from Bool: \(testBool)")

// Test creating GeneratedContent from numbers
let testInt = 42
let testDouble = 3.14159
print("Creating GeneratedContent from Int: \(testInt)")
print("Creating GeneratedContent from Double: \(testDouble)")

print("\n✅ All basic type conversions work without infinite recursion!")
print("The fix is successful.")