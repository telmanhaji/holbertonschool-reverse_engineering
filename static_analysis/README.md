# Static Analysis in Reverse Engineering

> *"You cannot defend what you do not understand. Static analysis is the art of understanding a program without ever running it—and that changes everything."*

---

## 📌 Introduction

Every piece of malware, compiled exploit, or suspicious binary encountered during a security investigation is fundamentally just a structured sequence of bytes. **Static Analysis** is the discipline of inspecting an executable's file structure, embedded strings, control flow, and assembly code to extract meaning and intent before a single instruction executes on CPU hardware.

Unlike dynamic analysis—which monitors behavior at runtime—static analysis allows security analysts to dissect programs safely inside an isolated environment without risking system compromise. This repository demonstrates core reverse engineering techniques used to inspect compiled executables, optimize computationally heavy decryption algorithms, unravel obfuscated algorithms, and reconstruct raw assembly routines into high-level logic.

---

## 🎯 Why It Matters

Static analysis is an essential foundational discipline across three critical cybersecurity domains:

* **Malware Analysis:** Inspecting dangerous or destructive binaries safely without launching executable code in live networks.
* **Security Auditing & Vulnerability Research:** Identifying memory safety bugs, buffer overflows, and hardcoded secrets when original source code is missing or proprietary.
* **Capture The Flag (CTF) & Threat Hunting:** Locating hidden flags, secret keys, and payload delivery routines by dissecting compiler artifacts and binary structures.

---

## 🧠 Learning Objectives

Upon completing this project, the following static analysis concepts, low-level mechanics, and reverse engineering tools are mastered:

* **Static vs. Dynamic Analysis:** Understanding the trade-offs, safety guarantees, and visibility provided by offline binary examination.
* **Disassembly vs. Decompilation:** Translating raw machine code into assembly language (x86/x64) and lifting assembly instructions into high-level pseudocode (C-like representations).
* **Executable File Formats:** Differentiating headers, section layouts, and loader behaviors across **ELF** (Linux), **PE** (Windows), and **Mach-O** (macOS).
* **Control Flow Graphs (CFGs):** Mapping basic blocks, conditional branches (`jmp`, `je`, `jne`), and loop structures to visualize execution flow.
* **Cross-Referencing (Xrefs):** Tracking how functions, string literals, and global variables interact across a compiled binary.
* **Algorithm De-obfuscation & Optimization:** Identifying performance bottlenecks (e.g., converting naive modular operations into fast exponentiation) and reversing non-linear mathematical transformations.

---

## 🛠️ Tooling & Environmental Setup

All tasks in this repository are executed entirely in a local, isolated laboratory environment on **Kali Linux**.

| Tool Category | Permitted Tools & Utilities |
| --- | --- |
| **GUI Disassemblers & Decompilers** | Ghidra, IDA Pro, Binary Ninja, Cutter |
| **Command-Line Frameworks** | Radare2, `objdump`, `gdb` (GNU Debugger) |
| **String & Asset Extraction** | `strings`, `binwalk`, Hex Editors |
| **Environment Constraints** | 100% Offline execution; no third-party online parsers |

---

## 📂 Repository Layout

```
holbertonschool-reverse_engineering/
└── static_analysis/
    ├── 0-flag.txt
    ├── 1-flag.txt
    ├── 2-flag.txt
    ├── 3-flag.txt
    └── 4-flag.txt

```

---

## ⚡ Technical Tasks & Implementation Details

### Task 0: Extracting and Analyzing Strings

* **Mechanics:** The initial stage of static triage involves extracting human-readable text embedded within executable data sections (`.rodata`, `.data`). Embedded strings often reveal internal function names, file paths, API endpoints, or hardcoded secrets.
* **Execution & Analysis Walkthrough:**
1. Extract printable ASCII/Unicode character sequences from `target-binary`:
```bash
strings -a -t x target-binary > extracted_strings.txt

```


2. Perform cross-analysis using Radare2 to locate cross-references to key strings:
```bash
r2 -A target-binary
[0x00401000]> iz
[0x00401000]> axt @ str.flag_location

```


3. Locate the embedded verification string or key artifact and save the retrieved token into `0-flag.txt`.


* **Deliverable:** `static_analysis/0-flag.txt`

---

### Task 1: Static Analysis of a Security-Critical C Program

* **Mechanics:** Going beyond static string extraction requires decompiling the binary's functions to inspect memory allocations, input sanitization routines, and potential vulnerability patterns (e.g., hardcoded credentials or buffer overflow risks).
* **Execution & Analysis Walkthrough:**
1. Load `target-binary` into Ghidra or IDA Pro and analyze the main execution routine (`main` or `entry`).
2. Analyze internal functions for memory management or validation flaws.
3. Trace variables from input buffers to conditional branches to uncover hidden code paths leading to flag output.
4. Record the resulting flag in `1-flag.txt`.


* **Deliverable:** `static_analysis/1-flag.txt`

---

### Task 2: Optimizing a Decryption Algorithm

