#include <cstdlib>
#include <iostream>
#include <fstream>
#include <vector>
#include <verilated.h>
#include "testbench.h"
#include "Vcore.h"

void load_default(std::vector<unsigned int>& insn, std::vector<unsigned int>& data)
{
    insn = std::vector<unsigned int>{
        0xa0000417, // auipc s0,0xa0000
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
    data = std::vector<unsigned int>{
        0x6c6c6548,
        0x52202c6f,
        0x2d435349,
        0x00000a56
    };
}

int load_insn_and_data(std::vector<unsigned int>& insn, std::vector<unsigned int>& data, char* isrc, char* dsrc)
{
    unsigned int d;
    {
        std::ifstream ifs(isrc, std::ios::in | std::ios::binary);
        if(ifs.is_open() == false) return -1;
        while(!ifs.eof()){
            ifs.read((char*)&d, sizeof(unsigned int));
            insn.push_back(d);
        }
        ifs.close();
    }
    {
        std::ifstream ifs(dsrc, std::ios::in | std::ios::binary);
        if(ifs.is_open() == false) return -1;
        while(!ifs.eof()){
            ifs.read((char*)&d, sizeof(unsigned int));
            data.push_back(d);
        }
        ifs.close();
    }
    return 0;
}

int main(int argc, char** argv)
{

    std::vector<unsigned int> insn;
    std::vector<unsigned int> data;
    
    Verilated::commandArgs(1, argv);
    TESTBENCH<Vcore> *tb = new TESTBENCH<Vcore>();
    
    if(argc < 3){
        std::cout << "load deafult insn/data (Hello, RISC-V)" << std::endl;
        load_default(insn, data);
    }else{
        std::cout << "load insn/data from " << argv[1] << " and " << argv[2] << std::endl;
        int ret = load_insn_and_data(insn, data, argv[1], argv[2]);
        if(ret < 0){
            std::cout << "cannot open insn/data file " << argv[1] << " and/or " << argv[2] << std::endl;
            return 0;
        }
        argv[1][0] = '\0';
        argv[2][0] = '\0';
        argc = 1;
    }
    std::cout << "init" << std::endl;

    tb->opentrace("trace.vcd");
    tb->m_core->run = 0;
                               
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
    int prev_6f = -1;
    while(tb->m_tickcount < 100000){
        if(tb->m_core->uart_we == 1){
            std::cout << (char)(tb->m_core->uart_dout);
        }
        if(tb->m_core->halt_mon == 1){
            std::cout << "halt_mon detected" << std::endl;
            break;
        }else{
            prev_6f = -1;
        }
        tb->tick();
    }

}
