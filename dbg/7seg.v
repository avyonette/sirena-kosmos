///////////////////////////////////////////////////////////////////////////////
// File downloaded from http://www.nandland.com
///////////////////////////////////////////////////////////////////////////////
// This file converts an input binary number into an output which can get sent
// to a 7-Segment LED.  7-Segment LEDs have the ability to display all decimal
// numbers 0-9 as well as hex digits A, B, C, D, E and F.  The input to this
// module is a 4-bit binary number.  This module will properly drive the
// individual segments of a 7-Segment LED in order to display the digit.
// Hex encoding table can be viewed at:
// http://en.wikipedia.org/wiki/Seven-segment_display
///////////////////////////////////////////////////////////////////////////////

module Binary_To_7Segment
  (
   input       i_Clk,
   input [3:0] i_Binary_Num,
   output      o_Segment_A,
   output      o_Segment_B,
   output      o_Segment_C,
   output      o_Segment_D,
   output      o_Segment_E,
   output      o_Segment_F,
   output      o_Segment_G
   );

  reg [6:0]    r_Hex_Encoding = 7'h00;

  // Purpose: Creates a case statement for all possible input binary numbers.
  // Drives r_Hex_Encoding appropriately for each input combination.
  always @(posedge i_Clk)
    begin
      case (i_Binary_Num)
		4'h1: r_Hex_Encoding = 7'b1111001;	// ---t----
		4'h2: r_Hex_Encoding = 7'b0100100; 	// |	  |
		4'h3: r_Hex_Encoding = 7'b0110000; 	// lt	 rt
		4'h4: r_Hex_Encoding = 7'b0011001; 	// |	  |
		4'h5: r_Hex_Encoding = 7'b0010010; 	// ---m----
		4'h6: r_Hex_Encoding = 7'b0000010; 	// |	  |
		4'h7: r_Hex_Encoding = 7'b1111000; 	// lb	 rb
		4'h8: r_Hex_Encoding = 7'b0000000; 	// |	  |
		4'h9: r_Hex_Encoding = 7'b0011000; 	// ---b----
		4'ha: r_Hex_Encoding = 7'b0001000;
		4'hb: r_Hex_Encoding = 7'b0000011;
		4'hc: r_Hex_Encoding = 7'b1000110;
		4'hd: r_Hex_Encoding = 7'b0100001;
		4'he: r_Hex_Encoding = 7'b0000110;
		4'hf: r_Hex_Encoding = 7'b0001110;
		4'h0: r_Hex_Encoding = 7'b1000000;
      endcase
    end // always @ (posedge i_Clk)

  // r_Hex_Encoding[7] is unused
  assign o_Segment_A = r_Hex_Encoding[0];
  assign o_Segment_B = r_Hex_Encoding[1];
  assign o_Segment_C = r_Hex_Encoding[2];
  assign o_Segment_D = r_Hex_Encoding[3];
  assign o_Segment_E = r_Hex_Encoding[4];
  assign o_Segment_F = r_Hex_Encoding[5];
  assign o_Segment_G = r_Hex_Encoding[6];

endmodule // Binary_To_7Segment