* **Mechanics:** Reverse engineering computationally intensive decryption routines often uncovers naive mathematical implementations. A common bottleneck involves high-power modular arithmetic executed linearly ($O(N)$), which can be optimized using fast exponentiation algorithms like **Exponentiation by Squaring** ($O(\log N)$).
* **Mathematical Concept:**
Given a modular exponentiation routine computing $C = M^e \pmod{n}$, replace linear loop multiplication with binary bit-shift modular exponentiation:

$$\text{Power}(base, exp, mod) = \begin{cases} 1 & \text{if } exp = 0 \\ \left(\text{Power}(base, \frac{exp}{2}, mod)\right)^2 \pmod{mod} & \text{if } exp \text{ is even} \\ (base \cdot \text{Power}(base, exp - 1, mod)) \pmod{mod} & \text{if } exp \text{ is odd} \end{cases}$$


* **Execution & Analysis Walkthrough:**
1. Decompile the encryption/decryption routine using Ghidra or Binary Ninja.
2. Extract the static parameters (keys, moduli, encrypted array buffers).
3. Re-implement the algorithm in an optimized local script to compute the solution efficiently without timed execution constraints.
4. Output the decrypted plaintext message to `2-flag.txt`.


* **Deliverable:** `static_analysis/2-flag.txt`

---

### Task 3: Reverse Engineering an Obfuscated Flag

* **Mechanics:** Obfuscated binaries often obscure flag validation using non-reversible mathematical transformations (e.g., modular multiplication, bit-mixing, or hash collisions). Because non-linear transformations create hash-like collisions, specialized constraint solver scripts or local brute-force strategies must be used within constrained search spaces.
* **Flag Format Requirements:** `Holberton{XXXXX?}`
* `XXXXX`: Lowercase letters (`a-z`) or underscores (`_`).
* `?`: Final symbol character.
* *Special Constraint:* Mathematical obfuscation causes collisions at odd string indices.


* **Execution & Analysis Walkthrough:**
1. Decompile the validation loop in Radare2 / Ghidra:
```cmd
pdf @ sym.verify_flag

```


2. Extract the mathematical transformation matrix and target collision values.
3. Construct a localized script in Python to evaluate valid candidate character combinations matching the `Holberton{XXXXX?}` format mask.
4. Validate the resulting string against the local binary to ensure successful execution.


* **Deliverable:** `static_analysis/3-flag.txt`

---

### Task 4: Understanding Raw Assembly Code

* **Mechanics:** In low-level security research, decompilers may fail or produce misleading abstractions. Disassembling raw x86/x64 assembly instructions directly allows exact reconstruction of registers (`rax`, `rbx`, `rsp`), stack frame structures, and control flow logic.
* **Execution & Analysis Walkthrough:**
1. Disassemble the binary or raw code snippet using `objdump` or `gdb`:
```bash
objdump -d -M intel target-binary

```


2. Map out function prologue/epilogue steps, stack frame offsets (`rbp - 0x10`), and arithmetic operations (`xor`, `rol`, `ror`, `lea`).
3. Reconstruct the low-level instructions into equivalent high-level pseudocode logic.
4. Determine the correct output based on the input processing routine and write the result to `4-flag.txt`.


* **Deliverable:** `static_analysis/4-flag.txt`

---

## 🔬 Reverse Engineering Workflow Reference

```
 ┌─────────────────────────────────────────────────────────┐
 │                   Target Binary Triage                  │
 └────────────────────────────┬────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────┐
│ 1. Surface Analysis (FileType, Headers, Hashes, Strings) │
└────────────────────────────┬────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────┐
│ 2. Binary Disassembly & Control Flow Graph Reconstruction│
└────────────────────────────┬────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────┐
│ 3. Decompilation & Cross-Reference Mapping (Xrefs)       │
└────────────────────────────┬────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────┐
│ 4. Algorithmic Reconstruction, De-obfuscation & Solving  │
└──────────────────────────────────────────────────────────┘

```

---

## 🛡️ Defensive Hardening Matrix

> [!IMPORTANT]
> ### 1. Code Obfuscation & Symbol Stripping
> 
> 
> Strip internal symbol tables (`strip --strip-all binary`) during production builds to remove function identifiers, variable names, and debug metadata that aid static analysis.
> ### 2. Compiler Protections
> 
> 
> Compile binary releases with hardening flags to increase analysis complexity and prevent exploitation:
> * **Stack Canaries:** `-fstack-protector-all`
> * **Position Independent Executable (PIE):** `-fPIE -pie`
> * **Read-Only Relocations (RELRO):** `-Wl,-z,relro,-z,now`
> 
> 
> ### 3. Anti-Analysis Techniques
> 
> 
> Implement integrity checks, anti-debugging calls (`ptrace`), and binary packing cautiously to hinder automated static decompilation by unauthorized parties.

---

## ⚠️ Disclaimer

> [!WARNING]
> This repository is developed exclusively for educational purposes, security research, and authorized reverse engineering CTF challenges. Reverse engineering proprietary binaries without explicit authorization may violate end-user license agreements (EULAs) or local regulations.
