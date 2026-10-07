# LightRISCV

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/menotti/lightriscv)

https://www.youtube.com/playlist?list=PLBZWofG0oRh8

Single & Multi-cycle implementation of a subset of RISC-V for educational purposes. 

The first version of this processor (multicycle) was adapted from the MIPS processor described in the Harris & Harris book[^1]. The single-cycle version was created from Bruno Levy's multicycle code[^2], with signal names changed to match those in the book.

## Instructions

`make` will simulate the single-cycle version. Be careful with data addresses, as the linker won't calculate them correctly. In the example below, `s0` is manually set to the address of variable `b` instead of using the pseudo instruction `la`.

```asm
_start:
	addi s0, zero, 0x4 # Harvard architecture (monocycle)
	#la s0, b # Von Neumann architecture (multicycle)
```

Uncomment the following line if you want to simulate the multicycle version. In this version, the addresses are calculated correctly by the linker. To simulate this version, use the command `make VERSION=MULTISTRUCT`.

The multicycle processor comes in two equivalent descriptions, chosen by the same `VERSION` variable. `MULTISTRUCT` compiles `riscvmulti-struct.sv`, the structural one, in which the controller, the datapath and each building block (register file, ALU, multiplexers and flip-flops) are separate modules wired together as in the book. To simulate the combinational one instead, use the command `make VERSION=MULTICOMBIN`: `riscvmulti-combin.sv` describes the same processor as a single module, where the state machine, the control signals and the datapath are written as continuous assignments and only the architectural registers are clocked.

Each simulation starts by printing the architecture it was compiled for, so you can check that the intended version was selected. An unrecognized `VERSION` falls back to the single-cycle version instead of failing.

## Implemented instructions
* add
* addi
* lw
* sw
* jal (incomplete)

## EDA Playground
* [You can try it online here!](https://www.edaplayground.com/x/cTAA)


## Further Reading 
* [Guia Prático RISC-V (pt-br)](http://riscvbook.com/portuguese/)
* [RISC-V Assembly Programming](https://riscv-programming.org/)
* [RARS: RISC-V Assembler and Runtime Simulator](https://github.com/TheThirdOne/rars)
* [Digital Design and Computer Architecture: RISC-V Edition](https://www.elsevier.com/books/digital-design-and-computer-architecture/harris/978-0-12-820064-3)
* [emulsiV: a visual simulator for a simple RISC-V processor](https://eseo-tech.github.io/emulsiV/)
* [DarkRISCV: Opensource RISC-V implemented from scratch in one night!](https://github.com/darklife/darkriscv)

## References

[^1]: [Digital Design and Computer Architecture](https://shop.elsevier.com/books/digital-design-and-computer-architecture/harris/978-0-12-394424-5)
[^2]: [From Blinker to RISC-V](https://github.com/BrunoLevy/learn-fpga/blob/master/FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV/)

[![YouTube Playlist with instructions (in portuguese)](https://img.youtube.com/vi/cuiVdmo3TxM/0.jpg)](https://www.youtube.com/playlist?list=PLBZWofG0oRh8)
