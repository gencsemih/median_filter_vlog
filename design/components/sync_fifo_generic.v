

/*
Author: Semih GENC
Description : Vendor-independent synchronous FIFO
Version : 1.00
*/


module sync_fifo_generic #(
	parameter WIDTH = 8,
	parameter DEPTH = 2048,
	parameter [0:0] REGOUT = 0

)(

	input clk,
	input rst,

	output 						full,
	output 						empty,
	//output reg [$clog2(DEPTH):0] dcnt,

	input [WIDTH-1:0] 			din,
	input 						wr_en,

	output [WIDTH-1:0] 			dout,
	input 						rd_en


);

	localparam CLOG2DEPTH = $clog2(DEPTH);

	reg [WIDTH-1:0] fifo_reg [0:DEPTH-1];
	reg [CLOG2DEPTH-1:0] wr_ptr;
	reg [CLOG2DEPTH-1:0] rd_ptr;
	reg [$clog2(DEPTH):0] dcnt;


	assign full = (dcnt == DEPTH);
	assign empty = (dcnt == 0);

	//------------------------
	//-- FIFO write pointer --
	//------------------------
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			wr_ptr <= 0;
		end else begin
			if(wr_en) begin
				if (wr_ptr == DEPTH) begin
	  	        	wr_ptr <= 0;
	  	    	end else begin
	  	        	wr_ptr <= wr_ptr + 1;
				end
			end
		end
	end


	//-----------------------
	//-- FIFO read pointer --
	//-----------------------
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			rd_ptr <= 0;
		end else begin
			if(rd_en) begin
				if (rd_ptr == DEPTH) begin
					rd_ptr <= 0;
				end else begin
					rd_ptr <= rd_ptr + 1;
				end
			end
		end
	end


	//-----------------------------------
	//-- FIFO dcnt up/down counter --
	//-----------------------------------
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			dcnt <= 0;
		end else begin
			if(wr_en && !rd_en) begin
				dcnt <= dcnt + 1;
			end else if(!wr_en && rd_en) begin
				dcnt <= dcnt - 1;
			end
		end
	end


	//------------------------
	//-- FIFO memory writes --
	//------------------------
	integer i;
	always @(posedge clk or posedge rst) begin
		if(rst) begin
			for(i=0;i<DEPTH;i=i+1) begin
				fifo_reg[i] <= 0;
			end
		end else begin
			if(wr_en) begin
				fifo_reg [wr_ptr] <= din;
			end
		end
	end


	//-----------------------
	//-- FIFO memory reads --
	//-----------------------
	generate
		if(!REGOUT) begin
			assign dout = fifo_reg[rd_ptr];
		end else begin
			reg dout_reg;
			assign dout = dout_reg;
			always @(posedge clk) begin
				dout_reg <= fifo_reg[rd_ptr];
			end
		end
	endgenerate


endmodule
