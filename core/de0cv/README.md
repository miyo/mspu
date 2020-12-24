
## Environment

- Terasic DE0-CV
- Quartus Prime Lite Edition (20.1.0 Build 711)

## Build

```
sh build.sh
```

## Run

1. programming FPGA
1. set terminal port baudrate 115200 (ex. `stty -F /dev/ttyUSB0 115200`)
1. connect FPGA and host PC via UART<->USB module: P40(FPGA->HOST) = RX, P38(HOST->FPGA) = TX
1. turn on `SW0` to set FPGA in programming mode
1. turn on `SW1` to set FPGA in writing data mode
1. send data into FPGA (ex. `cat hello.data > /dev/ttyUSB0`)
1. turn off `SW1` to set FPGA in writing instructions mode
1. send instructions into FPGA (ex. `cat hello.insn > /dev/ttyUSB0`)
1. open terminal port (ex. `cat /dev/ttyUSB0`)
1. turn off `SW0` to set FPGA in execution mode
1. push `KEY0` to reset FPGA
1. according to instructions, the output is generated (ex. `Hello, RISC-V`)

