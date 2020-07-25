`default_nettype none

module data_loader#(parameter CORES=4, INSN_DEPTH=12, DMEM_DEPTH=14)
    (
     input wire clk,
     input wire reset,

     input wire kick,
     output wire busy,
     input wire [63:0] memory_base_addr,
     input wire [$clog2(CORES)-1:0] target_core,

     output wire [$clog2(CORES)+INSN_DEPTH+2-1:0] insn_addr,
     output wire [31:0] insn_dout,
     output wire        insn_we,
     
     output wire [$clog2(CORES)+DMEM_DEPTH+2-1:0] data_addr,
     output wire [31:0] data_dout,
     output wire        data_we,

     input  wire           m0_waitrequest, 
     input  wire [512-1:0] m0_readdata,
     input  wire           m0_readdatavalid,
     output wire [3-1:0]   m0_burstcount,
     output wire [512-1:0] m0_writedata,
     output wire [64-1:0]  m0_address,
     output wire           m0_write,
     output wire           m0_read,
     output wire [63:0]    m0_byteenable
     );

    localparam INSN_NUM = 2**INSN_DEPTH;
    localparam DMEM_NUM = 2**DMEM_DEPTH;

    logic [$clog2(CORES)-1:0] target_core_reg;

    logic [31:0] insn_addr_reg;
    logic [31:0] insn_dout_reg;
    logic insn_we_reg;
    assign insn_addr = {target_core_reg, insn_addr_reg[INSN_DEPTH+2-1:0]};
    assign insn_dout = insn_dout_reg;
    assign insn_we = insn_we_reg;

    logic [31:0] data_addr_reg;
    logic [31:0] data_dout_reg;
    logic data_we_reg;
    assign data_addr = {target_core_reg, data_addr_reg[DMEM_DEPTH+2-1:0]};
    assign data_dout = data_dout_reg;
    assign data_we = data_we_reg;

    logic [512-1:0] m0_readdata_reg;
    logic [3-1:0]   m0_burstcount_reg;
    logic [512-1:0] m0_writedata_reg;
    logic [64-1:0]  m0_address_reg;
    logic           m0_write_reg;
    logic           m0_read_reg;
    logic [63:0]    m0_byteenable_reg;

    assign m0_burstcount = m0_burstcount_reg;
    assign m0_writedata  = m0_writedata_reg;
    assign m0_address    = m0_address_reg;
    assign m0_write      = m0_write_reg;
    assign m0_read       = m0_read_reg;
    assign m0_byteenable = m0_byteenable_reg;

    logic [31:0] state_counter;
    logic busy_reg;

    assign busy = busy_reg | kick;

    logic [63:0] mem_counter;
    logic [31:0] insn_counter;
    logic [31:0] data_counter;

    logic [63:0] memory_base_addr_reg;

    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    m0_burstcount_reg <= 1;
	    m0_writedata_reg <= 0;
	    m0_address_reg <= 0;
	    m0_write_reg <= 0;
	    m0_read_reg <= 0;
	    m0_byteenable_reg <= 0;
	    state_counter <= 0;
	    busy_reg <= 0;
	    insn_addr_reg <= 0;
	    data_addr_reg <= 0;
	end else begin

	    case(state_counter)
		0: begin
		    if(kick == 1) begin
			busy_reg <= 1;
			state_counter <= state_counter + 1;
		    end else begin
			busy_reg <= 0;
		    end
		    mem_counter <= 0;
		    insn_counter <= 0;
		    data_counter <= 0;
		    m0_read_reg <= 0;
		    insn_we_reg <= 0;
		    data_we_reg <= 0;
		    memory_base_addr_reg <= memory_base_addr;
		    target_core_reg <= target_core;
		    insn_addr_reg <= 0;
		    data_addr_reg <= 0;
		    insn_dout_reg <= 0;
		    data_dout_reg <= 0;
		end

		1: begin // read request to Avalon-MM
		    m0_address_reg <= {mem_counter[57:0], 6'b000000} + memory_base_addr_reg;
		    m0_read_reg <= 1;
		    state_counter <= state_counter + 1;
		    insn_we_reg <= 0;
		end
		2: begin // wait for readdatavalid
		    m0_read_reg <= 0;
		    if(m0_readdatavalid == 1) begin
			m0_readdata_reg <= m0_readdata;
			state_counter <= state_counter + 1;
		    end
		end
		3: begin // write insn
		    if(insn_counter[3:0] == 15) begin
			if(insn_counter == INSN_NUM-1) begin
			    state_counter <= 4;
			end else begin
			    state_counter <= 1;
			end
			mem_counter <= mem_counter + 1;
		    end
		    insn_addr_reg <= {insn_counter[29:0], 2'b00};
		    insn_dout_reg <= m0_readdata_reg[511:480];
		    insn_we_reg <= 1;
		    m0_readdata_reg <= {m0_readdata_reg[479:0], 32'h0};
		    insn_counter <= insn_counter + 1;
		end

		4: begin // read request to Avalon-MM
		    m0_address_reg <= {mem_counter[57:0], 6'b000000} + memory_base_addr_reg;
		    m0_read_reg <= 1;
		    state_counter <= state_counter + 1;
		    data_we_reg <= 0;
		    insn_we_reg <= 0;
		end
		5: begin // wait for readdatavalid
		    m0_read_reg <= 0;
		    if(m0_readdatavalid == 1) begin
			m0_readdata_reg <= m0_readdata;
			state_counter <= state_counter + 1;
		    end
		end
		6: begin // write data
		    if(data_counter[3:0] == 15) begin
			if(data_counter == DMEM_NUM-1) begin
			    state_counter <= 0;
			end else begin
			    state_counter <= 4;
			end
			mem_counter <= mem_counter + 1;
		    end
		    data_addr_reg <= {data_counter[29:0], 2'b00};
		    data_dout_reg <= m0_readdata_reg[511:480];
		    data_we_reg <= 1;
		    m0_readdata_reg <= {m0_readdata_reg[479:0], 32'h0};
		    data_counter <= data_counter + 1;
		end

		default: begin
		    state_counter <= 0;
		    insn_we_reg <= 0;
		    data_we_reg <= 0;
		    m0_read_reg <= 0;
		end

	    endcase
	end
    end

endmodule // data_loader

`default_nettype wire
