_stack_size = 4K;

MEMORY
{
    FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 256K
    SRAM (rwx) : ORIGIN = 0x20000000, LENGTH = 32K
}

SECTIONS
{
    .text :
    {
        _text = .;
        KEEP(*(.isr_vector))
        *(.text*)
        *(.rodata*)
        _etext = .;
    } > FLASH

    .other : AT(_etext)
    {
	_exidx = .;
	*(.ARM.exidx*)
	_eexidx = .;
    } > FLASH

    .bss : AT(ORIGIN(SRAM))
    {
        _bss = .;
        *(COMMON)
        *(.bss*)
        _ebss = .;
    } > SRAM

    .data : AT(_eexidx)
    {
        _data = .;
        *(vtable)
        *(.data*)
        _edata = .;
    } > SRAM
    

    _heap_bottom = .;
    _heap_top = ORIGIN(SRAM) + LENGTH(SRAM) - _stack_size;

    _stack_bottom = _heap_top;
    _stack_top = ORIGIN(SRAM) + LENGTH(SRAM);

}
