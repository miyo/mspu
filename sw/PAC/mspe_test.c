#include <string.h>
#include <uuid/uuid.h>
#include <opae/fpga.h>
#include <time.h>
#include <sys/mman.h>
#include <stdbool.h>
#include <getopt.h>
#include <stdio.h>
#include <stdint.h>
#include <errno.h>
#include <stdbool.h>
#include <sys/stat.h>
#include "safe_string/safe_string.h"
#include <hwloc.h>
#include "fpga_dma.h"

#include <stdlib.h>
#include <assert.h>

#define HELLO_AFU_ID "331DB30C-9885-41EA-9081-F88B8F655CAA"
#define TEST_BUF_SIZE (10 * 1024 * 1024)

static int err_cnt = 0;

// Options determining various optimization attempts
bool do_not_verify = false;

/*
 * macro for checking return codes
 */
#define ON_ERR_GOTO(res, label, desc)                   \
    do {                                                \
        if ((res) != FPGA_OK) {                         \
            err_cnt++;                                  \
            fprintf(stderr, "Error %s: %s\n", (desc),   \
                    fpgaErrStr(res));                   \
            goto label;                                 \
        }                                               \
    } while (0)

/*
 *  *  * Global configuration of bus, set during parse_args()
 *   *   * */
struct config {
    struct target {
        int bus;
    } target;
} config = {.target = {.bus = -1}};

/*
 *  *  * Parse command line arguments
 *   *   */
#define GETOPT_STRING ":B"
fpga_result parse_args(int argc, char *argv[])
{
    struct option longopts[] = {{"bus", required_argument, NULL, 'B'}};

    int getopt_ret;
    int option_index;
    char *endptr = NULL;

    while (-1
           != (getopt_ret = getopt_long(argc, argv, GETOPT_STRING, longopts, &option_index))) {
        const char *tmp_optarg = optarg;
        /* Checks to see if optarg is null and if not goes to value of optarg */
        if ((optarg) && ('=' == *tmp_optarg)) {
            ++tmp_optarg;
        }

        switch (getopt_ret) {
        case 'B': /* bus */
            if (NULL == tmp_optarg)
                break;
            endptr = NULL;
            config.target.bus =
                (int)strtoul(tmp_optarg, &endptr, 0);
            if (endptr != tmp_optarg + strnlen(tmp_optarg, 100)) {
                fprintf(stderr, "invalid bus: %s\n",
                        tmp_optarg);
                return FPGA_EXCEPTION;
            }
            break;
        default: /* invalid option */
            fprintf(stderr, "Invalid cmdline options\n");
            return -1;
        }
    }

    return FPGA_OK;
}

int find_fpga(fpga_guid interface_id, fpga_token *fpga, uint32_t *num_matches)
{
    fpga_properties filter = NULL;
    fpga_result res;

    /* Get number of FPGAs in system*/
    res = fpgaGetProperties(NULL, &filter);
    ON_ERR_GOTO(res, out, "creating properties object");

    res = fpgaPropertiesSetObjectType(filter, FPGA_DEVICE);
    ON_ERR_GOTO(res, out_destroy, "setting interface ID");

    res = fpgaPropertiesSetObjectType(filter, FPGA_ACCELERATOR);
    ON_ERR_GOTO(res, out_destroy, "fpgaPropertiesSetObjectType");

    res = fpgaPropertiesSetGUID(filter, interface_id);
    ON_ERR_GOTO(res, out_destroy, "fpgaPropertiesSetGUID");

    if (-1 != config.target.bus) {
        res = fpgaPropertiesSetBus(filter, config.target.bus);
        ON_ERR_GOTO(res, out_destroy, "setting bus");
    }

    res = fpgaEnumerate(&filter, 1, fpga, 1, num_matches);
    ON_ERR_GOTO(res, out, "enumerating FPGAs");

out_destroy:
    res = fpgaDestroyProperties(&filter);
    ON_ERR_GOTO(res, out, "destroying properties object");
out:
    return err_cnt;
}

