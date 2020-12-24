## Environment

- Digilent Arty
- Vivado 2019.2.1

## Build

```
vivado -mode batch -source ./create_prj.tcl
```

## Run

1. connect FPGA and host PC via USB-UART
1. programming FPGA
1. set terminal port baudrate 115200 (ex. `stty -F /dev/ttyUSB1 115200`)
1. turn on `SW0` to set FPGA in programming mode
1. turn on `SW1` to set FPGA in writing data mode
1. send data into FPGA (ex. `cat hello.data > /dev/ttyUSB1`)
1. turn off `SW1` to set FPGA in writing instructions mode
1. send instructions into FPGA (ex. `cat hello.insn > /dev/ttyUSB1`)
1. open terminal port (ex. `cat /dev/ttyUSB1`)
1. turn off `SW0` to set FPGA in execution mode
1. push `BTN0` to reset FPGA
1. according to instructions, the output is generated (ex. `Hello, RISC-V`)

