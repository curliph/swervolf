%.elf: %.S
	riscv64-unknown-elf-gcc -nostartfiles -march=rv32i -mabi=ilp32 -Tlink.ld -o$@ $<
%.vh: %.elf
	riscv64-unknown-elf-objcopy -O verilog $< $@
clean:
	rm -f *.elf *.bin *.vh
