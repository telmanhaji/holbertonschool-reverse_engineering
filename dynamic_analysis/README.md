# Dynamic Analysis in Reverse Engineering

> *"Static analysis tells you what code says. Dynamic analysis tells you what code does."*

---

## 📌 Introduction

In modern reverse engineering, binaries are rarely straightforward. Malware authors, obfuscators, and software protection systems employ runtime unpacking, self-modifying instructions, non-linear mathematical constraints, and anti-debugging checks to evade static inspection. When source code is unavailable and decompilers produce unreadable pseudocode, watching the executable run inside an instrumented environment becomes essential.

**Dynamic Analysis** bridges the gap between static binaries and runtime behavior. By executing code under controlled conditions—using debuggers, symbolic execution engines, binary instrumentation frameworks, and system call monitors—analysts observe exact register state changes, inspect decrypted memory regions, bypass anti-analysis checks, and solve complex branch conditions automatically.

---

## 🎯 Why It Matters

Dynamic analysis provides definitive runtime visibility across multiple offensive and defensive domain applications:

* **Malware Analysis & Ransomware Triage:** Unpacking encrypted payloads directly from process memory (`RAM`), tracing command-and-control (`C2`) network traffic, and monitoring file system modifications.
* **Anti-Debugging & Evasion Bypass:** Identifying and neutralizing runtime anti-analysis checks (such as `ptrace` checks or timing side-channels) to keep debuggers attached.
* **Symbolic Execution & Constraint Solving:** Using SMT/SAT solvers (like Z3 and Angr) to evaluate complex mathematical guard conditions automatically, eliminating manual reverse-engineering of validation routines.
* **Batch Vulnerability Research & Scripting:** Automating input verification and execution tracing across hundreds of compiled binaries simultaneously using programmatic frameworks like `pwntools`.

---

## 🧠 Learning Objectives

Upon completing this project, the following dynamic analysis principles, debugging mechanics, and automation methodologies are mastered:

* **Static vs. Dynamic Analysis Trade-offs:** Knowing when static decompilation is insufficient and runtime tracing or memory inspection is required.
* **Debugger Instrumentation:** Setting conditional hardware/software breakpoints, stepping through disassembly (`si`, `ni`), inspecting stack frames, and dumping modified memory regions using GDB.
* **Anti-Debugging Neutralization:** Detecting and bypassing anti-debugging checks (e.g., Linux `ptrace(PTRACE_TRACEME)`, `/proc/self/status` inspections, and `SIGTRAP` signal handling).
* **SAT/SMT Constraint Solving:** Formulating extracted binary logic into Boolean satisfiability equations and solving them programmatically using **Z3 SMT Solver** and **Angr**.
* **Self-Modifying Code (SMC):** Tracing runtime decryption routines, identifying RWX memory permissions (`PROT_READ | PROT_WRITE | PROT_EXEC`), and dumping decrypted instructions post-execution.
* **Automated Binary Analysis:** Writing Python automation scripts using `pwntools` and subprocess pipelines to analyze and solve batch binary inputs systematically.

---

## 🛠️ Environmental & Tooling Framework

All analysis tasks are executed locally inside an isolated, non-networked Kali Linux virtual machine sandbox.

| Utility / Framework | Primary Purpose |
| --- | --- |
| **GDB (GNU Debugger)** | Interactive process debugging, register inspection, runtime memory patching. |
| **Z3 SMT Solver** | High-performance Boolean satisfiability constraint solving via Python bindings. |
| **Angr** | Multi-architecture symbolic execution engine for path exploration and constraint solving. |
| **Intel Pin / Valgrind** | Dynamic Binary Instrumentation (DBI) and runtime memory tracing. |
| **Pwntools** | Python CTF/Exploit development framework for automated I/O handling and process interaction. |
| **Wireshark & ProcMon** | Local network protocol auditing and system call monitoring. |

---

## 📂 Repository Layout

```
holbertonschool-reverse_engineering/
└── dynamic_analysis/
    ├── 0-flag.txt
    ├── 1-flag.txt
    ├── 2-flag.txt
    ├── 3-flag.txt
    └── 4-flag.txt

```

---

## ⚡ Technical Tasks & Implementation Details

