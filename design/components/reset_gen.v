

/*
Author: Semih GENC
Description : Generation of specified length reset pulse
Version : 1.00
*/


module reset_gen #(
	parameter LEN = 4,
	parameter [0:0] INV = 0
)(

	input clk,
	input rstb,

	input 	ext_reset,
	output 	gen_reset


);



reg [LEN-1:0] shift_reg;
assign gen_reset = shift_reg[LEN-1];

always @(posedge clk or negedge rstb) begin
	if(!rstb) begin
		shift_reg <= {LEN{!INV}};
	end else begin
		if(ext_reset)	shift_reg <= {LEN{!INV}};
		else			shift_reg <= {shift_reg[LEN-2:0], INV};
	end
end



endmodule
