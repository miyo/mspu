#include <cstdlib>
#include <iostream>
#include <fstream>
#include <vector>
#include <verilated.h>
#include "testbench.h"
#include "Vdiv.h"

int main(int argc, char** argv)
{

    std::vector<unsigned int> insn;
    std::vector<unsigned int> data;
    
    Verilated::commandArgs(argc, argv);
    TESTBENCH<Vdiv> *tb = new TESTBENCH<Vdiv>();
    
    tb->opentrace("div.vcd");
    tb->m_core->kick = 0;
    tb->m_core->dividend = 30;
    tb->m_core->divider = 7;
    
    tb->reset();
                               
    tb->m_core->kick = 1;
    tb->tick();
    tb->m_core->kick = 0;
    tb->tick();
    
    while(tb->m_tickcount < 100){
        tb->tick();
    }

}