### Task 0: SAT Solving in Reverse Engineering

* **Mechanics:** Obfuscated verification routines often use non-linear branch conditions that resist simple static reading. Instead of reversing the logic manually, symbolic constraints are extracted from the binary disassembly and modeled as a Boolean Satisfiability (SAT/SMT) problem.
* **Mathematical Constraint Formulation:**
A binary constraint system with $n$ variables is represented as a conjunction of logical constraints:

$$\Phi(x_1, x_2, \dots, x_n) = \bigwedge_{i=1}^{k} C_i(x_1, \dots, x_n) = 1$$



The Z3 solver searches for a satisfying assignment vector $X = (x_1, \dots, x_n)$ such that $\Phi(X) = \text{True}$.
* **Execution & Solver Strategy:**
1. Extract control flow guard conditions from the target binary using IDA Pro or Ghidra.
2. Map register operations and arithmetic bitwise operations into a Python Z3 solver script:
```python
from z3 import *

s = Solver()
vars = [BitVec(f'x_{i}', 8) for i in range(16)]

# Add extracted binary constraints
s.add(vars[0] ^ vars[1] == 0x42)
s.add(vars[2] + vars[3] * 3 == 0x1A)
# ... additional constraints added ...

if s.check() == sat:
    m = s.model()
    flag = "".join([chr(m[v].as_long()) for v in vars])
    print(f"Solved Flag: {flag}")

```


3. Execute the solver script locally (execution may take up to 35+ minutes depending on constraint complexity).


* **Deliverable Path:** `dynamic_analysis/0-flag.txt`

---

### Task 1: Exploring Anti-Debugging Techniques

* **Mechanics:** Binaries frequently implement anti-debugging checks to detect attached analysis tools and terminate execution or alter behavior.
* **Common Anti-Debugging Mechanisms:**
* **Linux `ptrace` Check:** Calling `ptrace(PTRACE_TRACEME, 0, 1, 0)` returns `-1` if a debugger (like GDB) is already attached.
* **Process Status Inspection:** Reading `/proc/self/status` and checking if `TracerPid` is non-zero.
* **Signal Handler Manipulation:** Intercepting `SIGTRAP` or `SIGSEGV` signals used internally by debuggers.


* **Bypass Execution Flow:**
1. Load the binary into GDB:
```bash
gdb ./target_binary

```


2. Set a breakpoint at the `ptrace` call or the conditional jump following the check:
```cmd
(gdb) catch syscall ptrace
(gdb) run

```


3. Patch register values or force jump execution past the security check:
```cmd
(gdb) set $rax = 0
(gdb) set $eflags |= 0x40
(gdb) continue

```


4. Continue execution, trace memory, and retrieve the hidden flag.


* **Deliverable Path:** `dynamic_analysis/1-flag.txt`

---

### Task 2: Advanced SAT Solving & Constraint Analysis

* **Mechanics:** Complex protections mix conditional branches with self-modifying code or heavy bit manipulation loops. In this task, static decompilation is paired with dynamic memory tracing to isolate the constraint validation logic and process it using SMT solvers.
* **Execution & Analysis Walkthrough:**
1. Trace runtime execution using Valgrind or Intel Pin to log instruction address paths and execution trace trees.
2. Extract bitwise transformations and arithmetic comparison vectors.
3. Load extracted constraints into a Z3 / Angr symbolic execution pipeline:
```python
import angr, claripy

proj = angr.Project('./target_binary', auto_load_libs=False)
flag_chars = [claripy.BVS(f'flag_{i}', 8) for i in range(32)]
flag = claripy.Concat(*flag_chars)

state = proj.factory.entry_state(stdin=flag)
simgr = proj.factory.simulation_manager(state)
simgr.explore(find=0x4011AA, avoid=0x4011C0)

if simgr.found:
    found_state = simgr.found[0]
    print("Flag:", found_state.solver.eval(flag, cast_to=bytes))

```


4. Save the evaluated flag string into `2-flag.txt`.


* **Deliverable Path:** `dynamic_analysis/2-flag.txt`

---

### Task 3: Self-Modifying Code (SMC)

