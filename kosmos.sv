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
	input [1:0] KEY
);
	wire clk = CLK_50_1;

	logic [1:0] sdram_cmd;
	logic [31:0] sdram_adr;
	logic [7:0] sdram_data;
	logic [7:0] sdram_res;
	logic sdram_rdy;
	logic sdram_idle;

	is42s16320f_controller m_sdram(
		.clk(CLK_50_1),
		.i_cmd(sdram_cmd),
		.i_adr(sdram_adr),
		.i_data(sdram_data),
		.o_res(sdram_res),
		.o_rdy(sdram_rdy),
		.o_idle(sdram_idle),
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
	
	always @(posedge clk) begin
		LEDR[8] = sdram_idle;
		LEDR[9] = sdram_rdy;
		sdram_cmd = 2'b00;
		
		if(sdram_idle) begin
			if(SW[0]) begin
				// write to 0x0000 1234
				sdram_cmd = 2'b10;
				sdram_adr = 32'h00001234;
				sdram_data = 8'b10101010;
			end else if(SW[1]) begin
				// write to 0x0000 1234
				sdram_cmd = 2'b10;
				sdram_adr = 32'h00001234;
				sdram_data = 8'b11001100;
			end else if(SW[2]) begin
				// write to 0x0000 1234
				sdram_cmd = 2'b10;
				sdram_adr = 32'h00001234;
				sdram_data = 8'b00001111;
			end else if(!KEY[0]) begin
				// read from 0x0000 1234
				sdram_cmd = 2'b01;
				sdram_adr = 32'h00001234;
				sdram_data = 8'b0;
			end
		end
		
		if(sdram_rdy) begin
			LEDR[7:0] = sdram_res;
		end
		
		if(KEY[0]) begin
			LEDR[7:0] = 8'b0;
		end
	end

endmodule