// Aligned malloc
static inline void *malloc_aligned(uint64_t align, size_t size)
{
    assert(align && ((align & (align - 1)) == 0)); // Must be power of 2 and not 0
    assert(align >= 2 * sizeof(void *));
    void *blk = NULL;
    blk = malloc(size + align + 2 * sizeof(void *));
    void **aptr = (void **)(((uint64_t)blk + 2 * sizeof(void *) + (align - 1)) & ~(align - 1));
    aptr[-1] = blk;
    aptr[-2] = (void *)(size + align + 2 * sizeof(void *));
    return aptr;
}

// Aligned free
static inline void free_aligned(void *ptr)
{
    void **aptr = (void **)ptr;
    free(aptr[-1]);
    return;
}

// return elapsed time
static inline double getTime(struct timespec start, struct timespec end)
{
    uint64_t diff = 1000000000L * (end.tv_sec - start.tv_sec) + end.tv_nsec - start.tv_nsec;
    return (double)diff / (double)1000000000L;
}

/* functions to get the bus number when there are multiple buses */
struct bus_info {
    uint8_t bus;
};

fpga_result get_bus_info(fpga_token tok, struct bus_info *finfo)
{
    fpga_result res = FPGA_OK;
    fpga_properties props;
    res = fpgaGetProperties(tok, &props);
    ON_ERR_GOTO(res, out, "reading properties from Token");

    res = fpgaPropertiesGetBus(props, &finfo->bus);
    ON_ERR_GOTO(res, out_destroy, "Reading bus from properties");

    if (res != FPGA_OK) {
        return FPGA_EXCEPTION;
    }

out_destroy:
    res = fpgaDestroyProperties(&props);
    ON_ERR_GOTO(res, out, "fpgaDestroyProps");

out:
    return res;
}

void print_bus_info(struct bus_info *info)
{
    printf("Running on bus 0x%02X. \n", info->bus);
}

static void usage(void)
{
    printf("Usage: mspe_test [options]\n");
    printf("Options are:\n");
    printf("\t-B\t Set a target bus number\n");
}

bool dump_mspe_register(fpga_handle* afc_h)
{
    fpga_result res;
    int s1;
    int i;
    for(i = 0; i < 16; i++){
        uint64_t addr = 0x1000+(i*4);
        res = fpgaReadMMIO32(*afc_h, 0, addr, &s1);
        if ((res) != FPGA_OK) {
            printf("error: dump_mspe_register\n");
            return false;
        }
        printf("%08lx(%03ld): %08x\n", addr, ((addr-0x1000)/4), s1);
    }
    return true;
}

void dump_buffer(char *mesg, uint64_t *dma_buf_ptr)
{
    int i;
    printf("%s", mesg);
    for(i = 0; i < 16; i++){
        printf(" %08x", *(((unsigned int*)dma_buf_ptr)+i));
    }
    printf("\n");
}

void kick_mspe(fpga_handle *afc_h, uint64_t src_addr, uint64_t dst_addr, uint64_t data_count, bool debug)
{
    fpga_result res;
    res = fpgaWriteMMIO32(*afc_h, 0, 0x1000L + (7 * 4), (data_count>>32)&0x0FFFFFFFFL);
    res = fpgaWriteMMIO32(*afc_h, 0, 0x1000L + (8 * 4), (data_count>>0)&0x0FFFFFFFFL);
    res = fpgaWriteMMIO32(*afc_h, 0, 0x1000L + (9 * 4), (src_addr>>32)&0x0FFFFFFFFL);
    res = fpgaWriteMMIO32(*afc_h, 0, 0x1000L + (10 * 4), (src_addr>>0)&0x0FFFFFFFFL);
    res = fpgaWriteMMIO32(*afc_h, 0, 0x1000L + (11 * 4), (dst_addr>>32)&0x0FFFFFFFFL);
    res = fpgaWriteMMIO32(*afc_h, 0, 0x1000L + (12 * 4), (dst_addr>>0)&0x0FFFFFFFFL);
    res = fpgaWriteMMIO32(*afc_h, 0, 0x1000L + (1 * 4), 0x00000003); // reset recv_fifo and snd_fifo
    res = fpgaWriteMMIO32(*afc_h, 0, 0x1000L + (1 * 4), 0x00000004); // start

    if(debug){
        dump_mspe_register(afc_h);
    }
}

