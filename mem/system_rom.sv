// Quartus Prime Verilog Template
// Single Port ROM

module sysrom_controller
#(parameter DATA_WIDTH=32, parameter ADDR_WIDTH=14)
(
	input clk, 
	input [(ADDR_WIDTH-1):0] i_adr,
	output reg [(DATA_WIDTH-1):0] o_data
);

	// Declare the ROM variable
	reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];

	// Initialize the ROM with $readmemb.  Put the memory contents
	// in the file single_port_rom_init.txt.  Without this file,
	// this design will not compile.

	// See Verilog LRM 1364-2001 Section 17.2.8 for details on the
	// format of this file, or see the "Using $readmemb and $readmemh"
	// template later in this section.

	initial begin
		$readmemh("blip.rom", rom);
	end

	always @(negedge clk) begin
		o_data <= rom[i_adr];
	end

endmodule
