# MSPU

MSPU is a processor for stream data with multiple small cores. each core is based on RISC-V ISA.

## Archtiecture

MSPU consists of a frontend, an instruction fetcher, processing-units, and connections of them.

- Frontend: receiving and parsing stream data
- Instruction Fetcher: fetching instructions to process arrived stream data
- Processing Unit: RISC-V based core

## Core
Each core is a simple 5-stage pipelined in-order processor which supports RV32IM. A core runs on Arty, DE0-CV, and DE10-lite as standalone processing system.
Build scripts are in core/arty, core/de0cv, and core/de10lite. Sample programs for the core are in core/sample, written in assembler and C.

### Tools
Samples in core/sample are compiled with GNU tool chain. In my environment, the tool chain is built with `crosstool-ng` as the following.

```
$ wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.24.0.tar.bz2
$ tar xvf crosstool-ng-1.24.0.tar.bz2
$ cd crosstool-ng-1.24.0
$ ./configure --prefix=$HOME/tools/crosstool-ng
$ export PATH=$HOME/tools/crosstool-ng/bin:$PATH
$ rehash
$ ct-ng update-samples
$ ct-ng list-samples | grep riscv
$ ct-ng riscv64-unknown-elf
$ vi .config # I set $HOME/tools/ct-ng/ for CT_PREFIX_DIR 
$ ct-ng build
```
