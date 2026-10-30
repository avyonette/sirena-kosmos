module sysram_controller
#(parameter DATA_WIDTH=32 /*8*/, parameter ADDR_WIDTH=15 /*17*/)
(
	input clk,
	input i_wA, i_wB,
	input [(ADDR_WIDTH-1):0] i_adrA, i_adrB,
	input [(DATA_WIDTH-1):0] i_dataA, i_dataB,
	output [(DATA_WIDTH-1):0] o_dataA, o_dataB
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
	
	// port A
	always @(negedge clk) begin // negedge to execute right after MMU's cycle and before its next cycle
		if(i_wA) ram[i_adrA] <= i_dataA;
		o_dataA <= ram[i_adrA];
	end
	
	// port B
	always @(negedge clk) begin
		if(i_wB) ram[i_adrB] <= i_dataB;
		o_dataB <= ram[i_adrB];
	end
	
endmodule
