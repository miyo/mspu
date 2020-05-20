#include <cstdlib>
#include <iostream>
#include <fstream>
#include <vector>
#include <verilated.h>
#include "testbench.h"
#include "Vshift.h"

int op(TESTBENCH<Vshift> *tb, int a, int b, int lshift, int unsigned_flag){
    tb->m_core->a = a;
    tb->m_core->b = b;
    tb->m_core->lshift = lshift;
    tb->m_core->unsigned_flag = unsigned_flag;
    
    tb->m_core->kick = 1;
    tb->tick();
    tb->m_core->kick = 0;
    tb->tick();
    
    for(int i = 0; i < 100; i++){
        tb->tick();
    }

    return tb->m_core->q;
}

int main(int argc, char** argv)
{

    std::vector<unsigned int> insn;
    std::vector<unsigned int> data;
    
    Verilated::commandArgs(argc, argv);
    TESTBENCH<Vshift> *tb = new TESTBENCH<Vshift>();
    
    tb->opentrace("shift.vcd");
    
    tb->m_core->kick = 0;
    tb->reset();

    int q;
    
    if((q = op(tb, 0xa0a0a0a0, 4, 1, 0)) == 0x0a0a0a00){
        std::cout << "lshift OK" << std::endl;
    }else{
        std::cout << "lshift error: " << std::hex << q << std::endl;
    }
    
    if((q = op(tb, 0xa0a0a0a0, 4, 0, 0)) == 0xfa0a0a0a){
        std::cout << "signed rshift OK" << std::endl;
    }else{
        std::cout << "signed rshift error: " << std::hex << q << std::endl;
    }
    
    if((q = op(tb, 0xa0a0a0a0, 4, 0, 1)) == 0x0a0a0a0a){
        std::cout << "unsigned rshift OK" << std::endl;
    }else{
        std::cout << "unsigned rshift error: " << std::hex << q << std::endl;
    }

}
