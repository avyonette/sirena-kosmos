// Quartus Prime Verilog Template
// Single port RAM with single read/write address 

import mem::*;

module sysram_controller
#(parameter DATA_WIDTH=32 /*8*/, parameter ADDR_WIDTH=15 /*17*/)
(
	input clk,
	input MemCtrlCmd i_cmd,
	input [(17):0] i_adr,
	input [(DATA_WIDTH-1):0] i_data,
	output [(DATA_WIDTH-1):0] o_data
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

	// Variable to hold the registered read address
	//reg [ADDR_WIDTH-1:0] addr_reg;

	always @ (posedge clk) begin
		/*word_adr = i_adr >> 2;
		half_word_offset = i_adr & 'b10;
		byte_offset = i_adr & 'b11;*/
		
		unique case(1'b1)
			i_cmd[MC_CMD_READ8_I]: o_data <= ram[i_adr >> 2] >> (i_adr & 'b11);
			i_cmd[MC_CMD_READ16_I]: o_data <= ram[i_adr >> 2] >> (i_adr & 'b10);
			i_cmd[MC_CMD_READ32_I]: o_data <= ram[i_adr >> 2];
			i_cmd[MC_CMD_WRITE8_I]: ram[i_adr >> 2] <= i_data << (i_adr & 'b11);
			i_cmd[MC_CMD_WRITE16_I]: ram[i_adr >> 2] <= i_data << (i_adr & 'b10);
			i_cmd[MC_CMD_WRITE32_I]: ram[i_adr >> 2] <= i_data;
		endcase
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	//assign o_data = ram[addr_reg];

endmodule
