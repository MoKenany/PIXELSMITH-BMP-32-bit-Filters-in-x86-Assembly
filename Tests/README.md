# Tests Overview

This folder contains two main categories of test images used to verify the behavior and reliability of the 32-bit BMP image processing project.

---

## 1) real_world_tests/
A small set of natural photos (objects, faces, scenes).  
These images help demonstrate how the filters behave on real-life content instead of synthetic patterns.

---

## 2) technical_tests/
A collection of controlled, synthetic test images designed to check the accuracy of grayscale and binary processing.

The technical tests currently included in this folder are:

### 1. RGBWB Color Palette
Simple red/green/blue/white/black color blocks used to confirm basic grayscale behavior.

### 2. Sharp Color Patterns
High-contrast color tiles useful for revealing channel-mixing issues and boundary mistakes.

### 3. Pure Spectrum
A horizontal RGB spectrum bar used to test smooth grayscale transitions across a wide color range.

---

## Additional Technical Tests (Available on Google Drive)
For space reasons, the rest of the technical test collection is stored on Google Drive.  
These tests include more advanced and larger examples:

### • Noise Images  
Random pixel images designed for stress testing and checking stability under heavy data.

### • Dark Images with Subtle Highlights  
Low-light scenes used to evaluate grayscale sensitivity and detail preservation.

### • High Contrast Complex Images  
Scenes with strong contrast, useful for testing filter behavior on challenging lighting conditions.

### • General Mixed Tests  
Combined patterns, gradients, and noise inside one image for a quick all-in-one check.

You can access the full extended test set here:  
👉  [**Click & Enjoy**](<https://drive.google.com/drive/folders/1xYavLYvdm19kWrZTY5ErW0FESos9d4B4?usp=sharing>)


---
