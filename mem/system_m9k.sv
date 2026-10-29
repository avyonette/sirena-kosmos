// Quartus Prime Verilog Template
// Single port RAM with single read/write address 

import mem::*;

module sysram_controller
#(parameter DATA_WIDTH=32 /*8*/, parameter ADDR_WIDTH=15 /*17*/)
(
	input clk,
	//input MemCtrlCmd i_cmd,
	//input i_r,
	input i_w,
	input [(ADDR_WIDTH-1):0] i_adr,
	//input [17:0] i_w_adr,
	input [(DATA_WIDTH-1):0] i_data,
	output [(DATA_WIDTH-1):0] o_data
);

	// Declare the RAM variable
	logic [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
	
	//logic [(ADDR_WIDTH-1):0] r_adr;
	//logic [(ADDR_WIDTH-1):0] w_adr;
	
	//assign r_adr = i_r_adr >> 2;
	//assign w_adr = i_w_adr >> 2;
	
	logic [(DATA_WIDTH-1):0] r_data;

	// Variable to hold the registered read address
	reg [ADDR_WIDTH-1:0] addr_reg;
	
	//always @(negedge clk) begin
	//	r_data = ram[i_adr >> 2];
	//end
	
	always @(negedge clk) begin // negedge to execute right after MMU's cycle and before its next cycle
		/*word_adr = i_adr >> 2;
		half_word_offset = i_adr & 'b10;
		byte_offset = i_adr & 'b11;*/
		
		/*unique case(1'b1)
			i_cmd[MC_CMD_READ8_I]: o_data <= ram[i_adr >> 2] >> (i_adr & 'b11);
			i_cmd[MC_CMD_READ16_I]: o_data <= ram[i_adr >> 2] >> (i_adr & 'b10);
			i_cmd[MC_CMD_READ32_I]: o_data <= ram[i_adr >> 2];
			i_cmd[MC_CMD_WRITE8_I]: ram[i_adr >> 2] <= i_data << (i_adr & 'b11);
			i_cmd[MC_CMD_WRITE16_I]: ram[i_adr >> 2] <= i_data << (i_adr & 'b10);
			i_cmd[MC_CMD_WRITE32_I]: ram[i_adr >> 2] <= i_data;
		endcase*/
		
		/*unique case(1'b1)
			i_cmd[MC_CMD_READ8_I]: o_data <= {24'b0, r_data >> ((i_r_adr & 'b11) * 'd8)};
			i_cmd[MC_CMD_READ16_I]: o_data <= {16'b0, r_data >> ((i_r_adr & 'b10) * 'd8)};
			i_cmd[MC_CMD_READ32_I]: o_data <= r_data;
			i_cmd[MC_CMD_WRITE8_I]: ram[w_adr] <= i_data << ((i_w_adr & 'b11) * 'd8);
			i_cmd[MC_CMD_WRITE16_I]: ram[w_adr] <= i_data << ((i_w_adr & 'b10) * 'd8);
			i_cmd[MC_CMD_WRITE32_I]: ram[w_adr] <= i_data;
		endcase*/
		
		if(i_w) begin
			ram[i_adr] <= i_data;
		end
		
		o_data <= ram[i_adr];
		//addr_reg <= i_adr;
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	//assign o_data = ram[i_adr];

endmodule
