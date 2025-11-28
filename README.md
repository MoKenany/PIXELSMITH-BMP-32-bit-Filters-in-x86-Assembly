# PIXELSMITH — BMP 32-bit Filters in x86 Assembly

PIXELSMITH is a university project developed for the 8086 Assembly course.  
The system demonstrates low-level image processing by applying real pixel-based filters on BMP images using pure x86 assembly and DOS interrupts.

This project focuses on understanding how bitmap data is stored, accessed, and manipulated at the byte level, while maintaining performance and correctness even for large images.

---

## 🧩 **Project Idea**

PIXELSMITH is a lightweight image-processing tool that applies multiple filters to BMP images.  
All pixel operations are written manually in assembly — no external libraries, no high-level logic.

The project contains two main parts:

- The **core assembly code**, inside the `code/` folder  
- A complete **test suite**, inside the `tests/` folder (local samples + full Drive collection)

---

## 📂 **Project Structure**

```
Project/
│
├── code/
│   ├── MAIN.asm          → Main program (menu, I/O, progress, control flow)
│   ├── MACROS.inc        → DOS interrupt macros + helper routines
│   ├── F_PROCS.asm       → Filter procedures (Invert, LightGrey, Grey, Binary)
│   ├── PIXELMESS.asm     → Single-file optimized build (merged version)
│   └── README.md         → Documentation for the code folder
│
└── tests/
    ├── real_world_tests/ → Real photos for practical demonstrations
    ├── technical_tests/  → Synthetic tests for accuracy & edge cases
    └── README.md         → Explanation of available test sets & Drive link
```

---

## ⚙️ **Requirements**

To build or run PIXELSMITH you need:

- **DOSBox** (or any DOS environment)  
- **TASM / MASM** assembler  
- A compatible BMP input file:  
  - **4-bit indexed BMP** (for Invert filter)  
  - **32-bit BGRA BMP** (for LightGrey, Grey, Binary)

---

## 🖇 **Main Files Explained**

### **MAIN.asm**
Entry point of the program.  
Handles:

- User menu  
- Opening / closing files  
- Progress tracking (`blockCounter`)  
- Block-by-block reading  
- Calling filter procedures  
- Writing processed output  

---

### **MACROS.inc**
Contains reusable macros:

- DOS interrupt wrappers  
- Read/write helpers  
- Printing utilities  

Keeps the main code clean and consistent.

---

### **F_PROCS.asm**
Contains the full filter logic:

- **Invert Colors** (4-bit palette BMP)  
- **Light Grayscale** (experimental light-tone effect)  
- **Full Grayscale** (accurate BGRA grayscale)  
- **Binary Filter** (threshold 90)

Each filter processes pixels directly from the buffer and preserves alpha where needed.

---

### **PIXELMESS.asm**
A fully combined, single-block version of the entire program.  
Useful for:

- Reviewing the full system in one place  
- Optimization and debugging  
- Cleaner distribution build  

---

## 🎨 **Filters Included**

### **1) Invert Filter (4-bit Indexed BMP)**
Inverts palette colors and pixel indices for palette-based BMP files.  
Useful for testing indexed-color logic.

---

### **2) Light Grayscale Filter (non-standard / experimental)**
This filter was created unintentionally during development.  
It does **not** follow a correct grayscale formula — it simply **adds a small constant to RGB**, producing a washed-out, softer “light gray” effect.

Although not mathematically accurate, it creates a pleasant light-tone result, so it was kept as an optional stylistic filter.

---

### **3) Full Grayscale Filter (32-bit BGRA)**
Accurate grayscale conversion for 32-bit images:

```
Gray = (R + G + B) / 3
```

The **alpha channel is preserved**.

---

### **4) Binary Filter (Threshold = 90)**
Converts grayscale pixels into pure black or white:

```
if gray >= 90 → white
else → black
```

Ideal for high-contrast and edge-style output.

---

## ▶️ **How to Run**

1. Place your input BMP as **input.bmp** in the program folder.  
2. Assemble using TASM or MASM:  
   ```
   tasm MAIN.asm
   tlink MAIN.obj
   ```  
3. Run inside DOSBox.  
4. Choose a filter from the menu.  
5. Output will be saved as:

- `inverted.bmp`  
- `light_grey.bmp`  
- `grey.bmp`  
- `binary.bmp`

---

## 🧪 **Test Cases**

All organized inside the **tests/** folder:

- **technical_tests** → synthetic stress & accuracy tests  
- **real_world_tests** → natural images to show practical results  

The complete extended test set is available on Google Drive:  
>  [**Click & Enjoy**](<https://drive.google.com/drive/folders/1xYavLYvdm19kWrZTY5ErW0FESos9d4B4?usp=sharing>)

---

## 🎥 **Demo Video**


███████████████████████████████████████████

🎥 PIXELSMITH — Project Demo Video

▶ Watch on YouTube: 
> [**Enjoy Your Time**](<https://drive.google.com/drive/folders/13DWAfBIs6K1EmSU8URb-y2Svm7b-qB8R?usp=sharing>)

███████████████████████████████████████████
```
```
---

## ⭐ **Project Features**

- Pure x86 assembly (no high-level code)  
- Four fully implemented filters  
- Manual pixel-level processing  
- Support for **32-bit BGRA** and **4-bit indexed BMP**  
- **Progress tracking** during filter application  
- **Large 63 KB buffered I/O** for fast processing  
- BMP **header passthrough**  
- Block-based processing for large images  
- Optimized single-file build (**PIXELMESS.asm**)  
- Clean modular design (procedures + macros)  
- Comprehensive test suite (synthetic + real-world)

---

## 🙌 **Credits**

Developed by **Mohamed Al-Sayed Ali Mohamed**  
Course: **Assembly(8086) Programming**  


---
