# Reverse Engineering Fundamentals

> *"Every program tells a story. Reverse engineering is how you learn to read it."*

---

## 📌 Introduction

Modern software runs everywhere—across servers, endpoints, mobile devices, and embedded systems. In many security investigations, source code is unavailable, yet understanding program behavior is critical.

Reverse Engineering (RE) is the art and science of analyzing compiled binaries to understand their internal mechanics, execution logic, and data structures without access to original source files. This project introduces core static analysis techniques, focusing on binary structure parsing, ELF header extraction, non-standard section identification, and dynamic library dependency resolution.

---

## 🎯 Why It Matters

In real-world incident response and malware analysis, security teams routinely encounter undocumented or suspicious executables running inside enterprise networks.

Being able to inspect compiled code directly allows security professionals to:

* **Uncover Hidden Functionality:** Detect stealthy data exfiltration routines or hidden backdoors.
* **Audit Software Integrity:** Verify that third-party binaries have not been tampered with or infected.
* **Support Vulnerability Research:** Analyze software behavior to discover zero-day flaws and patch security vulnerabilities before exploitation.
* **Reverse Malware Logic:** Deconstruct malicious payloads, understand command-and-control (C2) mechanisms, and generate threat intelligence signatures.

---

## 🧠 Learning Objectives

By completing this module, the following binary analysis concepts and system-level mechanisms are mastered:

* **Disassembly vs. Decompilation:** Understanding how machine code translates into assembly language instructions versus higher-level C-like pseudocode.
* **ELF File Architecture:** Deconstructing the Executable and Linkable Format (ELF), including file headers, program headers, and section headers.
* **Static Binary Inspection:** Extracting critical binary metadata using standard utility binaries (`readelf`, `objdump`, `ldd`).
* **Section Analysis:** Identifying standard executable sections (`.text`, `.data`, `.rodata`, `.bss`) and detecting unusual or non-standard custom sections indicative of packing or obfuscation.
* **Dynamic Linking & Shared Libraries:** Tracking external symbol references and shared object dependencies (`.so` files) linked at runtime.
* **Control Flow Visualization:** Understanding Control Flow Graphs (CFGs), basic blocks, and conditional branching logic.
* **Anti-Analysis Techniques:** Recognizing common anti-reverse engineering mechanisms such as code obfuscation, executable packing, and anti-debugging checks.

---

## 🛠️ Environmental & Analytical Constraints

All static analysis and script development operations conform strictly to the following parameters:

* **Execution Operating System:** Kali Linux (isolated local laboratory VM / sandbox).
* **Allowed Core Toolset:** `readelf`, `objdump`, `ldd`, `bash`, `vi`/`vim`/`emacs`.
* **Offline Requirement:** 100% local execution—no online disassembly services or cloud parsers.
* **Pathing Rules:** All scripts utilize relative file paths and clean environmental bindings.
* **Stream Integrity:** All deliverables end with a POSIX-compliant trailing newline character (`\n`).

---

## 📂 Repository Layout

```
holbertonschool-reverse_engineering/
└── re_fundamentals/
    ├── get_entry_point.sh
    ├── size.txt
    ├── command.txt
    └── external_library.txt

```

---

## ⚡ Technical Tasks & Implementation Details

### Task 0: ELF Header Extractor (`get_entry_point.sh`)

#### Objective & Mechanics

Write an automated Bash script that inspects a target ELF binary (`target_binary`) and extracts four critical low-level header attributes:

1. **Magic Number:** Identifies the file type (`7f 45 4c 46`).
2. **Class:** Architecture width (32-bit vs. 64-bit).
3. **Byte Order:** System endianness (Little Endian vs. Big Endian).
4. **Entry Point Address:** Memory execution starting address assigned to the executable.

The script integrates with `messages.sh` to centralize output formatting.

#### Script Execution Logic (`get_entry_point.sh`)

