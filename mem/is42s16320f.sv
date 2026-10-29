// specifically; -7TL, 143 MHz
/*
	this is a very basic simple controller with many optimizations that could be done, such as
	- burst access
	- full word access when requesting 16/32-bit I/O instead of always 8-bit
	- S_CMD_WAIT based on the command

	based on the documentation at https://www.issi.com/WW/pdf/42-45R-S_86400F-16320F.pdf
*/
import mem::*;

module is42s16320f_controller
#(parameter CLK_TIME_NS = 20)
(
	input logic clk, // FPGA clock
	input MemCtrlCmd i_cmd, // command
	input logic [31:0] i_adr, // address
	input logic [31:0] i_data, // data for writing
	output logic [31:0] o_data, // result from reading
	output logic o_rdy, // controller is idle (ready to receive commands)
	output logic o_done, // command has finished
	output logic o_clk, // DRAM clock
	output logic o_cke, // clock enable
	output logic o_cs, // chip select
	output logic o_ras, // row address strobe
	output logic o_cas, // column access strobe
	output logic o_we, // write enable
	output logic [12:0] o_a, // address
	output logic [1:0] o_ba, // bank address
	output logic o_dqml, // data qualifier mask low
	output logic o_dqmh, // data qualifier mask high
	inout logic [15:0] io_dq // data qualifier
);

	assign o_clk = clk;
	assign o_cke = 1'b1; // always HIGH except for self-refresh but we don't really care about that
	
	logic dq_rw = 1'b0;
	logic [15:0] o_dq = 16'b0;
	
	assign io_dq = dq_rw ? o_dq : 16'hZZ;
	wire [15:0] i_dq = io_dq;
	
	localparam H = 1'b1; // high
	localparam L = 1'b0; // low

	localparam INIT_DELAY_NS = 100_000; // 20. Initialization
	localparam INIT_CYCLES = INIT_DELAY_NS / CLK_TIME_NS;
	
	localparam REFRESH_TIME_NS = 64_000_000 / 8192; // 1. ADDRESS TABLE/Refresh Count (A1)
	localparam REFRESH_CYCLES = REFRESH_TIME_NS / CLK_TIME_NS;
	
	localparam T_RC_NS = 63; // 18. LATENCY RELATIONSHIPS
	localparam T_RC_CYCLES = (T_RC_NS + CLK_TIME_NS - 1) / CLK_TIME_NS; // round up
	
	typedef enum bit[17:0] {
		S_NONE = 18'd0,
		S_INIT = 18'd1,
		S_INIT_PRECHARGE = 18'd2,
		S_INIT_REFRESH = 18'd4,
		S_INIT_SETUP = 18'd8,
		S_INIT_OK = 18'd16,
		S_WORK_IDLE = 18'd32,
		S_WORK_ACTIVATE = 18'd64,
		S_WORK_READ8 = 18'd128,
		S_WORK_READ8_RESULT = 18'd256,
		S_WORK_WRITE8 = 18'd512,
		S_WORK_PRECHARGE = 18'd1024,
		S_CMD_WAIT = 18'd2048,
		S_WORK_READ16 = 18'd4096,
		S_WORK_READ16_RESULT = 18'd8192,
		S_WORK_READ32 = 18'd16384,
		S_WORK_READ32_RESULT = 18'd32768,
		S_WORK_WRITE16 = 18'd65536,
		S_WORK_WRITE32 = 18'd131072
	} State;
	
	localparam
		S_INIT_I = 0,
		S_INIT_PRECHARGE_I = 1,
		S_INIT_REFRESH_I = 2,
		S_INIT_SETUP_I = 3,
		S_INIT_OK_I = 4,
		S_WORK_IDLE_I = 5,
		S_WORK_ACTIVATE_I = 6,
		S_WORK_READ8_I = 7,
		S_WORK_READ8_RESULT_I = 8,
		S_WORK_WRITE8_I = 9,
		S_WORK_PRECHARGE_I = 10,
		S_CMD_WAIT_I = 11,
		S_WORK_READ16_I = 12,
		S_WORK_READ16_RESULT_I = 13,
		S_WORK_READ32_I = 14,
		S_WORK_READ32_RESULT_I = 15,
		S_WORK_WRITE16_I = 16,
		S_WORK_WRITE32_I = 17;
	
	// state
	State state = S_INIT;
	State target_state = S_INIT;
	
	// counters
	reg [31:0] clk_counter = 0;
	reg [31:0] wait_counter = 0;
	reg [31:0] wait_time = 0;
	
	// helper functions
	task call_command;
		//input set_state;
		input [31:0] cmd_cycles;
		input State next_state;
		input cs;
		input ras;
		input cas;
		input we;
		input [1:0] ba;
		input [12:0] a;
		
		begin
			o_cs = cs;
			o_ras = ras;
			o_cas = cas;
			o_we = we;
			o_ba = ba;
			o_a = a;
			
			if(cmd_cycles > 0) begin
				state = S_CMD_WAIT;
				target_state = next_state;
				wait_time = cmd_cycles;
			end
		end
	endtask
	
	//
	reg lo_hi_sel = 1'b0;
	
	/*
		address encoding:
		0b000000BBRRRRRRRRRRRRRCCCCCCCCCCW
	*/
	reg [1:0] adr_bank_index = 2'b0;
	reg [9:0] adr_col_index = 10'b0;
	reg [12:0] adr_row_index = 13'b0;
	
	reg [12:0] ref_counter = 13'b0;
	
	always @(posedge clk) begin
		ref_counter = ref_counter + 1'b1;
	
		unique case(1'b1)
			// initialisation cycle
			// INIT -> PRECHARGE ALL -> REFRESH x2 -> LOAD MODE REGISTER -> OK (IDLE)
			state[S_INIT_I]: begin
				// wait for INIT_CYCLES before calling first command
				if(clk_counter < INIT_CYCLES) begin
					call_command(0, S_NONE, L, H, H, H, 0, 0); // NOP
					clk_counter = clk_counter + 1;
				end else begin
					clk_counter = 0;
					state = S_INIT_PRECHARGE;
				end
			end
			state[S_INIT_PRECHARGE_I]: begin
				call_command(T_RC_CYCLES, S_INIT_REFRESH, L, L, H, L, 0, 13'b0010000000000); // PALL
			end
			state[S_INIT_REFRESH_I]: begin
				if(clk_counter < 2) begin // two AUTO REFRESH cycles
					call_command(T_RC_CYCLES, S_INIT_REFRESH, L, L, L, H, 0, 0); // REF
					clk_counter = clk_counter + 1;
				end else begin
					clk_counter = 0;
					state = S_INIT_SETUP;
				end
			end
			state[S_INIT_SETUP_I]: begin
				// 24. MODE REGISTER DEFINITION
				// SLA, SO, CL3, S, 1
				call_command(T_RC_CYCLES, S_INIT_OK, L, L, L, L, 0, 13'b0001000110000); // MRS
			end
			state[S_INIT_OK_I]: begin
				o_dqmh = L;
				o_dqml = L;
				state = S_WORK_IDLE; // init complete, switch to work cycle
			end
			// work cycle
			state[S_WORK_IDLE_I]: begin
				dq_rw = 1'b0; // dq is read normally, write enabled only in S_WORK_WRITE
				
				unique case(1'b1)
					i_cmd[MC_CMD_READ8_I]: target_state = S_WORK_READ8;
					i_cmd[MC_CMD_READ16_I]: target_state = S_WORK_READ16;
					i_cmd[MC_CMD_READ32_I]: target_state = S_WORK_READ32;
					i_cmd[MC_CMD_WRITE8_I]: target_state = S_WORK_WRITE8;
					i_cmd[MC_CMD_WRITE16_I]: target_state = S_WORK_WRITE16;
					i_cmd[MC_CMD_WRITE32_I]: target_state = S_WORK_WRITE32;
					default: begin
						o_rdy = 1'b1;
						
						// periodic refresh
						if(ref_counter < REFRESH_CYCLES) begin
							//ref_counter = ref_counter + 1'b1;
							call_command(0, S_NONE, L, H, H, H, 0, 0); // NOP
						end else begin
							call_command(0, S_NONE, L, L, L, H, 0, 0); // REF
							ref_counter = 0;
						end
					end
				endcase
				
				if(i_cmd != 0) begin
					state = S_WORK_ACTIVATE;
					o_rdy = 1'b0;
					o_done = 1'b0;
					
					// this truncates; that's fine
					adr_bank_index = i_adr >> 24; // 4 banks, 128 Mb (16 MiB) per bank
					adr_col_index = ((i_adr & 32'hFFFFFF) >> 1) & 10'h3FF; // low 10 bits after word alignment = column
					adr_row_index = ((i_adr & 32'hFFFFFF) >> 11) & 13'h1FFF; // high 13 bits = row
					//lo_hi_sel = i_adr & 1; // 16-bit word

					if(i_cmd[MC_CMD_READ32_I] || i_cmd[MC_CMD_WRITE32_I]) begin
						lo_hi_sel = 1'b0;
					end else begin
						lo_hi_sel = i_adr & 1'b1; // 16-bit word
					end
				end
			
			end
			state[S_WORK_ACTIVATE_I]: begin
				unique case(1'b1)
					i_cmd[MC_CMD_READ8_I], i_cmd[MC_CMD_WRITE8_I]: begin
						if(lo_hi_sel == 1'b1) begin
							// high 8 bit access
							o_dqmh = L;
							o_dqml = H; // high impedance - ignored
						end else begin
							// low 8 bit access
							o_dqmh = H; // high impedance - ignored
							o_dqml = L;
						end
					end
					default: begin
						o_dqmh = L;
						o_dqml = L;
					end
				endcase
				
				// need to wait 2 cycles for DQM to propagate (?)
				// "DQ's read data is subject to the logic level on the DQM inputs two clocks earlier"
				if(clk_counter < 2) begin
					clk_counter = clk_counter + 1;
					call_command(0, S_NONE, L, H, H, H, 0, 0); // NOP
				end else begin
					clk_counter = 0;
					call_command(T_RC_CYCLES, target_state, L, L, H, H, adr_bank_index, adr_row_index); // ACT
				end
			end
			state[S_WORK_READ8_I]: begin
				call_command(T_RC_CYCLES, S_WORK_READ8_RESULT, L, H, L, H, adr_bank_index, adr_col_index); // READ
			end
			state[S_WORK_READ8_RESULT_I]: begin
				if(lo_hi_sel == 1'b1) begin
					// high selector
					o_data = i_dq[15:8];
				end else begin
					// low selector
					o_data = i_dq[7:0];
				end
				
				state = S_WORK_PRECHARGE;
				o_done = 1'b1;
			end
			state[S_WORK_READ16_I]: begin
				call_command(T_RC_CYCLES, S_WORK_READ16_RESULT, L, H, L, H, adr_bank_index, adr_col_index); // READ
			end
			state[S_WORK_READ16_RESULT_I]: begin
				o_data = i_dq;
				state = S_WORK_PRECHARGE;
				o_done = 1'b1;
			end
			state[S_WORK_READ32_I]: begin
				// reusing the low/high selector but in a silly way :3 (i.e. for low/high word selection)
				// TODO is it possible for +1 to be out of the row/col/bank range when reading a 32-bit aligned address?
				call_command(T_RC_CYCLES, S_WORK_READ32_RESULT, L, H, L, H, adr_bank_index, adr_col_index + lo_hi_sel); // READ
			end
			state[S_WORK_READ32_RESULT_I]: begin
				if(lo_hi_sel == 1'b0) begin
					o_data[15:0] = i_dq;
					lo_hi_sel = 1'b1;
					state = S_WORK_READ32;
				end else begin
					o_data[31:16] = i_dq;
					lo_hi_sel = 1'b0;
					state = S_WORK_PRECHARGE;
					o_done = 1'b1;
				end
			end
			state[S_WORK_WRITE8_I]: begin
				dq_rw = 1'b1; // make dq writeable
				
				if(lo_hi_sel == 1'b1) begin
					// high selector
					o_dq[15:8] = i_data[7:0];
				end else begin
					// low selector
					o_dq[7:0] = i_data[7:0];
				end
				
				o_done = 1'b1;
				call_command(T_RC_CYCLES, S_WORK_PRECHARGE, L, H, L, L, adr_bank_index, adr_col_index); // WRITE
			end
			state[S_WORK_WRITE16_I]: begin
				dq_rw = 1'b1; // make dq writeable
				o_dq = i_data[15:0];
				o_done = 1'b1;
				call_command(T_RC_CYCLES, S_WORK_PRECHARGE, L, H, L, L, adr_bank_index, adr_col_index); // WRITE
			end
			state[S_WORK_WRITE32_I]: begin
				// reusing the low/high selector but in a silly way :3 (i.e. for low/high word selection)
				dq_rw = 1'b1; // make dq writeable
				
				if(lo_hi_sel == 1'b0) begin
					o_dq = i_data[15:0];
					lo_hi_sel = 1'b1;
					call_command(T_RC_CYCLES, S_WORK_WRITE32, L, H, L, L, adr_bank_index, adr_col_index); // WRITE
				end else begin
					o_dq = i_data[31:16];
					lo_hi_sel = 1'b0;
					call_command(T_RC_CYCLES, S_WORK_PRECHARGE, L, H, L, L, adr_bank_index, adr_col_index + 1); // WRITE
					o_done = 1'b1;
				end
			end
			state[S_WORK_PRECHARGE_I]: begin
				call_command(T_RC_CYCLES, S_WORK_IDLE, L, L, H, L, adr_bank_index, 0); // PRE
				//s = 1'b1;
				o_rdy = 1'b1;
			end
			// cmd wait
			state[S_CMD_WAIT_I]: begin
				call_command(0, S_NONE, L, H, H, H, 0, 0); // NOP
				
				if(wait_counter < wait_time) begin
					wait_counter = wait_counter + 1;
				end else begin
					state = target_state;
					wait_counter = 0;
				end
			end
			default: state = S_WORK_IDLE;
		endcase
	end

endmodule
