import mem::*;
import cpu::*;

module kosmos(
	input CLK_50_1,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	inout [15:0] DRAM_DQ,
	output DRAM_LDQM,
	output DRAM_RAS_N,
	output DRAM_UDQM,
	output DRAM_WE_N,
	output reg [9:0] LEDR,
	input [9:0] SW,
	input [1:0] KEY,
	output reg [7:0] HEX0,
	output reg [7:0] HEX1,
	output reg [7:0] HEX2,
	output reg [7:0] HEX3,
	output reg [7:0] HEX4,
	output reg [7:0] HEX5
);
	wire clk = CLK_50_1;

	MemCtrlCmd sdram_cmd = MC_CMD_NOP;
	logic [31:0] sdram_adr;
	logic [31:0] sdram_data_in;
	logic [31:0] sdram_data_out;
	logic sdram_rdy = 1'b0;
	logic sdram_done = 1'b0;

	is42s16320f_controller m_sdram(
		.clk(CLK_50_1),
		.i_cmd(sdram_cmd),
		.i_adr(sdram_adr),
		.i_data(sdram_data_in),
		.o_data(sdram_data_out),
		.o_rdy(sdram_rdy),
		.o_done(sdram_done),
		.o_clk(DRAM_CLK),
		.o_cke(DRAM_CKE),
		.o_cs(DRAM_CS_N),
		.o_ras(DRAM_RAS_N),
		.o_cas(DRAM_CAS_N),
		.o_we(DRAM_WE_N),
		.o_a(DRAM_ADDR),
		.o_ba(DRAM_BA),
		.o_dqml(DRAM_LDQM),
		.o_dqmh(DRAM_UDQM),
		.io_dq(DRAM_DQ)
	);
	
	//MemCtrlCmd sysram_cmd = MC_CMD_NOP;
	logic sysram_write = 1'b0;
	logic [17:0] sysram_adr;
	logic [31:0] sysram_data_in;
	logic [31:0] sysram_data_out;
	
	sysram_controller m_sysram(
		.clk(CLK_50_1),
		.i_w(sysram_write),
		.i_adr(sysram_adr),
		.i_data(sysram_data_in),
		.o_data(sysram_data_out)
	);
	
	MmuCmd mmu_cmd = MMU_CMD_NOP;
	logic [31:0] mmu_adr_in;
	logic [31:0] mmu_data_in;
	logic [31:0] mmu_data_out = 32'hDEAD_C0DE;
	logic [31:0] mmu_padr_out;
	logic mmu_rdy = 1'b0;
	logic mmu_done = 1'b0;
	
	cpu_mmu m_mmu(
		.clk(CLK_50_1),
		.i_cmd(mmu_cmd),
		.i_adr(mmu_adr_in),
		.i_data(mmu_data_in),
		.o_data(mmu_data_out),
		.o_padr(mmu_padr_out),
		.o_rdy(mmu_rdy),
		.o_done(mmu_done),
		
		.o_sdram_cmd(sdram_cmd),
		.o_sdram_adr(sdram_adr),
		.o_sdram_data(sdram_data_in),
		.i_sdram_data(sdram_data_out),
		.i_sdram_rdy(sdram_rdy),
		.i_sdram_done(sdram_done),
		
		.o_sysram_write(sysram_write),
		.o_sysram_adr(sysram_adr),
		.o_sysram_data(sysram_data_in),
		.i_sysram_data(sysram_data_out)
		
		//.i_leds(LEDR[7:0])
	);
	
	logic [3:0] b_num_0;
	Binary_To_7Segment m_7seg0(
		.i_Clk(CLK_50_1),
		.i_Binary_Num(b_num_0),
		.o_Segment_A(HEX0[0]),
		.o_Segment_B(HEX0[1]),
		.o_Segment_C(HEX0[2]),
		.o_Segment_D(HEX0[3]),
		.o_Segment_E(HEX0[4]),
		.o_Segment_F(HEX0[5]),
		.o_Segment_G(HEX0[6])
	);
	
	logic [3:0] b_num_1;
	Binary_To_7Segment m_7seg1(
		.i_Clk(CLK_50_1),
		.i_Binary_Num(b_num_1),
		.o_Segment_A(HEX1[0]),
		.o_Segment_B(HEX1[1]),
		.o_Segment_C(HEX1[2]),
		.o_Segment_D(HEX1[3]),
		.o_Segment_E(HEX1[4]),
		.o_Segment_F(HEX1[5]),
		.o_Segment_G(HEX1[6])
	);
	
	logic [3:0] b_num_2;
	Binary_To_7Segment m_7seg2(
		.i_Clk(CLK_50_1),
		.i_Binary_Num(b_num_2),
		.o_Segment_A(HEX2[0]),
		.o_Segment_B(HEX2[1]),
		.o_Segment_C(HEX2[2]),
		.o_Segment_D(HEX2[3]),
		.o_Segment_E(HEX2[4]),
		.o_Segment_F(HEX2[5]),
		.o_Segment_G(HEX2[6])
	);
	
	logic [3:0] b_num_3;
	Binary_To_7Segment m_7seg3(
		.i_Clk(CLK_50_1),
		.i_Binary_Num(b_num_3),
		.o_Segment_A(HEX3[0]),
		.o_Segment_B(HEX3[1]),
		.o_Segment_C(HEX3[2]),
		.o_Segment_D(HEX3[3]),
		.o_Segment_E(HEX3[4]),
		.o_Segment_F(HEX3[5]),
		.o_Segment_G(HEX3[6])
	);
	
	logic [3:0] b_num_4;
	Binary_To_7Segment m_7seg4(
		.i_Clk(CLK_50_1),
		.i_Binary_Num(b_num_4),
		.o_Segment_A(HEX4[0]),
		.o_Segment_B(HEX4[1]),
		.o_Segment_C(HEX4[2]),
		.o_Segment_D(HEX4[3]),
		.o_Segment_E(HEX4[4]),
		.o_Segment_F(HEX4[5]),
		.o_Segment_G(HEX4[6])
	);
	
	logic [3:0] b_num_5;
	Binary_To_7Segment m_7seg5(
		.i_Clk(CLK_50_1),
		.i_Binary_Num(b_num_5),
		.o_Segment_A(HEX5[0]),
		.o_Segment_B(HEX5[1]),
		.o_Segment_C(HEX5[2]),
		.o_Segment_D(HEX5[3]),
		.o_Segment_E(HEX5[4]),
		.o_Segment_F(HEX5[5]),
		.o_Segment_G(HEX5[6])
	);
	
	task display_7seg;
		input [23:0] num;
		
		begin
			b_num_0 = num[3:0];
			b_num_1 = num[7:4];
			b_num_2 = num[11:8];
			b_num_3 = num[15:12];
			b_num_4 = num[19:16];
			b_num_5 = num[23:20];
		end
	endtask
	
	always @(posedge clk) begin
		LEDR[8] = mmu_done;
		LEDR[9] = mmu_rdy;
		mmu_cmd = MMU_CMD_NOP;
		
		if(mmu_rdy) begin
			if(SW[0]) begin
				// write half_word to 0x0021 AB12
				mmu_cmd = MMU_CMD_MWRITE16;
				mmu_data_in = 16'h1357;
				mmu_adr_in = 32'h0021_AB12;
			end else if(SW[1]) begin
				// write half-word to 0xFFFF 1234
				mmu_cmd = MMU_CMD_MWRITE16;
				mmu_data_in = 16'hDEAD;
				mmu_adr_in = 32'hFFFF_1234;
			end else if(SW[2]) begin
				// write word to 0x0123 4560
				mmu_cmd = MMU_CMD_MWRITE32;
				mmu_data_in = 32'hBEEF_9876;
				mmu_adr_in = 32'h0123_4560;
			end else if(SW[3]) begin
				// write word to 0xFFFE 1000
				mmu_cmd = MMU_CMD_MWRITE32;
				mmu_data_in = 32'hCAFE_BABE;
				mmu_adr_in = 32'hFFFE_1000;
			end else if(SW[4]) begin
				// read half-word from 0x0021 AB12
				mmu_cmd = MMU_CMD_MREAD16;
				mmu_adr_in = 32'h0021_AB12;
			end else if(SW[5]) begin
				// read half-word from 0xFFFF 1234
				mmu_cmd = MMU_CMD_MREAD16;
				mmu_adr_in = 32'hFFFF_1234;
			end else if(SW[6]) begin
				// read word from 0x0123 4560
				mmu_cmd = MMU_CMD_MREAD32;
				mmu_adr_in = 32'h0123_4560;
			end else if(SW[7]) begin
				// read half-word from 0x0123 4562
				mmu_cmd = MMU_CMD_MREAD16;
				mmu_adr_in = 32'h0123_4562;
			end else if(SW[8]) begin
				// read half-word from 0xFFFF 1000
				mmu_cmd = MMU_CMD_MREAD16;
				mmu_adr_in = 32'hFFFF_1000;
			end else if(SW[9]) begin
				// read half-word from 0xFFFF 1002
				mmu_cmd = MMU_CMD_MREAD16;
				mmu_adr_in = 32'hFFFF_1002;
			end
		end
		
		if(!SW[9:4]) begin
			display_7seg(24'b0);
			LEDR[7:0] = 8'b0;
		end else begin
			//display_7seg(24'hABCDEF);
			display_7seg(mmu_data_out[31:8]);
			LEDR[7:0] = mmu_data_out[7:0];
		end
		
		/*if(mmu_cmd == 0) begin
			LEDR[7] = 1'b1;
		end else begin
			LEDR[7] = 1'b0;
		end*/
	end

endmodule
