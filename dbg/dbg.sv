typedef enum bit[3:0] {
	DM_SHOW_RIP = 4'b0000,
	DM_SHOW_INST = 4'b0001
} DbgMode;

module dbg_interface(
	input clk,
	
	input [23:0] i_hex_dp,
	input [9:0] i_led_dp,
	
	output DbgMode o_mode,
	output reg o_freeze,
	output [5:0] o_args,
	
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

	assign LEDR = i_led_dp;
	
	assign b_num_0 = i_hex_dp[3:0];
	assign b_num_1 = i_hex_dp[7:4];
	assign b_num_2 = i_hex_dp[11:8];
	assign b_num_3 = i_hex_dp[15:12];
	assign b_num_4 = i_hex_dp[19:16];
	assign b_num_5 = i_hex_dp[23:20];
	
	assign o_mode = DbgMode'(SW[4:1]);
	assign o_args = SW[9:5];
	
	logic step_pulse1, step_pulse2, step_pulse3;
	logic step_pulse = 1'b0;
	assign step_pulse = step_pulse2 && !step_pulse3;

	always @(posedge clk) begin
		step_pulse1 <= !KEY[1];
		step_pulse2 <= step_pulse1;
		step_pulse3 <= step_pulse2;
		
		if(SW[0]) begin // frozen
			if(!KEY[0] || step_pulse) begin // KEY0 steps when frozen, KEY1 steps once with a pulse
				o_freeze <= 1'b0;
			end else begin
				o_freeze <= 1'b1;
			end
		end else begin
			o_freeze <= 1'b0;
		end
	end
	
	logic [3:0] b_num_0;
	Binary_To_7Segment m_7seg0(
		.i_Clk(clk),
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
		.i_Clk(clk),
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
		.i_Clk(clk),
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
		.i_Clk(clk),
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
		.i_Clk(clk),
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
		.i_Clk(clk),
		.i_Binary_Num(b_num_5),
		.o_Segment_A(HEX5[0]),
		.o_Segment_B(HEX5[1]),
		.o_Segment_C(HEX5[2]),
		.o_Segment_D(HEX5[3]),
		.o_Segment_E(HEX5[4]),
		.o_Segment_F(HEX5[5]),
		.o_Segment_G(HEX5[6])
	);

endmodule