* **Mechanics:** Self-Modifying Code alters its own instructions in memory during execution. The binary starts with encrypted or scrambled bytes in an executable memory page (`RWX`), decrypts the payload at runtime via a loop, executes the unencrypted code, and often re-encrypts it afterward to evade static signatures.
* **Analysis & Tracing Workflow:**
1. Disassemble the binary in Ghidra / GDB to locate the decryption routine loop (typically an `XOR` or substitution loop targeting local code addresses).
2. Set a software breakpoint immediately after the loop finishes executing (at the landing page address of the newly decrypted block):
```cmd
(gdb) break *0x00401150
(gdb) run

```


3. Once the breakpoint hits, dump the modified instructions from memory to analyze input validation logic:
```cmd
(gdb) x/30i $pc
(gdb) dump memory decrypted_code.bin 0x00401150 0x00401300

```


4. Reverse engineer the revealed input validation routine to obtain the correct passphrase.


* **Deliverable Path:** `dynamic_analysis/3-flag.txt`

---

### Task 4: Solve the 100 Binaries (Automated Dynamic Batch Solving)

* **Mechanics:** This challenge presents 100 distinct compiled binaries (`binary_0` through `binary_99`). Each binary processes a single input character, performs an arithmetic transformation (e.g., $C' = C \pm K$), compares it against a hardcoded internal byte, and exits silently without printing success messages.
* **Automation Workflow:**
Instead of manual reverse engineering, a Python script automates input testing and execution tracing across all 100 targets:

```python
import subprocess
import string

flag = ""
printable_chars = string.printable

for i in range(100):
    binary_path = f"./binaries/binary_{i}"
    found_char = False
    
    for char in printable_chars:
        # Pass candidate character to binary and check exit code
        proc = subprocess.Popen([binary_path], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = proc.communicate(input=char.encode())
        
        if proc.returncode == 0:
            flag += char
            found_char = True
            break
            
    if not found_char:
        flag += "?"

print(f"Reconstructed Flag: {flag}")
with open("4-flag.txt", "w") as f:
    f.write(flag + "\n")

```

* **Deliverable Path:** `dynamic_analysis/4-flag.txt`

---

## 🔬 Dynamic Analysis Cheat Sheet

```
                   +-----------------------------------+
                   |     Target Process Attachment     |
                   +-----------------+-----------------+
                                     |
                                     v
                   +-----------------------------------+
                   |   Detect Anti-Debugging Checks?   |
                   +--------+-----------------+--------+
                            |                 |
                   YES      v                 v     NO
        +-----------------------+   +-----------------------+
        | Patch ptrace/TracerPid|   | Set Hardware/Software |
        | or Bypass Signal Traps|   | Breakpoints (b / hbreak)|
        +-----------+-----------+   +-----------+-----------+
                    |                           |
                    +-------------+-------------+
                                  |
                                  v
                   +-----------------------------------+
                   | Memory Decryption / SMC Execution |
                   +-----------------+-----------------+
                                     |
                                     v
                   +-----------------------------------+
                   | Inspect Registers / Memory Dump   |
                   | or Run SMT Symbolic Exploration   |
                   +-----------------------------------+

```

---

## 🛡️ Defensive Hardening Matrix

> [!IMPORTANT]
> ### 1. Implement Integrity & Environment Checks
> 
> 
> Enterprise software and agent binaries can protect runtime state by detecting timing anomalies (`RDTSC` delta checks) or checking for active API hooks and debugger registers (`DR0`-`DR7`).
> ### 2. Code Signing & Memory Protections
> 
> 
> Prevent self-modifying code vulnerabilities by strictly enforcing **W^X (Write XOR Execute)** memory policies (`DEP` / `NX`). Memory pages must never be simultaneously writable and executable.
> ### 3. Obfuscation & Dynamic Integrity Seals
> 
> 
> Utilize dynamic runtime checksums to verify that binary code segments have not been patched with `NOP` instructions (`0x90`) or debugger software breakpoints (`0xCC / INT 3`).

---

## ⚠️ Disclaimer

> [!WARNING]
> This repository is maintained strictly for ethical cybersecurity education, defensive research, and authorized laboratory reverse engineering tasks. Executing dynamic analysis tools, symbolic solvers, or debugging scripts against unauthorized binaries or production systems without explicit written consent is strictly prohibited.
