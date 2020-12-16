
/*
Author: Semih GENC
Description : Median Filter core, full 3x3, partial 5x5, 7x7 ....;
Version : 1.00
*/


module median_filter_core #(
    parameter SIZE = 3,
    parameter DW = 14,
	parameter PAD_OPT = "zeros"
)(

    input clk,
    input rstb,

	input [15:0] iw,
	input [15:0] ih,


	input [15:0] sent_line_cntr,
	input [15:0] sent_pix_cntr,

    input [SIZE*DW-1:0] stack_data,
	input valid,

    output [DW-1:0] dout,
    output dout_valid



    );

	// This module selects the proper inputs that will be given to median filter sorting network whose job is to find the median.
	// The complexity comes from the necessity that filtering should be performed correctly on the edges.

	localparam REGISTER_LATENCY = SIZE/2 + 1;
	// Counter delays; +2 consists of one clock cycle for middle elements
	localparam SORTING_LATENCY = 5;
    localparam CORE_LATENCY = REGISTER_LATENCY + SORTING_LATENCY;

	localparam INVALID_FILL = (PAD_OPT == "ones") ? 1'b1 : 1'b0;


	// SIZE x SIZE register mat (window).
	// Formed by concatenation of lines and pixels
    reg [SIZE*SIZE*DW-1:0]  input_mat;
    wire [SIZE*SIZE*DW-1:0]  formed_mat;


	// Median output
	wire [DW-1:0] 			median;


	// Sampling
	wire [15:0] 			sent_line_cntr_dly;
	wire [15:0] 			sent_pix_cntr_dly;


	// Find invalid rows and cols depending on the window placement location
	wire [SIZE-1:0] row_invalid;
	wire [SIZE-1:0] col_invalid;


    // Output valid signal with latency
	add_latency #(.DW(1), .LAT(CORE_LATENCY)) DLY_VALID (.clk(clk), .din(valid), .dout(dout_valid));
	add_latency #(.DW(16), .LAT(REGISTER_LATENCY)) SENT_LINE_CNTR_DLY (.clk(clk), .din(sent_line_cntr), .dout(sent_line_cntr_dly));
	add_latency #(.DW(16), .LAT(REGISTER_LATENCY)) SENT_PIX_CNTR_DLY (.clk(clk), .din(sent_pix_cntr), .dout(sent_pix_cntr_dly));


	// Output data
	assign dout = median;


	// Left-shift the matrix by one column and insert the new stack data from right
	always @(posedge clk or negedge rstb) begin
		if(!rstb) begin
			input_mat <= 0;
		end else begin
			input_mat <= {input_mat[(SIZE-1)*SIZE*DW-1 : 0*SIZE*DW], stack_data};
		end
	end


	// Parse input mat into 2D elements array "elems_in"
	// Form a 2D array "elems_out" by taking invalid locations into account
	// Form a concatenated stack "stack_out"
	wire [DW-1:0] elems_in[0:SIZE-1][0:SIZE-1];
	wire [DW-1:0] elems_out[0:SIZE-1][0:SIZE-1];
	genvar m;
	genvar n;
	generate
		for(m=0; m<SIZE; m=m+1) begin : MAT_PARSING_C
			for(n=0; n<SIZE; n=n+1) begin : MAT_PARSING_R
				assign elems_in[n][SIZE-1-m] = input_mat[m*SIZE*DW + (SIZE-1-n)*DW +: DW];
				assign elems_out[n][m] = (row_invalid[n] || col_invalid[m]) ? {DW{INVALID_FILL}} : elems_in[n][m];
				assign formed_mat[m*SIZE*DW + (SIZE-1-n)*DW +: DW] = elems_out[n][SIZE-1-m];
			end
		end
	endgenerate


	assign row_invalid[SIZE/2] = 1'b0;
	assign col_invalid[SIZE/2] = 1'b0;
	genvar p;
	generate
		for(p=0; p<SIZE; p=p+1) begin : MAT_PARSING
			if(p < (SIZE/2)) begin
				assign row_invalid[p] = (p < (SIZE/2 - sent_line_cntr_dly)) && (sent_line_cntr_dly < SIZE/2);
				assign col_invalid[p] = (p < (SIZE/2 - sent_pix_cntr_dly)) && (sent_pix_cntr_dly < SIZE/2);
			end
			if(p > (SIZE/2)) begin
				assign row_invalid[p] = (p >= (ih + SIZE/2 - sent_line_cntr_dly)) && (sent_line_cntr_dly >= (ih - SIZE/2));
				assign col_invalid[p] = (p >= (iw + SIZE/2 - sent_pix_cntr_dly)) && (sent_pix_cntr_dly >= (iw - SIZE/2));
			end
		end
	endgenerate


    // Sorting network
	// Give the matrix (SIZE x SIZE) to sorting network
    sort_NxN #(SIZE, DW)
    SORTNxN(
        .clk(clk),
        .rstb(rstb),

        .valid(valid),
        .data(formed_mat),
        .median(median)
    );




endmodule
