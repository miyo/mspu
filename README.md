# MSPU

MSPU is a processor for stream data with multiple small cores. each core is based on RISC-V ISA.

## Archtiecture

MSPU consists of a frontend, an instruction fetcher, processing-units, and connections of them.

- Frontend: receiving and parsing stream data
- Instruction Fetcher: fetching instructions to process arrived stream data
- Processing Unit: RISC-V based core

## Core
Each core is a simple 5-stage pipelined in-order processor which supports RV32IM. A core runs on Arty, DE0-CV, and DE10-lite.
Build scripts are in core/arty, core/de0cv, and de10lite. Sample programs for the core are in sample, written in assembler and C.
