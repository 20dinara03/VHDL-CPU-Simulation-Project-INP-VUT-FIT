# CPU Simulation Project (INP)

## 📌 Project Overview

This project is designed to test and validate a MIPS assembly implementation that encodes a login string using a specific encryption algorithm. The validation process ensures that the generated encrypted login string matches the expected output and adheres to given constraints.

## 🛠 Features

- **MIPS64 Assembly Login Validation**
- **Custom Login Encryption Algorithm**
- **Automated Testing via Python**
- **Execution in EduMIPS64 Emulator**
- **Strict Syntax and Formatting Checks**
- Java 8+ (required to run the EduMIPS64 simulator)
- EduMIPS64 1.2.10 (placed in the project directory)

## Author

- **Dinara Garipova (xgarip00)**

## Prerequisites

Before running the project, make sure you have the following installed:

- **GHDL** (for VHDL compilation and simulation)
- **Cocotb** (Python-based verification framework)
- **Python 3.8+** (for running tests with Cocotb)
- **Make** (optional, for automated build process)

## 🚀 Running the Test Suite
### 1. Ensure the required files are in place:
- edumips64-1.2.10.jar
- xgarip00.s (MIPS assembly source file)
### 2. Run the Python validation script:
```bash
python3 tests/test.py
```
Expected Output:
- The script will check for proper encryption and formatting.
- If successful, it prints:
```sql
ALL TESTS PASSED!!! YOU ARE AWESOME!!!
```
If errors are found, the script will indicate the specific failure.

## 📝 Testing Mechanism
- The test.py script runs the EduMIPS64 simulator on the MIPS source file.
- It performs multiple login encryption tests, validating:
  - Proper login string encoding
  - Correct memory allocation and formatting
  - No usage of illegal MIPS64 instructions
  - Null byte termination for login and cipher strings
-If all tests pass, the program confirms successful validation.

## 🔍 Debugging
If edumips64-1.2.10.jar is missing, the script will halt with:
```vbnet
ERROR!!! edumips64-1.2.10.jar not found
```
If the login format is incorrect:
```pgsql
ERROR!!! Login must start with 'x'
ERROR!!! Login should end with two digits
```
If illegal MIPS instructions are detected:
```sql
ERROR!!! You are using one of the restricted instructions: "BNEZ", "BEQZ", "HALT"...
```
If encryption output does not match the expected result:
```vbnet
ERROR!!! Cipher string is not correct
```
## 📜 License
This project is developed as part of an educational assignment and is meant for academic use only.
