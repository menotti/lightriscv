OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
  text (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
  data (rw)  : ORIGIN = 0x00000100, LENGTH = 64K
}

SECTIONS
{
  /* Código em 0x00000000 */
  .text : {
    *(.text)
    *(.text.*)
  } > text

  /* Dados em 0x00000100 */
  .data : {
    *(.data)
    *(.data.*)
  } > data

  .bss : {
    *(.bss)
    *(.bss.*)
    *(COMMON)
  } > data
}