fpga_result cpu_affinity(fpga_token *afc_token)
{
    fpga_result res = FPGA_OK;
    unsigned dom = 0, bus = 0, dev = 0, func = 0;
    fpga_properties props;
    int retval;
    
    res = fpgaGetProperties(*afc_token, &props);
    if(res != FPGA_OK) return res;
    res = fpgaPropertiesGetBus(props, (uint8_t *)&bus);
    if(res != FPGA_OK) return res;
    res = fpgaPropertiesGetDevice(props, (uint8_t *)&dev);
    if(res != FPGA_OK) return res;
    res = fpgaPropertiesGetFunction(props, (uint8_t *)&func);
    if(res != FPGA_OK) return res;
    
    // Find the device from the topology
    hwloc_topology_t topology;
    hwloc_topology_init(&topology);
    hwloc_topology_set_flags(topology, HWLOC_TOPOLOGY_FLAG_IO_DEVICES);
    hwloc_topology_load(topology);
    hwloc_obj_t obj = hwloc_get_pcidev_by_busid(topology, dom, bus, dev, func);
    hwloc_obj_t obj2 = hwloc_get_non_io_ancestor_obj(topology, obj);
#if HWLOC_API_VERSION > 0x00020000
    retval = hwloc_set_membind(topology, obj2->nodeset, HWLOC_MEMBIND_THREAD, HWLOC_MEMBIND_MIGRATE | HWLOC_MEMBIND_BYNODESET);
#else
    retval = hwloc_set_membind_nodeset(topology, obj2->nodeset, HWLOC_MEMBIND_THREAD, HWLOC_MEMBIND_MIGRATE);
#endif
    if(retval != 0) return res;
    retval = hwloc_set_cpubind(topology, obj2->cpuset, HWLOC_CPUBIND_STRICT);
    if(retval != 0) return res;
    
    return res;
}

fpga_result clear_dest(fpga_dma_handle *dma_h){
    fpga_result res;
    char *ptr = (char *)malloc_aligned(getpagesize(), 128*1024*1024); // 32KB
    res = fpgaDmaTransferSync(*dma_h,
                              0x180000000L /*dst */,
                              (uint64_t)ptr /*src */,
                              128*1024*1024, // 128M
                              HOST_TO_FPGA_MM);
    return res;
}

fpga_result fill_payload(fpga_dma_handle *dma_h, uint64_t offset, uint64_t count, uint64_t *data){
    fpga_result res;
    res = fpgaDmaTransferSync(*dma_h,
                              offset + 0x100000000L /*dst */,
                              (uint64_t)data /*src */,
                              count,
                              HOST_TO_FPGA_MM);
    return res;
}

fpga_result read_payload(fpga_dma_handle *dma_h, uint64_t offset, uint64_t count, uint64_t *data){
    fpga_result res = FPGA_OK;
    
    res = fpgaDmaTransferSync(*dma_h,
                              (uint64_t)data /* dst */,
                              offset + 0x180000000L /* src */,
                              count,
                              FPGA_TO_HOST_MM);
    if(res != FPGA_OK) return res;
    return res;
}

fpga_result fill_instruction(fpga_dma_handle *dma_h, int id, uint64_t count, uint64_t *insn){
    fpga_result res;
    res = fpgaDmaTransferSync(*dma_h,
                              id*32*1024 + 0x000000000L /*dst */,
                              (uint64_t)insn /*src */,
                              count,
                              HOST_TO_FPGA_MM);
    return res;
}

