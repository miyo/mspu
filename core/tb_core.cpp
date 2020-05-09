#include <iostream>
#include <vector>
#include <verilated.h>
#include "testbench.h"
#include "Vcore.h"

int main(int argc, char** argv) {

    Verilated::commandArgs(argc, argv);

    TESTBENCH<Vcore> *tb = new TESTBENCH<Vcore>();
    
    tb->opentrace("trace.vcd");
    tb->m_core->run = 0;
    
    std::cout << "init" << std::endl;

    std::vector<unsigned int> insn = {
        0x40000417, // auipc s0,0x0
        0x00040413, // mv    s0,s0
        0x00040503, // lb    a0,0(s0)
        0x00140413, // addi  s0,s0,1
        0x00050c63, // beqz  a0,80000028 <halt>
        0x008000ef, // jal   ra,8000001c <putchar>
        0xff1ff06f, // j     80000008 <loop>
        0x100002b7, // lui   t0,0x10000
        0x00a28023, // sb    a0,0(t0)
        0x00008067, // ret
        0x0000006f  // j halt
    };
    std::vector<unsigned int> data = {
        0x6c6c6548,
        0x52202c6f,
        0x2d435349,
        0x00000a56
    };
                           
    for(int i = 0; i < insn.size(); i++){
        tb->m_core->insn_addr = 4*i;
        tb->m_core->insn_din = insn[i];
        tb->m_core->insn_we = 1;
        tb->tick();
    }
    tb->m_core->insn_we = 0;
    
    for(int i = 0; i < data.size(); i++){
        tb->m_core->data_addr = 4*i;
        tb->m_core->data_din = data[i];
        tb->m_core->data_we = 1;
        tb->tick();
    }
    tb->m_core->data_we = 0;

    tb->m_core->run = 1;
    while(tb->m_tickcount < 1000){
        if(tb->m_core->uart_we == 1){
            std::cout << (char)(tb->m_core->uart_dout);
        }
        tb->tick();
    }

}
