SweRVolf
========

Simple simulation SoC for the [SweRV](https://github.com/westerndigitalcorporation/swerv_eh1) RISC-V core.

This can be used to run the [RISC-V compliance tests](https://github.com/riscv/riscv-compliance) or other software.

The SoC consists of the SweRV CPU with a 16MB memory connected to the instruction bus and one to the data bus, all wrapped up in a simple testbench. Two memory addresses on the data bus has special meaning. Writing to 0x10000000 will print the ascii representation of the lower eight bits to the console. Writing to 0x20000000 will finish the simulation.

## How to use

1. Create an empty workspace directory (from now on called `$WORKSPACE`). All further commands will be run from `$WORKSPACE` unless otherwise stated
2. Make sure you have [FuseSoC](https://github.com/olofk/fusesoc) installed or install it with `pip install fusesoc`
3. Register SweRVolf as a FuseSoC core library `fusesoc library add swervolf https://github.com/olofk/swervolf`
4. Make sure you have verilator installed to run the simulation

### Run a precompiled example

At this point we can now run the bundled hello world example. Copy the pre-built file to the workspace to save some typing `cp ~/.local/share/fusesoc/swervolf/sw/hello.vh $WORKSPACE` and run `fusesoc run --target=sim swervolf --ifu_mem_file=hello.vh --lsu_mem_file=hello.vh`. This should build the simulation model, run it and output `SweRV+FuseSoC rocks` before exiting.

*Note: To see all available options for the chosen target, run `fusesoc run --target=sim swervolf --help`*

*Note: Since the data and instruction bus uses separate memories, we could split the program into different segments (e.g. with `riscv64-unknown-elf-objcopy -j.text -O verilog program.elf text.vh` and `riscv64-unknown-elf-objcopy -j.data -O verilog program.elf data.vh`), but for simplicity we will just load the same file to both instruction and data memories.*

### Run RISC-V compliance tests

1. Build the simulation model, if that hasn't already been done. From $workspace, run `fusesoc run --target=sim --setup --build swervolf`
2. Download the RISC-V compliance tests somewhere. `git clone https://github.com/riscv/riscv-compliance`
3. Enter the directory of the riscv-compliance tests and run `make TARGETDIR=~/.local/share/fusesoc/swervolf/riscv-target RISCV_TARGET=swerv RISCV_DEVICE=rv32i RISCV_ISA=rv32imc TARGET_SIM=$WORKSPACE/build/swervolf_0/sim-verilator/Vtb`

*Note: Other test suites can be run by replacing RISCV_ISA=rv32imc with rv32im or rv32i