fpga_result set_dummy_payload(fpga_dma_handle *dma_h){
    fpga_result res = FPGA_OK;
    uint64_t *data = NULL;
    data = (uint64_t *)malloc_aligned(getpagesize(), 64); // 64Byte(minimum payload)
    if(!data) return FPGA_EXCEPTION;

    int i, j;
    for(i = 0; i < 5; i++){
        for(j = 0; j < 16; j++) *(((unsigned int*)data)+j) = (i<<8) + j;
        *(((unsigned int*)data)+0) = 1; // len
        *(((unsigned int*)data)+1) = i; // id
        res = fill_payload(dma_h, 64*i, 64, data);
        dump_buffer("fill: ", data);
        if(res != FPGA_OK) return res;
    }
    if(data) free_aligned(data);
    return res;
}

fpga_result set_dummy_instructions(fpga_dma_handle *dma_h){
    fpga_result res = FPGA_OK;
    uint64_t *insn = NULL;
    insn = (uint64_t *)malloc_aligned(getpagesize(), 32*1024); // 32KB
    if(!insn) return FPGA_EXCEPTION;
    
    //*((unsigned int*)insn+0) = 0x0000006F; // halt
    
    // start
    *((unsigned int*)insn+0) = 0x20004437; //          	lui	s0,0x20004
    *((unsigned int*)insn+1) = 0x80040413; //          	addi	s0,s0,-2048 # 20003800 <STREAM_ADDR>
    *((unsigned int*)insn+2) = 0x00010337; //          	lui	t1,0x10
    *((unsigned int*)insn+3) = 0x00840413; //          	addi	s0,s0,8
    *((unsigned int*)insn+4) = 0x00e00513; //          	li	a0,14
    // loop
    *((unsigned int*)insn+5) = 0x00042283; //         	lw	t0,0(s0)
    *((unsigned int*)insn+6) = 0x006282b3; //          	add	t0,t0,t1
    *((unsigned int*)insn+7) = 0x00542023; //          	sw	t0,0(s0)
    *((unsigned int*)insn+8) = 0xfff50513; //          	addi	a0,a0,-1
    *((unsigned int*)insn+9) = 0x00050663; //         	beqz	a0,80000030 <halt>
    *((unsigned int*)insn+10) = 0x00440413; //         	addi	s0,s0,4
    *((unsigned int*)insn+11) = 0xfe9ff06f; //         	j	80000014 <loop>
    // halt
    *((unsigned int*)insn+12) = 0x0000006f; //         	j	80000030 <halt>
    
    res = fill_instruction(dma_h, 0, 32*1024, insn);
    res = fill_instruction(dma_h, 1, 32*1024, insn);
    res = fill_instruction(dma_h, 2, 32*1024, insn);
    res = fill_instruction(dma_h, 3, 32*1024, insn);
    res = fill_instruction(dma_h, 4, 32*1024, insn);
    if(insn) free_aligned(insn);
    return res;
}

