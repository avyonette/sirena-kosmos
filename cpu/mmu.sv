package cpu;

typedef enum bit[6:0] {
	MMU_CMD_NOP = 7'd0,
	MMU_CMD_TAVP = 7'd1,
	MMU_CMD_MREAD8 = 7'd2,
	MMU_CMD_MREAD16 = 7'd4,
	MMU_CMD_MREAD32 = 7'd8,
	MMU_CMD_MWRITE8 = 7'd16,
	MMU_CMD_MWRITE16 = 7'd32,
	MMU_CMD_MWRITE32 = 7'd64
} MmuCmd;

typedef enum bit[2:0] {
	MMU_CMD_TAVP_I = 3'd0,
	MMU_CMD_MREAD8_I = 3'd1,
	MMU_CMD_MREAD16_I = 3'd2,
	MMU_CMD_MREAD32_I = 3'd3,
	MMU_CMD_MWRITE8_I = 3'd4,
	MMU_CMD_MWRITE16_I = 3'd5,
	MMU_CMD_MWRITE32_I = 3'd6
} MmuCmdIndex;

endpackage

import cpu::*;
import mem::*;

module cpu_mmu(
	input clk,
	input MmuCmd i_cmd,
	input logic [31:0] i_adr,
	input logic [31:0] i_data,
	output logic [31:0] o_data,
	output logic [23:0] o_padr,
	output logic o_rdy,
	output logic o_done,
	
	// sdram
	output MemCtrlCmd o_sdram_cmd,
	output logic [31:0] o_sdram_adr,
	output logic [7:0] o_sdram_data,
	input logic [7:0] i_sdram_data,
	input logic i_sdram_rdy,
	input logic i_sdram_done,
	
	// sysram
	//output MemCtrlCmd o_sysram_cmd,
	output logic o_sysram_write,
	output logic [16:0] o_sysram_adr,
	output logic [7:0] o_sysram_data,
	input logic [7:0] i_sysram_data
);

	typedef enum bit[2:0] {
		REQ_BYTE = 3'd1,
		REQ_HALF_WORD = 3'd2,
		REQ_WORD = 3'd4
	} ReqSize;
	
	typedef enum bit[1:0] {
		REQ_BYTE_I = 2'd0,
		REQ_HALF_WORD_I = 2'd1,
		REQ_WORD_I = 2'd2
	} ReqSizeIndex;

	typedef enum bit[10:0] {
		S_IDLE = 11'd1,
		S_READ8 = 11'd2,
		S_READ16 = 11'd4,
		S_READ32 = 11'd8,
		S_WRITE8 = 11'd16,
		S_WRITE16 = 11'd32,
		S_WRITE32 = 11'd64,
		S_SDRAM_RET = 11'd128,
		S_SDRAM_WAIT_RDY = 11'd256,
		S_SDRAM_WAIT_DONE = 11'd512,
		S_SYSRAM_RET = 11'd1024
	} State;
	
	typedef enum bit[3:0] {
		S_IDLE_I = 4'd0,
		S_READ8_I = 4'd1,
		S_READ16_I = 4'd2,
		S_READ32_I = 4'd3,
		S_WRITE8_I = 4'd4,
		S_WRITE16_I = 4'd5,
		S_WRITE32_I = 4'd6,
		S_SDRAM_RET_I = 4'd7,
		S_SDRAM_WAIT_RDY_I = 4'd8,
		S_SDRAM_WAIT_DONE_I = 4'd9,
		S_SYSRAM_RET_I = 4'd10
	} StateIndex;
	
	State state;
	State target_state;
	
	//ReqSize cmd_data_size;
	//logic [4:0] data_shift;
	
	// waiting
	logic [6:0] wait_counter;
	logic [6:0] wait_amount;
	//State wait_target;
	
	// address ranges
	parameter
		USER_RAM_BASE = 32'h0000_1000,
		USER_RAM_LIMIT = 32'hFFA0_0000,
		BLIP_ROM_BASE = 32'hFFA0_0000,
		BLIP_ROM_LIMIT = 32'hFFA1_0000,
		PMM1_BASE = 32'hFFFD_E000,
		PMM1_LIMIT = 32'hFFFD_E200,
		SYS_RAM_BASE = 32'hFFFE_0000,
		SYS_RAM_LIMIT = 32'hFFFF_FFFF;
	
	// helpers
	task route_address;
		input MemCtrlCmd i_cmd;
		input [31:0] i_adr;
		input State rdy_state;
		input [31:0] i_data;
		
		begin
			if(i_adr >= USER_RAM_BASE && i_adr < USER_RAM_LIMIT) begin // User RAM
				if(!i_sdram_rdy) begin
					target_state = rdy_state;
					state = S_SDRAM_WAIT_RDY;
				end else begin
					o_sdram_cmd = i_cmd;
					o_sdram_adr = i_adr - USER_RAM_BASE;
					o_sdram_data = i_data;
					
					state = S_SDRAM_WAIT_DONE;
				end
			end else if(i_adr >= BLIP_ROM_BASE && i_adr < BLIP_ROM_LIMIT) begin // BLIP ROM
				;
			end else if(i_adr >= PMM1_BASE && i_adr < PMM1_LIMIT) begin // L1 PMM
				;
			end else if(i_adr >= SYS_RAM_BASE && i_adr <= SYS_RAM_LIMIT) begin // System RAM
				//o_sysram_cmd = i_cmd;
				o_sysram_adr = (i_adr - SYS_RAM_BASE) >> 2 /* word align */; // truncation OK
				o_sysram_data = i_data;
				
				case(1'b1)
					i_cmd[MC_CMD_READ8], i_cmd[MC_CMD_READ16], i_cmd[MC_CMD_READ32]: o_sysram_write = 1'b0;
					i_cmd[MC_CMD_WRITE8], i_cmd[MC_CMD_WRITE16], i_cmd[MC_CMD_WRITE32]: o_sysram_write = 1'b1;
				endcase
				
				state = S_SYSRAM_RET; // can return immediately afterwards; sysram access is a single clock
			end else begin // Reserved
				;
			end
		end
	endtask
	
	/*always @(negedge clk) begin
		o_sdram_cmd = MC_CMD_NOP;
		o_sysram_write = 1'b0;
	end*/

	always @(posedge clk) begin
		//o_rdy = 1'b0;
		
		unique case(1'b1)
			state[S_IDLE_I]: begin
				//o_rdy = 1'b1;
				
				unique case(1'b1)
					i_cmd[MMU_CMD_MREAD8_I]: begin
						//cmd_data_size = REQ_BYTE;
						route_address(MC_CMD_READ8, i_adr, S_READ8, 0);
					end
					i_cmd[MMU_CMD_MREAD16_I]: begin
						//cmd_data_size = REQ_HALF_WORD;
						route_address(MC_CMD_READ16, i_adr, S_READ16, 0);
					end
					i_cmd[MMU_CMD_MREAD32_I]: begin
						//cmd_data_size = REQ_WORD;
						route_address(MC_CMD_READ32, i_adr, S_READ32, 0);
					end
					i_cmd[MMU_CMD_MWRITE8_I]: begin
						//cmd_data_size = REQ_BYTE;
						route_address(MC_CMD_WRITE8, i_adr, S_WRITE8, i_data);
					end
					i_cmd[MMU_CMD_MWRITE16_I]: begin
						//cmd_data_size = REQ_HALF_WORD;
						route_address(MC_CMD_WRITE16, i_adr, S_WRITE16, i_data);
					end
					i_cmd[MMU_CMD_MWRITE32_I]: begin
						//cmd_data_size = REQ_WORD;
						route_address(MC_CMD_WRITE32, i_adr, S_WRITE32, i_data);
					end
					default: begin
						o_rdy = 1'b1;
					end
				endcase

				if(i_cmd != 0) begin
					o_done = 1'b0;
					o_rdy = 1'b0;
				end
			end
			// for rdy wait
			state[S_READ8_I]: route_address(MC_CMD_READ8, i_adr, S_READ8, 0);
			state[S_READ16_I]: route_address(MC_CMD_READ16, i_adr, S_READ16, 0);
			state[S_READ32_I]: route_address(MC_CMD_READ32, i_adr, S_READ32, 0);
			state[S_WRITE8_I]: route_address(MC_CMD_WRITE8, i_adr, S_WRITE8, i_data);
			state[S_WRITE16_I]: route_address(MC_CMD_WRITE16, i_adr, S_WRITE16, i_data);
			state[S_WRITE32_I]: route_address(MC_CMD_WRITE32, i_adr, S_WRITE32, i_data);
			// sdram
			state[S_SDRAM_RET_I]: begin
				o_done = 1'b1;
				o_rdy = 1'b1;
				o_data = i_sdram_data; // if reading the caller will just ignore this
				state = S_IDLE;
				o_sdram_cmd = MC_CMD_NOP;
			end
			state[S_SDRAM_WAIT_RDY_I]: begin
				o_sdram_cmd = MC_CMD_NOP;
				
				if(i_sdram_rdy) begin
					state = target_state;
				end
			end
			state[S_SDRAM_WAIT_DONE_I]: begin
				o_sdram_cmd = MC_CMD_NOP;
				
				if(i_sdram_done) begin
					state = S_SDRAM_RET;
				end
			end
			// sysram
			state[S_SYSRAM_RET_I]: begin
				o_data = i_sysram_data;
				o_done = 1'b1;
				o_rdy = 1'b1;
				o_sysram_write = 1'b0;
				state = S_IDLE;
			end
		endcase
	end
	
endmodule
