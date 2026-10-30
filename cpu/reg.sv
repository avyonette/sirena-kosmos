typedef enum bit[4:0] {
	REG_R0 = 5'h01,
	REG_R1 = 5'h02,
	REG_R2 = 5'h03,
	REG_R3 = 5'h04,
	REG_R4 = 5'h05,
	REG_R5 = 5'h06,
	REG_R6 = 5'h07,
	REG_R7 = 5'h08,
	REG_R8 = 5'h09,
	REG_R9 = 5'h0A,
	REG_R10 = 5'h0B,
	REG_R11 = 5'h0C,
	REG_R12 = 5'h0D,
	REG_R13 = 5'h0E,
	REG_R14 = 5'h0F,
	REG_R15 = 5'h10,
	REG_RIP = 5'h11,
	REG_RTP = 5'h12,
	REG_RSP = 5'h13,
	REG_RLFP = 5'h14,
	REG_RPDP = 5'h15,
	REG_RCF = 5'h16,
	REG_RPL = 5'h17,
	REG_RFI0 = 5'h18,
	REG_RFI1 = 5'h19,
	REG_RFO0 = 5'h1A,
	REG_RFO1 = 5'h1B,
	REG_NULL = 5'h1C,
	REG_RFP = 5'h1D,
	REG_RRAP = 5'h1E,
	REG_RZ = 5'h1F
} CpuRegister;

module cpu_reg(
	input clk,
	
	/* global */
	//inout [31:0] io_rfp,
	//inout [31:0] io_rrap,
	//output [31:0] io_rz,
	
	input [31:0] i_rfp,
	output [31:0] o_rfp,
	input i_w_rfp,
	
	input [31:0] i_rrap,
	output [31:0] o_rrap,
	input i_w_rrap,
	
	output [31:0] o_rz,
	
	/* local */
	input [27 /* 28 local registers */:0][31:0] i_reg,
	output [27:0][31:0] o_reg,
	
	input [27:0] i_r,
	input [27:0] i_w,
	
	/* sysram */
	output logic o_sysram_write,
	output logic [14:0] o_sysram_adr,
	output logic [31:0] o_sysram_data,
	input logic [31:0] i_sysram_data
);

	logic [31:0] rfp;
	assign o_rfp = rfp;
	//assign io_rfp = i_w[REG_RFP] ? rfp : 32'hZZZZ_ZZZZ;
	//assign o_reg[REG_RFP] = rfp;
	
	logic [31:0] rrap;
	assign o_rrap = rrap;
	//assign io_rrap = i_w[REG_RRAP] ? rrap : 32'hZZZZ_ZZZZ;
	//assign o_reg[REG_RRAP] = rrap;
	
	assign o_rz = 32'b0;
	//assign io_rz = 32'b0;
	//assign o_reg[REG_RZ] = 32'b0;
	
	always @(negedge clk) begin
		if(i_w_rfp) rfp <= i_rfp;
		if(i_w_rrap) rrap <= i_rrap;
	end
	
	CpuRegister r_tgt;
	
	integer i;
	
	always @(negedge clk) begin
		if(r_tgt != REG_NULL) begin
			o_reg[r_tgt] <= i_sysram_data;
			r_tgt <= REG_NULL;
		end
		
		for(i = 0; i < 28 /* 28 local registers */; i = i + 1) begin
			if(i_r[i]) begin
				o_sysram_write <= 1'b0;
				o_sysram_adr <= (rfp - SYS_RAM_BASE) + i; // sysram expects a word-aligned address; no need to do (i * 4)
				r_tgt <= CpuRegister'(i);
			end
			
			if(i_w[i]) begin
				o_sysram_write <= 1'b1;
				o_sysram_adr <= (rfp - SYS_RAM_BASE) + i;
				o_sysram_data <= i_reg[i];
			end
		end
	end
endmodule