module control_unit(
	input clk,
	output o_sdram_cmd,
	output o_sdram_adr,
	output o_sdram_data,
	input i_sdram_res,
	input i_sdram_rdy
);
	

	parameter
		S_FETCH = 3'b001,
		S_DECODE = 3'b010,
		S_EXECUTE = 3'b100;
	
	reg [2:0] state = S_FETCH;
	
	always @(posedge clk) begin
		case(1'b1)
			state[0]: begin // FETCH
			end
			state[1]: begin // DECODE
			end
			state[2]: begin // EXECUTE
			end
		endcase
	end

endmodule