# http://iverilog.icarus.com/
CC=iverilog 
FLAGS=-Wall -g2012
# http://gtkwave.sourceforge.net/
VIEWER=code
# http://gtkwave.sourceforge.net/
# VIEWER=gtkwave
# https://github.com/yne/vcd
# VIEWER=../../../vcd/vcd < 
# https://drom.io/vcd/?github=menotti/up1/master/processor/dump.vcd

# Toolchain RISC-V
CROSS = riscv64-unknown-elf
AS    = $(CROSS)-as
LD    = $(CROSS)-ld
OBJDUMP = $(CROSS)-objdump

all: asm simul

asm: *.asm
	$(AS) -o riscv.o *.asm
	$(LD) -o riscv.elf riscv.o
	$(OBJDUMP) -d riscv.elf > riscv.dump


simul: *.sv
	$(CC) $(FLAGS) *.sv 
	vvp a.out
	$(VIEWER) dump.vcd
# 	$(VIEWER) dump.vcd config.gtkw

clean:
	rm -f *.o *.elf a.out dump.vcd