```bash
#!/bin/bash
# Validate command-line input and file existence
if [ $# -ne 1 ] || [ ! -f "$1" ]; then
    echo "Error: File does not exist or invalid argument."
    exit 1
fi

file_name="$1"

# Verify target file is a valid ELF executable
if ! readelf -h "$file_name" > /dev/null 2>&1; then
    echo "Error: '$file_name' is not a valid ELF file."
    exit 1
fi

# Extract ELF header properties using readelf
magic_number=$(readelf -h "$file_name" | grep "Magic:" | sed 's/^[ \t]*Magic:[ \t]*//')
class=$(readelf -h "$file_name" | grep "Class:" | awk -F: '{print $2}' | xargs)
byte_order=$(readelf -h "$file_name" | grep "Data:" | awk -F: '{print $2}' | xargs)
entry_point_address=$(readelf -h "$file_name" | grep "Entry point address:" | awk -F: '{print $2}' | xargs)

# Source messages.sh if available, or call display routine natively
if [ -f "./messages.sh" ]; then
    source ./messages.sh
    display_elf_header_info
else
    echo "Header Information for '$file_name':"
    echo "--------------------------------"
    echo "Magic Number: $magic_number"
    echo "Class: $class"
    echo "Byte Order: $byte_order"
    echo "Entry Point Address: $entry_point_address"
fi

```

#### Deliverable Mapping

* **File Path:** `re_fundamentals/get_entry_point.sh`

---

### Task 1: Binary Section Enumeration (`size.txt`, `command.txt`)

#### Objective & Mechanics

Compilers organize binary assets into distinct sections. Malware authors or obfuscators often insert non-standard sections (e.g., custom payload containers or packed code blocks).

This task involves enumerating all sections of `target_binary`, identifying a non-standard section, and recording its exact size.

#### CLI Command Execution

```bash
# List all section headers using readelf
readelf -S target_binary

# Alternative enumeration using objdump
objdump -h target_binary

```

#### Output Deliverables

* **`command.txt`:** Contains the precise command used to isolate and output the details of the unusual section:
```bash
readelf -S target_binary | grep -E "unusual_section_name"

```


* **`size.txt`:** Stores only the hexadecimal or decimal size value of the identified section.
* **Deliverable Paths:** `re_fundamentals/size.txt`, `re_fundamentals/command.txt`

---

### Task 2: External Library Dependency Analysis (`external_library.txt`)

#### Objective & Mechanics

When binaries depend on shared system libraries (like `libc.so.6`, `libssl.so`, or custom dynamic modules), those dependencies are listed within the binary's dynamic section header under the `NEEDED` tag.

This task identifies the specific external shared library required by `target_binary`.

#### Inspection Commands

```bash
# Inspect dynamic library dependencies using ldd
ldd target_binary

# Alternatively, extract NEEDED tags via readelf
readelf -d target_binary | grep NEEDED

```

#### Output Deliverable

* **`external_library.txt`:** Contains the name of the external shared library file identified during dynamic analysis.
* **Deliverable Path:** `re_fundamentals/external_library.txt`

---

## 🔬 Command Quick Reference Cheat Sheet

| Tool | Common Flag | Purpose |
| --- | --- | --- |
| `readelf` | `-h` | Display the main ELF file header. |
| `readelf` | `-S` | List all section headers and sizes. |
| `readelf` | `-d` | Display dynamic section entries (dependencies, RPATH). |
| `objdump` | `-h` | Display section header summary. |
| `objdump` | `-d` | Disassemble executable sections (`.text`). |
| `ldd` | *(none)* | Print shared library dependencies required by binary. |

---

## 🛡️ Defensive Perspective & Remediation

> [!IMPORTANT]
> ### 1. Implement Integrity Monitoring
> 
> 
> Deploy File Integrity Monitoring (FIM) solutions like `AIDE` or `Tripwire` to detect unauthorized modifications to system binaries or unexpected section changes.
> ### 2. Binary Hardening Features
> 
> 
> Build production binaries using modern defensive compilation flags:
> * **PIE (Position Independent Executable):** Randomizes binary loading base addresses via ASLR.
> * **NX (No-Execute / DEP):** Prevents stack and heap execution.
> * **RPATH Audit:** Restrict hardcoded shared library search paths to prevent DLL/shared object hijacking.
> 
> 

---

## ⚠️ Disclaimer

> [!WARNING]
> This repository is maintained strictly for educational security research, academic compliance, and authorized static binary analysis. Inspecting or reverse engineering proprietary software without explicit permission may violate software license agreements or regional legal frameworks.
