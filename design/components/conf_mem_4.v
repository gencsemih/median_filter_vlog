
/*
Author: Semih GENC
Description : Config memory block to be used in video IPs;
Version : 1.00
*/

module conf_mem_4 #(
	parameter DW_MA = 8,
	parameter DW_MD = 16,
	parameter NUM_OF_REG = 4,

	parameter [DW_MD-1:0] DEF_M0 = 16'h0000,
	parameter [DW_MD-1:0] DEF_M1 = 16'h0000,
	parameter [DW_MD-1:0] DEF_M2 = 16'h0000,
	parameter [DW_MD-1:0] DEF_M3 = 16'h0000,

	parameter [NUM_OF_REG-1:0] DIR_M = 0
) (

	input clk,
	input rstb,

	input [DW_MA-1:0] 	adr,
	input [DW_MD-1:0] 	wdt,
	output reg [DW_MD-1:0] 	rdt,
	output 				val,


	inout [DW_MD-1:0] m0,
	inout [DW_MD-1:0] m1,
	inout [DW_MD-1:0] m2,
	inout [DW_MD-1:0] m3
);


// Memory variable declaration
reg [DW_MD-1:0] mem [0:NUM_OF_REG-1];


assign m0 = mem[0];
assign m1 = mem[1];
assign m2 = mem[2];
assign m3 = mem[3];

always @(posedge clk or negedge rstb) begin
	if(!rstb) begin
		mem[ 0] <= DEF_M0 ;
		mem[ 1] <= DEF_M1 ;
		mem[ 2] <= DEF_M2 ;
		mem[ 3] <= DEF_M3 ;
	end else begin
		// Write logic
		if(val && !DIR_M[adr])
			mem[adr] <= wdt;

		// Read logic
		if(!DIR_M[adr])
			rdt <= mem[adr];
		else
			case(adr)
				0	: rdt <= m0;
				1	: rdt <= m1;
				2	: rdt <= m2;
				3	: rdt <= m3;
			endcase
	end
end


endmodule
