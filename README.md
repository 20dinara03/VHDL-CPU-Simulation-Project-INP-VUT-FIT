# CPU Simulation Project (INC)

## Overview

This project is a simulation of a simple CPU, implemented in VHDL, and tested using GHDL and Cocotb. The simulation runs various test cases to validate the behavior of the CPU, including arithmetic operations, memory manipulations, and loops.

## Author

- **Dinara Garipova (xgarip00)**

## Prerequisites

Before running the project, make sure you have the following installed:

- **GHDL** (for VHDL compilation and simulation)
- **Cocotb** (Python-based verification framework)
- **Python 3.8+** (for running tests with Cocotb)
- **Make** (optional, for automated build process)

## How to Run

### 1. Compile the VHDL Code

```bash
ghdl -i --ieee=synopsys -fexplicit --workdir=build --work=work src/cpu.vhd
ghdl -m --ieee=synopsys -fexplicit --workdir=build -Pbuild --work=work cpu
```

### 2. Run the Simulation
```bash
ghdl -r --ieee=synopsys -fexplicit --workdir=build -Pbuild --work=work cpu
```
Or, if using Cocotb:
```bash
pytest
```
