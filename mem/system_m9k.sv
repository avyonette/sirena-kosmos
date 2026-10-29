// Quartus Prime Verilog Template
// Single port RAM with single read/write address 

import mem::*;

module sysram_controller
#(parameter DATA_WIDTH=32 /*8*/, parameter ADDR_WIDTH=15 /*17*/)
(
	input clk,
	input i_w,
	input [(ADDR_WIDTH-1):0] i_adr,
	input [(DATA_WIDTH-1):0] i_data,
	output [(DATA_WIDTH-1):0] o_data
);

	// Declare the RAM variable
	
	logic [(DATA_WIDTH-1):0] r_data;

	// Variable to hold the registered read address
	reg [ADDR_WIDTH-1:0] addr_reg;
	
	always @(negedge clk) begin // negedge to execute right after MMU's cycle and before its next cycle
		if(i_w) begin
			ram[i_adr] <= i_data;
		end
		
		o_data <= ram[i_adr];
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	//assign o_data = ram[i_adr];

endmodule
