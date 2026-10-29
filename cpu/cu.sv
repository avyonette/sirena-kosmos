module cpu_cu(
	input clk,
	
	/* register sysram */
	output logic o_sysram_write,
	output logic [16:0] o_sysram_adr,
	output logic [31:0] o_sysram_data,
	input logic [31:0] i_sysram_data,
	
	/* MMU */
	output MmuCmd mmu_cmd,
	output [31:0] mmu_adr_in,
	output [31:0] mmu_data_in,
	input [31:0] mmu_data_out,
	input [31:0] mmu_padr_out,
	input mmu_rdy,
	input mmu_done,
	
	// for debug
	input [9:0] SW,
	input [1:0] KEY,
	output reg [9:0] LEDR,
	output reg [7:0] HEX0,
	output reg [7:0] HEX1,
	output reg [7:0] HEX2,
	output reg [7:0] HEX3,
	output reg [7:0] HEX4,
	output reg [7:0] HEX5
);

	typedef enum bit[4:0] {
		S_FREEZE,
		S_INIT_REGS,
		S_FETCH_RIP_V2P,
		S_FETCH_READ_INST,
		S_DECODE,
		S_EXECUTE,
		//S_WAIT,
		S_WAIT_MMU_RDY,
		S_WAIT_MMU_DONE
	} State;
	
	logic [23:0] dbg_hex;
	logic [9:0] dbg_led;
	
	logic [31:0] dbg_num = 31'b0;
	assign dbg_hex = dbg_num[31:8];
	assign dbg_led[9:2] = dbg_num[7:0];
	
	DbgMode dbg_mode;
	logic dbg_freeze;
	logic [4:0] dbg_args;
	
	dbg_interface m_dbg(
		.i_hex_dp(dbg_hex),
		.i_led_dp(dbg_led),
		.o_mode(dbg_mode),
		.o_args(dbg_args),
		.o_freeze(dbg_freeze),
		.*
	);
	
	wire [31:0] rfp;
	wire [31:0] rrap;
	wire [31:0] rz;
	
	logic [31:0][31:0] reg_in;
	logic [31:0][31:0] reg_out;
	
	logic [31:0] reg_rs; // read select
	logic [31:0] reg_ws; // write select
	
	cpu_reg m_reg(
		.io_rfp(rfp),
		.io_rrap(rrap),
		.io_rz(rz),
		.i_reg(reg_in),
		.o_reg(reg_out),
		.i_r(reg_rs),
		.i_w(reg_ws),
		.*
	);
	
	// counters
	/*reg [31:0] wait_counter = 0;
	reg [31:0] wait_time = 0;*/
	
	State state = S_INIT_REGS;
	State target_state = S_INIT_REGS;
	
	CpuRegister pr_reg = REG_RIP;
	
	logic [31:0] c_inst = 31'b0;
	
	always @(posedge clk) begin
		reg_rs <= 32'b0;
		reg_ws <= 32'b0;
		
		mmu_cmd <= MMU_CMD_NOP;
		
		unique case(state)
			S_INIT_REGS: begin
				// read all required registers for a single step (rip, rpdp, rcf)
				// one reg - one cycle
				case(pr_reg)
					REG_RIP: begin
						reg_rs[REG_RIP] <= 1'b1;
						pr_reg <= REG_RPDP;
					end
					REG_RPDP: begin
						reg_rs[REG_RPDP] <= 1'b1;
						pr_reg <= REG_RCF;
					end
					REG_RCF: begin
						reg_rs[REG_RCF] <= 1'b1;
						pr_reg <= REG_RIP;
						state <= dbg_freeze ? S_FREEZE : S_FETCH_RIP_V2P;
					end
				endcase
			end
			S_FETCH_RIP_V2P: begin
				// TODO convert virtual address to physical...
				state <= S_FETCH_READ_INST;
			end
			S_FETCH_READ_INST: begin
				mmu_cmd <= MMU_CMD_MREAD32;
				mmu_adr_in <= reg_out[REG_RIP];
				
				target_state <= S_DECODE;
				state <= S_WAIT_MMU_DONE;
			end
			S_DECODE: begin
				c_inst <= mmu_data_out;
				state <= S_EXECUTE;
			end
			S_EXECUTE: begin
				// execute...
				
				// increment RIP
				reg_ws[REG_RIP] <= 1'b1;
				reg_in[REG_RIP] <= reg_out[REG_RIP] + 1;
				
				state <= S_INIT_REGS;
			end
			/*S_WAIT: begin
				if(wait_counter < wait_time) begin
					wait_counter = wait_counter + 1;
				end else begin
					state = target_state;
				end
			end*/
			S_WAIT_MMU_RDY: begin
				if(mmu_rdy) state <= target_state;
			end
			S_WAIT_MMU_DONE: begin
				if(mmu_rdy) state <= target_state;
			end
			S_FREEZE: begin
				if(!dbg_freeze) state <= S_FETCH_RIP_V2P;
			end
		endcase
		
		// debug
		unique case(dbg_mode)
			DM_SHOW_RIP: begin
				dbg_num <= reg_out[REG_RIP];
			end
			DM_SHOW_INST: begin
				dbg_num <= c_inst;
			end
			default: ;
		endcase
	end

endmodule