# 32-bit Multi-Cycle CPU in VHDL

A simple 32-bit accumulator-style CPU with two registers (A, B), carry/zero flags,
a 3-state control unit (fetch → decode → execute), on-chip data memory, and an
instruction memory (`system_memory`, Altera `altsyncram` initialised from
`system_memory.mif`). Targets the Cyclone IV E (EP4CE115F29C7, DE2-115) in Quartus.

## Files

| File | Description |
|------|-------------|
| `cpu_test_sim.vhd` | Top level: CPU + instruction memory |
| `cpu1.vhd` | CPU: datapath + control + reset circuit |
| `data_path.vhd` | Registers, muxes, ALU, PC, data memory |
| `Control_New.vhd` | Control unit FSM / instruction decoder |
| `alu.vhd` | AND, OR, ADD, SUB, shift left/right, pass-B |
| `adder32/16/4.vhd`, `fulladd.vhd` | Ripple-carry adder hierarchy |
| `pc.vhd`, `add.vhd`, `register32.vhd` | Program counter and registers |
| `LZE/UZE/RED.vhd` | Lower/upper zero-extend, address reduce |
| `mux2to1.vhd`, `mux4to1.vhd` | Multiplexers |
| `data_mem.vhd` | 256 × 32-bit data RAM |
| `reset_circuit.vhd` | Holds the PC clear for a few cycles after reset |
| `*.vwf` | Quartus waveform test vectors |

## Instruction set

| Opcode (IR[31:28] / IR[31:24]) | Instruction | Operation |
|---|---|---|
| `0000` | LDAI imm | A ← zext(imm16) |
| `0001` | LDBI imm | B ← zext(imm16) |
| `0010` | STA addr | M[addr] ← A |
| `0011` | STB addr | M[addr] ← B |
| `0100` | LUI imm | A ← imm16 << 16, B ← 0 |
| `0101` | JMP addr | PC ← addr |
| `0110` | BEQ addr | if A = B: PC ← addr |
| `1000` | BNE addr | if A ≠ B: PC ← addr |
| `1001` | LDA addr | A ← M[addr] |
| `1010` | LDB addr | B ← M[addr] |
| `01110000` | ADD | A ← A + B |
| `01110001` | ADDI imm | A ← A + imm |
| `01110010` | SUB | A ← A − B |
| `01110011` | INCA | A ← A + 1 |
| `01110100` | ROL | A ← A << 1 (C ← bit shifted out) |
| `01110101`–`01111000` | CLRA / CLRB / CLRC / CLRZ | clear register/flag |
| `01111001` | ANDI imm | A ← A and imm |
| `01111010` | TSTZ | skip next instruction if Z = 1 |
| `01111011` | AND | A ← A and B |
| `01111100` | TSTC | skip next instruction if C = 1 |
| `01111101` | ORI imm | A ← A or imm |
| `01111110` | DECA | A ← A − 1 |
| `01111111` | ROR | A ← A >> 1 (C ← bit shifted out) |

## Building

Open `cpu32.qpf` in Quartus Prime and compile. Top-level entity is `CPU_TEST_Sim`.

## Execution

Every instruction takes three cycles, as in the CPU specification:

- **T0** – `IR <= M[PC]`
- **T1** – `PC <= PC + 1`; pre-decode memory instructions (assert `en`/`wen` and muxes for
  LDA/LDB/STA/STB). BEQ/BNE also compute `A - B` here to load Z, and LUI clears B.
- **T2** – decode and execute.

The PC increments by 1 because each instruction memory word is 32 bits wide.
BEQ/BNE overwrite the Z flag with the result of the A/B comparison.

Clocks (from the CPU testing document): memory clock ≤ 20 MHz (50 ns period), CPU clock
at least 2× slower, with the memory clock's falling edge aligned to the CPU clock's rising edge.

## Testing

`test/all_instructions.mif` is a program that exercises every instruction (including taken and
not-taken branches and skips) and ends with `A = 0x600D`, `B = 0x2`. `test/tb_cpu.vhd` runs it
and reports the register state after each instruction. With Questa/ModelSim:

```
vlib work
cp test/all_instructions.mif system_memory.mif   # in the simulation directory
vcom -2008 fulladd.vhd adder4.vhd adder16.vhd adder32.vhd add.vhd mux2to1.vhd mux4to1.vhd      register32.vhd pc.vhd LZE.vhd UZE.vhd RED.vhd alu.vhd data_mem.vhd data_path.vhd      reset_circuit.vhd Control_New.vhd cpu1.vhd system_memory.vhd cpu_test_sim.vhd test/tb_cpu.vhd
vsim -c tb_cpu -do "run -all; quit -f"
```

Run it from a scratch directory so the project's own `system_memory.mif` isn't overwritten.
