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
	inout [31:0] io_rfp,
	inout [31:0] io_rrap,
	output [31:0] io_rz,
	
	/* local */
	/*inout [31:0] io_r0,
	inout [31:0] io_r1,
	inout [31:0] io_r2,
	inout [31:0] io_r3,
	inout [31:0] io_r4,
	inout [31:0] io_r5,
	inout [31:0] io_r6,
	inout [31:0] io_r7,
	inout [31:0] io_r8,
	inout [31:0] io_r9,
	inout [31:0] io_r10,
	inout [31:0] io_r11,
	inout [31:0] io_r12,
	inout [31:0] io_r13,
	inout [31:0] io_r14,
	inout [31:0] io_r15,
	
	inout [31:0] io_rip,
	inout [31:0] io_rtp,
	inout [31:0] io_rsp,
	inout [31:0] io_rlfp,
	inout [31:0] io_rpdp,
	inout [31:0] io_rcf,
	inout [31:0] io_rpl,*/
	
	input [31:0][31:0] i_reg,
	output [31:0][31:0] o_reg,
	
	input [31:0] i_r,
	input [31:0] i_w,
	
	/* sysram */
	output logic o_sysram_write,
	output logic [16:0] o_sysram_adr,
	output logic [31:0] o_sysram_data,
	input logic [31:0] i_sysram_data
);

	logic [31:0] rfp;
	assign io_rfp = i_w[REG_RFP] ? rfp : 32'hZZZZ_ZZZZ;
	
	logic [31:0] rrap;
	assign io_rrap = i_w[REG_RRAP] ? rrap : 32'hZZZZ_ZZZZ;
	
	assign rz = 32'b0;
	
	always @(posedge clk) begin
		if(i_w) rfp <= io_rfp;
		if(i_w) rrap <= io_rrap;
	end
	
	CpuRegister r_tgt;
	
	integer i;
	
	always @(negedge clk) begin
		if(r_tgt != REG_NULL) begin
			o_reg[r_tgt] <= i_sysram_data;
			r_tgt <= REG_NULL;
		end
		
		for(i = 0; i < 32; i = i + 1) begin
			if(i_r == (1 << i)) begin
				o_sysram_write <= 1'b0;
				o_sysram_adr <= rfp + i;
				r_tgt <= CpuRegister'(i);
			end
			
			if(i_w == (1 << i)) begin
				o_sysram_write <= 1'b1;
				o_sysram_adr <= rfp + i;
				o_sysram_data <= i_reg[i];
			end
		end
	
		/*case(1'b1)
			for(i = 0; i < 32; i = i + 1) begin
				i_r[i]: begin
					o_sysram_write <= 1'b0;
					o_sysram_adr <= rfp + i;
					r_tgt = i;
				end
				
				i_w[i]: begin
					o_sysram_write <= 1'b1;
					o_sysram_adr <= rfp + i;
					o_sysram_data <= i_reg[i];
				end
			end
			// ...
			// ...
		endcase*/
	end
endmodule