int main(int argc, char *argv[])
{
    fpga_result res = FPGA_OK;
    fpga_dma_handle dma_h;
    fpga_token afc_token;
    fpga_handle afc_h;
    fpga_guid guid;
    uint32_t num_matches = 0;
    volatile uint64_t *mmio_ptr = NULL;
    struct bus_info info;

    res = parse_args(argc, argv);
    if (res == FPGA_EXCEPTION) {
        return 1;
    }

    // enumerate the afc
    if (uuid_parse(HELLO_AFU_ID, guid) < 0) {
        return 1;
    }

    res = find_fpga(guid, &afc_token, &num_matches);
    if (num_matches == 0) {
        fprintf(stderr, "No suitable slots found.\n");
        return 1;
    }
    if (num_matches > 1) {
        fprintf(stderr, "Found more than one suitable slot. ");
        res = get_bus_info(afc_token, &info);
        ON_ERR_GOTO(res, out, "getting bus num");
        print_bus_info(&info);
    }

    if (num_matches < 1) {
        printf("Error: Number of matches < 1");
        ON_ERR_GOTO(FPGA_INVALID_PARAM, out, "num_matches<1");
    }

    // open the AFC
    res = fpgaOpen(afc_token, &afc_h, FPGA_OPEN_SHARED);
    ON_ERR_GOTO(res, out_destroy_tok, "fpgaOpen");

    // CPU affinity
    res = cpu_affinity(&afc_token);
    ON_ERR_GOTO(res, out_destroy_tok, "affinity");

    res = fpgaMapMMIO(afc_h, 0, (uint64_t **)&mmio_ptr);
    ON_ERR_GOTO(res, out_close, "fpgaMapMMIO");
        
    // reset AFC
    res = fpgaReset(afc_h);
    ON_ERR_GOTO(res, out_unmap, "fpgaReset");

    res = fpgaDmaOpen(afc_h, &dma_h);
    ON_ERR_GOTO(res, out_dma_close, "fpgaDmaOpen");
    if (!dma_h) {
        res = FPGA_EXCEPTION;
        ON_ERR_GOTO(res, out_dma_close, "Invaid DMA Handle");
    }

    res = set_dummy_instructions(&dma_h);
    ON_ERR_GOTO(res, out_dma_close, "Error set_dummy instruction");

    uint64_t *data = (uint64_t *)malloc_aligned(getpagesize(), 32*1024); // 32KB
    if(!data) return FPGA_EXCEPTION;


    clear_dest(&dma_h);
    printf("- before -------------------------\n");
    res = read_payload(&dma_h, 0, 64, data);
    dump_buffer("result: ", data);
    res = read_payload(&dma_h, 2048, 64, data);
    dump_buffer("result: ", data);
    res = read_payload(&dma_h, 4096, 64, data);
    dump_buffer("result: ", data);
    res = read_payload(&dma_h, 6144, 64, data);
    dump_buffer("result: ", data);
    res = read_payload(&dma_h, 8192, 64, data);
    dump_buffer("result: ", data);
    printf("----------------------------------\n");

    set_dummy_payload(&dma_h);

    kick_mspe(&afc_h,
              0x0000000100000000L /* src */,
              0x0000000180000000L /* dst */,
              5 /* count=16words */,
              //32*1024*1024 /* count=32words=2GB */,
              false /* debug*/ );
    sleep(1);
    dump_mspe_register(&afc_h);
    
    printf("- result -------------------------\n");
    res = read_payload(&dma_h, 0, 64, data);
    dump_buffer("result: ", data);
    res = read_payload(&dma_h, 2048, 64, data);
    dump_buffer("result: ", data);
    res = read_payload(&dma_h, 4096, 64, data);
    dump_buffer("result: ", data);
    res = read_payload(&dma_h, 6144, 64, data);
    dump_buffer("result: ", data);
    res = read_payload(&dma_h, 8192, 64, data);
    dump_buffer("result: ", data);
    printf("----------------------------------\n");
    
    if(data) free_aligned(data);

    ON_ERR_GOTO(res, out_dma_close, "fpgaDmaTransferSync FPGA_TO_HOST_MM");

    /*----------------------------------------------------------------
     * error handling
     *----------------------------------------------------------------*/
out_dma_close:
    if (dma_h)
        res = fpgaDmaClose(dma_h);
    ON_ERR_GOTO(res, out_unmap, "fpgaDmaClose");

out_unmap:
    res = fpgaUnmapMMIO(afc_h, 0);
    ON_ERR_GOTO(res, out_close, "fpgaUnmapMMIO");
        
out_close:
    res = fpgaClose(afc_h);
    ON_ERR_GOTO(res, out_destroy_tok, "fpgaClose");

out_destroy_tok:
    res = fpgaDestroyToken(&afc_token);
    ON_ERR_GOTO(res, out, "fpgaDestroyToken");

out:
    return err_cnt;
}
