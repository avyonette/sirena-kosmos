`define I_OPSET mmu_data_out[3:0]
`define I_OPCODE mmu_data_out[8:4]
`define J_TG mmu_data_out[26:9]

module cpu_cu(
	input clk,
	
	/* register sysram */
	output logic o_sysram_write,
	output logic [14:0] o_sysram_adr,
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
		S_RESET,
		S_LOAD_REGS,
		S_FETCH_RIP_V2P,
		S_FETCH_READ_INST,
		S_DECODE_EXECUTE,
		S_ADVANCE,
		//S_WAIT,
		S_WAIT_MMU_RDY,
		S_WAIT_MMU_DONE
	} State;
	
	logic [23:0] dbg_hex;
	logic [9:0] dbg_led;
	
	logic [31:0] dbg_num = 32'b0;
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
	
	logic [31:0] rfp_rd;
	logic [31:0] rfp_wr;
	logic rfp_ws;
	
	logic [31:0] rrap_rd;
	logic [31:0] rrap_wr;
	logic rrap_ws;
	
	logic [31:0] rz_rd;
	
	logic [27:0][31:0] reg_rd;
	logic [27:0][31:0] reg_wr;
	
	logic [27:0] reg_rs; // read select
	logic [27:0] reg_ws; // write select
	
	cpu_registers m_reg(
		//.io_rfp(rfp),
		//.io_rrap(rrap),
		//.io_rz(rz),
		.i_rfp(rfp_wr),
		.o_rfp(rfp_rd),
		.i_w_rfp(rfp_ws),
		.i_rrap(rrap_wr),
		.o_rrap(rrap_rd),
		.i_w_rrap(rrap_ws),
		.o_rz(rz_rd),
		.i_reg(reg_wr),
		.o_reg(reg_rd),
		.i_r(reg_rs),
		.i_w(reg_ws),
		.*
	);
	
	// counters
	/*reg [31:0] wait_counter = 0;
	reg [31:0] wait_time = 0;*/
	
	State state = S_RESET;
	State target_state = S_RESET;
	
	CpuRegister rst_reg = REG_RFP;
	CpuRegister pr_reg = REG_RIP;
	
	logic [31:0] i_data = 31'b0; // instruction data
	logic advance_ip = 1'b1;
	/*logic [3:0] i_opset;
	logic [4:0] i_opcode;
	
	// R-type instruction
	logic [4:0] r_ds;
	logic [4:0] r_ra;
	logic [4:0] r_rb;
	logic [7:0] r_ff;
	
	// I-type instruction
	logic [4:0] i_ds;
	logic [15:0] i_vl;
	logic [1:0] i_ff;
	
	// J-type instructions
	logic [17:0] j_tg;
	logic [4:0] j_rc;*/
	
	always @(posedge clk) begin
		rfp_ws <= 1'b0;
		rrap_ws <= 1'b0;
		reg_rs <= 28'b0;
		reg_ws <= 28'b0;
		
		mmu_cmd <= MMU_CMD_NOP;
		
		unique case(state)
			S_RESET: begin
				// TODO for loop and reset all registers instead of only the non-zero ones...
				case(rst_reg)
					REG_RFP: begin
						rfp_ws <= 1'b1;
						rfp_wr <= 32'hFFFF_FF80;
						rst_reg <= REG_RIP;
					end
					REG_RIP: begin
						reg_ws[REG_RIP] <= 1'b1;
						reg_wr[REG_RIP] <= 32'hFFA0_0000;
						rst_reg <= REG_RPL;
					end
					REG_RPL: begin
						reg_ws[REG_RPL] <= 1'b1;
						reg_wr[REG_RPL] <= 32'h1;
						rst_reg <= REG_RFP;
						state <= S_LOAD_REGS;
					end
				endcase
			end
			S_LOAD_REGS: begin
				// read all required registers for a single step (rip, rpdp, rpl)
				// one reg - one cycle
				case(pr_reg)
					REG_RIP: begin
						reg_rs[REG_RIP] <= 1'b1;
						pr_reg <= REG_RPDP;
					end
					REG_RPDP: begin
						reg_rs[REG_RPDP] <= 1'b1;
						pr_reg <= REG_RPL;
					end
					REG_RPL: begin
						reg_rs[REG_RPL] <= 1'b1;
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
				mmu_adr_in <= reg_rd[REG_RIP];
				
				target_state <= S_DECODE_EXECUTE;
				state <= S_WAIT_MMU_DONE;
			end
			S_DECODE_EXECUTE: begin
				i_data <= mmu_data_out;
				
				case(`I_OPSET)
					OPSET_CORE32: begin
						case(`I_OPCODE)
							CORE32_NOP: begin
							end

							CORE32_CPUID: begin
								case(mmu_data_out[31:30]) // ff
									CORE32_CPUID_CPUID: begin
										// TODO: CPUID
									end
									CORE32_CPUID_CPUFT: begin
										// TODO: CPUFT
									end
									default: begin
										// TODO: illegal sub-opcode
									end
								endcase
							end

							CORE32_LDW: begin
								case(mmu_data_out[31:24]) // ff
									CORE32_LDW_LDW: begin
										// TODO: LDW
									end
									CORE32_LDW_LDHZ: begin
										// TODO: LDHZ
									end
									CORE32_LDW_LDHS: begin
										// TODO: LDHS
									end
									CORE32_LDW_LDBZ: begin
										// TODO: LDBZ
									end
									CORE32_LDW_LDBS: begin
										// TODO: LDBS
									end
									default: begin
										// TODO: illegal sub-opcode
									end
								endcase
							end

							CORE32_LVI: begin
								// TODO: LVI
							end

							CORE32_LLI: begin
								case(mmu_data_out[31:30]) // ff
									CORE32_LLI_LLI: begin
										// TODO: LLI
									end
									CORE32_LLI_LUI: begin
										// TODO: LUI
									end
									default: begin
										// TODO: illegal sub-opcode
									end
								endcase
							end

							CORE32_STW: begin
								case(mmu_data_out[31:24]) // ff
									CORE32_STW_STW: begin
										// TODO: STW
									end
									CORE32_STW_STH: begin
										// TODO: STH
									end
									CORE32_STW_STB: begin
										// TODO: STB
									end
									default: begin
										// TODO: illegal sub-opcode
									end
								endcase
							end

							CORE32_MOV: begin
								// TODO: MOV
							end

							CORE32_JA: begin
								// TODO: JA
							end

							CORE32_JAE: begin
								case(mmu_data_out[31:24]) // ff
									CORE32_JAE_JAE: begin
										// TODO: JAE
									end
									CORE32_JAE_JANE: begin
										// TODO: JANE
									end
									CORE32_JAE_JALT: begin
										// TODO: JALT
									end
									CORE32_JAE_JAGE: begin
										// TODO: JAGE
									end
									default: begin
										// TODO: illegal sub-opcode
									end
								endcase
							end

							CORE32_JR: begin
								advance_ip <= 1'b0;
								reg_ws[REG_RIP] <= 1'b1;
								reg_wr[REG_RIP] <= reg_rd[REG_RIP] + $signed(`J_TG);
							end

							CORE32_JRE: begin
								// TODO: JRE
							end

							CORE32_JRNE: begin
								// TODO: JRNE
							end

							CORE32_JRLT: begin
								// TODO: JRLT
							end

							CORE32_JRGE: begin
								// TODO: JRGE
							end

							CORE32_CALLA: begin
								// TODO: CALLA
							end

							CORE32_CALLR: begin
								// TODO: CALLR
							end

							CORE32_RET: begin
								// TODO: RET
							end

							CORE32_CMPU: begin
								case(mmu_data_out[31:24]) // ff
									CORE32_CMPU_CMPU: begin
										// TODO: CMPU
									end
									CORE32_CMPU_CMPS: begin
										// TODO: CMPS
									end
									default: begin
										// TODO: illegal sub-opcode
									end
								endcase
							end

							CORE32_ADD: begin
								case(mmu_data_out[31:24]) // ff
									CORE32_ADD_ADD: begin
										// TODO: ADD
									end
									CORE32_ADD_SUB: begin
										// TODO: SUB
									end
									default: begin
										// TODO: illegal sub-opcode
									end
								endcase
							end

							CORE32_ADDI: begin
								// TODO: ADDI
							end

							CORE32_MUL: begin
								// TODO: MUL
							end

							CORE32_AND: begin
								case(mmu_data_out[31:24]) // ff
									CORE32_AND_AND: begin
										// TODO: AND
									end
									CORE32_AND_OR: begin
										// TODO: OR
									end
									CORE32_AND_XOR: begin
										// TODO: XOR
									end
									default: begin
										// TODO: illegal sub-opcode
									end
								endcase
							end

							CORE32_SHL: begin
								case(mmu_data_out[31:30]) // ff
									CORE32_SHL_SHL: begin
										// TODO: SHL
									end
									CORE32_SHL_SHR: begin
										// TODO: SHR
									end
									CORE32_SHL_SHSR: begin
										// TODO: SHSR
									end
									default: begin
										// TODO: illegal sub-opcode
									end
								endcase
							end

							CORE32_SHLI: begin
								case(mmu_data_out[31:30]) // ff
									CORE32_SHLI_SHLI: begin
										// TODO: SHLI
									end
									CORE32_SHLI_SHRI: begin
										// TODO: SHRI
									end
									CORE32_SHLI_SHSRI: begin
										// TODO: SHSRI
									end
									default: begin
										// TODO: illegal sub-opcode
									end
								endcase
							end

							CORE32_INT: begin
								// TODO: INT
							end

							CORE32_INTI: begin
								// TODO: INTI
							end

							CORE32_INTM: begin
								// TODO: INTM
							end

							CORE32_RETI: begin
								// TODO: RETI
							end

							CORE32_MCW: begin
								case(mmu_data_out[31:24]) // ff
									CORE32_MCW_MCW: begin
										// TODO: MCW
									end
									CORE32_MCW_MCH: begin
										// TODO: MCH
									end
									CORE32_MCW_MCB: begin
										// TODO: MCB
									end
									default: begin
										// TODO: illegal sub-opcode
									end
								endcase
							end

							default: begin
								// TODO: illegal opcode
							end
						endcase
					end
					default: begin
						// UDO
					end
				endcase
				
				state <= S_ADVANCE;
			end
			S_ADVANCE: begin
				if(advance_ip) begin
					// increment RIP
					reg_ws[REG_RIP] <= 1'b1;
					reg_wr[REG_RIP] <= reg_rd[REG_RIP] + 4;
				end
				
				advance_ip <= 1'b1; // reset for next step
				state <= S_LOAD_REGS;
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
				if(mmu_done) state <= target_state;
			end
			S_FREEZE: begin
				if(!dbg_freeze) state <= S_FETCH_RIP_V2P;
			end
		endcase
		
		// debug
		unique case(dbg_mode)
			DM_SHOW_RIP: begin
				dbg_num <= reg_rd[REG_RIP];
			end
			DM_SHOW_INST: begin
				dbg_num <= i_data;
			end
			DM_SHOW_REG: begin
				case(dbg_args)
					REG_RFP: dbg_num <= rfp_rd;
					REG_RRAP: dbg_num <= rrap_rd;
					REG_RZ: dbg_num <= rz_rd;
					REG_NULL: dbg_num <= 32'b0;
					default: dbg_num <= reg_rd[dbg_args];
				endcase
			end
			DM_SHOW_STAGE: begin
				//dbg_hex <= state;
				//dbg_led <= 8'b0;
				dbg_num <= state << 8;
			end
			default: ;
		endcase
	end

endmodule