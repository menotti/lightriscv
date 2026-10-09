# http://iverilog.icarus.com/
CC=/bin/iverilog 
VVP=/bin/vvp

FLAGS=-Wall -g2012

# http://gtkwave.sourceforge.net/
VIEWER=code
# http://gtkwave.sourceforge.net/
# VIEWER=gtkwave
# https://github.com/yne/vcd
# VIEWER=../../../vcd/vcd < 
# https://drom.io/vcd/?github=menotti/up1/master/processor/dump.vcd

# Toolchain
VERSION ?= SINGLE
STYLE ?= DATAFLOW

VALID_VERSIONS := SINGLE MULTI
VALID_STYLES := DATAFLOW STRUCT

ifneq ($(filter $(VERSION),$(VALID_VERSIONS)),$(VERSION))
$(error Invalid VERSION value '$(VERSION)'. Valid values: $(VALID_VERSIONS))
endif

ifneq ($(filter $(STYLE),$(VALID_STYLES)),$(STYLE))
$(error Invalid STYLE value '$(STYLE)'. Valid values: $(VALID_STYLES))
endif

CROSS   = riscv64-unknown-elf
AS      = $(CROSS)-as
LD      = $(CROSS)-ld
OBJCOPY = $(CROSS)-objcopy
OBJDUMP = $(CROSS)-objdump
ASFLAGS = -march=rv32i
ifeq ($(VERSION),MULTI)
ASFLAGS += -defsym MULTI=1
endif

# Arquivos
LDS    = riscv.ld
SRC    = fibo.asm
OBJ    = $(SRC:.asm=.o)
ELF    = fibo.elf
LST    = fibo.lst
HEX    	 = von_neumann.hex
HEX_TEXT = harvard_text.hex
HEX_DATA = harvard_data.hex

all: $(HEX) $(HEX_TEXT) $(HEX_DATA) $(LST) simul

# Monta o assembly (RV32)
$(OBJ): $(SRC)
	$(AS) $(ASFLAGS) -o $@ $<

# Linka em 32 bits usando o linker script
$(ELF): $(OBJ) $(LDS)
	$(LD) -m elf32lriscv -T $(LDS) -o $@ $<

# Gera HEX de instruções + dados (.text + .data + .bss) (memória von Neumann)
$(HEX): $(ELF)
	$(OBJCOPY) -O verilog --verilog-data-width=4 $< $@

# Gera HEX de instruções (.text) (memória Harvard)
$(HEX_TEXT): $(ELF)
	$(OBJCOPY) -O verilog --verilog-data-width=4 \
	--only-section=.text $< $@

# Gera HEX de dados (.data + .bss) (memória Harvard)
$(HEX_DATA): $(ELF)
	$(OBJCOPY) -O verilog --verilog-data-width=4 \
	--change-section-lma .data=0x0 --change-section-lma .bss=0x0 \
	--only-section=.data --only-section=.bss $< $@

# Gera listagem com instruções + dados
$(LST): $(ELF)
	$(OBJDUMP) -D $< > $@
	@echo "Listagem gerada em $(LST)"

clean:
	rm -f $(OBJ) $(ELF) $(HEX) $(HEX_TEXT) $(HEX_DATA) $(LST) *.out dump.vcd dump.log

.PHONY: single multi struct dataflow help clean

multi:
	$(MAKE) VERSION=MULTI

struct:
	$(MAKE) VERSION=MULTI STYLE=STRUCT

dataflow:
	$(MAKE) STYLE=DATAFLOW

help:
	@echo "Makefile para simular o processador LightRISCV"
	@echo "\nVersão do processador: VERSION=$(VERSION)"
	@echo "  SINGLE - Versão single-cycle (default)"
	@echo "  MULTI - Versão multi-cycle"
	@echo "\nEstilo de Verilog: STYLE=$(STYLE)"
	@echo "  DATAFLOW - Versão dataflow (default)"
	@echo "  STRUCT - Versão estrutural"
	@echo "\nTargets disponíveis:"
	@echo "  all               - Compila e gera todos os arquivos"
	@echo "  clean             - Remove arquivos gerados"
	@echo "  help              - Mostra esta mensagem de ajuda"
	@echo "  single            - Alias para VERSION=SINGLE STYLE=DATAFLOW"
	@echo "  multi             - Alias para VERSION=MULTI STYLE=DATAFLOW"
	@echo "  struct            - Alias para VERSION=SINGLE STYLE=STRUCT"
	@echo "  dataflow          - Alias para VERSION=SINGLE STYLE=DATAFLOW"
	@echo "  simul             - Compila e simula os arquivos SystemVerilog (*.sv)"
	@echo "  $(HEX)   - Gera arquivo HEX de memória unificada (von Neumann)"
	@echo "  $(HEX_TEXT)  - Gera arquivo HEX de instruções (Harvard)"
	@echo "  $(HEX_DATA)  - Gera arquivo HEX de dados (Harvard)"
	@echo "  $(LST)          - Gera listagem com instruções + dados"

simul: *.sv
	$(CC) -D$(VERSION) -D$(STYLE) $(FLAGS) *.sv 
# 	$(VVP) a.out | grep -v xxxx | sort > dump.log
# 	$(VVP) a.out > dump.log
	$(VVP) a.out 
# 	$(VIEWER) dump.vcd
# 	$(VIEWER) dump.vcd config.gtkw