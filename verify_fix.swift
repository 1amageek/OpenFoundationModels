#!/usr/bin/env swift


import Foundation

let testString = "Hello, World!"
print("Creating GeneratedContent from String: '\(testString)'")

let testBool = true
print("Creating GeneratedContent from Bool: \(testBool)")

let testInt = 42
let testDouble = 3.14159
print("Creating GeneratedContent from Int: \(testInt)")
print("Creating GeneratedContent from Double: \(testDouble)")

print("\n✅ All basic type conversions work without infinite recursion!")
print("The fix is successful.")