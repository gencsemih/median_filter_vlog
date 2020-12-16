

/*
Author: Semih GENC
Description : Synchronous FIFO with source selection
Version : 1.00
*/


module sync_fifo #(
	parameter WIDTH = 8,
	parameter DEPTH = 2048,
	parameter USE_VENDOR = 0

)(

	input clk,
	input rst,

	output full,
	output empty,
	//output [$clog2(DEPTH):0] dcnt,

	input [WIDTH-1:0] din,
	input wr_en,

	output [WIDTH-1:0] dout,
	input rd_en


);

generate
	if(USE_VENDOR) begin : GEN_VENDOR_FIFO

		sync_fifo_vendor #(.WIDTH(WIDTH), .DEPTH(DEPTH), .REGOUT(0))
		SYNC_FIFO (

			.clk(clk),
			.rst(rst),

			.full(full),
			.empty(empty),
			//.dcnt(dcnt),

			.din(din),
			.wr_en(wr_en),

			.dout(dout),
			.rd_en(rd_en)
		);

	end else begin : GEN_GENERIC_FIFO

		sync_fifo_generic #(.WIDTH(WIDTH), .DEPTH(DEPTH), .REGOUT(0))
		SYNC_FIFO (

			.clk(clk),
			.rst(rst),

			.full(full),
			.empty(empty),
			//.dcnt(dcnt),

			.din(din),
			.wr_en(wr_en),

			.dout(dout),
			.rd_en(rd_en)
		);

	end
endgenerate



endmodule
