

/*
Author: Semih GENC
Description : Converts VBUS interface to parallel video bus
Version : 1.00
*/


module vbus_2_parallel #(
	parameter DW_VD = 12,
	parameter DW_VX = 4,
	parameter BUF_LEN = 4096,
	parameter USE_VENDOR_FIFO = 0,
    parameter MAX_HEIGHT = 1024,
    parameter MAX_WIDTH = 1280,
	parameter TIMEOUT_MS = 1000,
	parameter CLK_FREQ_HZ = 5_000_000

)(

    input 				clk,
    input 				rstb,

    input [DW_VD-1:0] 	s_vb_dat,
	input [DW_VX-1:0]	s_vb_aux,
    input 				s_vb_val,
    output 				s_vb_rdy,

    output reg 			fval,
    output reg 			lval,
    output reg 			dval,
    output [DW_VD-1:0] 	pix_data

);


    // Parameters
    localparam DW_FIFO = DW_VD + 2; // Data Width + SOF + EOL
	localparam TIMEOUT_CC = TIMEOUT_MS * (CLK_FREQ_HZ/1000);


    // States
    localparam IDLE = 0;
    localparam FVAL_HIGH = 1;
    localparam LINE_WAIT = 2;
    localparam LVAL_HIGH = 3;
    localparam DVAL_HIGH = 4;
    localparam LVAL_LOW = 5;
    localparam FVAL_LOW = 6;


	wire sof;
    wire eol;
	wire [DW_VD-1:0] dat;
	wire valid;
	wire ready;

	wire sof_in;
	wire eol_in;
	wire sof_out;
	wire eol_out;

	wire wr_en;
	reg rd_en;
	wire full;
	wire empty;

	wire [DW_FIFO-1:0] din;
	wire [DW_FIFO-1:0] dout;

	// Counter of EOLs in FIFO
    reg [$clog2(MAX_HEIGHT):0] eol_cntr;

	// Counter of SOFs in FIFO
    reg [$clog2(MAX_HEIGHT):0] sof_cntr;

	reg [31:0] timeout_cntr;

	wire blanking_time_end;


	reg [2:0] time_cntr;
	reg [3:0] state;




    assign s_vb_rdy = !full;

	// Rename bus wires
	assign sof = s_vb_aux[0];
    assign eol = s_vb_aux[1];
	assign dat = s_vb_dat;
	assign valid = s_vb_val;
	assign ready = s_vb_rdy;



	// FIFO input
	assign din = {eol, sof, dat};
	assign sof_in = sof && valid && ready;
	assign eol_in = eol && valid && ready;


	// FIFO output
	assign pix_data = dout[DW_FIFO-3:0];
	assign sof_out = dout[DW_FIFO-2];
	assign eol_out = dout[DW_FIFO-1];


	assign wr_en = valid && ready;
	assign blanking_time_end = (time_cntr == 3'b111);


	// ----------------------------------------
	// Buffer FIFO
	// ----------------------------------------
    sync_fifo #(.WIDTH(DW_FIFO), .DEPTH(BUF_LEN), .USE_VENDOR(USE_VENDOR_FIFO)) VIDEO_DATA_FIFO (
        .rst(!rstb),
        .clk(clk),
        .din(din),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .dout(dout),
        .full(full),
        .empty(empty)
    );


	// ----------------------------------------
    // EOL counter
	// ----------------------------------------
	always @(posedge clk or negedge rstb) begin
		if(!rstb) begin
			eol_cntr <= 0;
		end else begin

			// If eol is received to FIFO
			if(eol_in && !eol_out)
				eol_cntr <= eol_cntr + 1;

			// If eol is out from FIFO
			if(!eol_in && eol_out)
				eol_cntr <= (eol_cntr == 0) ? 1'b0 : (eol_cntr - 1);

		end
	end


	// ----------------------------------------
    // SOF counter
	// ----------------------------------------
	always @(posedge clk or negedge rstb) begin
		if(!rstb) begin
			sof_cntr <= 0;
		end else begin

			// If SOF is received to FIFO
			if(sof_in && !sof_out)
				sof_cntr <= sof_cntr + 1;

			// If SOF is out from FIFO
			if(!sof_in && sof_out && rd_en)
				sof_cntr <= (sof_cntr == 0) ? 1'b0 : (sof_cntr - 1);

		end
	end


	// ----------------------------------------
    // State machine
	// ----------------------------------------
	always @(posedge clk or negedge rstb) begin
		if(!rstb) begin
			fval <= 0;
			lval <= 0;
			dval <= 0;
			time_cntr <= 0;
			timeout_cntr <= 0;
			state <= IDLE;
		end else begin
			case(state)
				IDLE: begin
					// If there is no SOF at the output
					// then continue getting data
					if(!empty && !sof_out) begin
						rd_en <= 1;
					end else begin
						rd_en <= 0;
					end

					state <= sof_out ? FVAL_HIGH : IDLE;
				end

				FVAL_HIGH: begin
					fval <= 1;
					lval <= 0;
					rd_en <= 0;
					state <= (eol_cntr > 0) ? LVAL_HIGH : FVAL_HIGH;
				end

				LINE_WAIT: begin
					lval <= 0;
					timeout_cntr <= timeout_cntr + 1;

					if(timeout_cntr == TIMEOUT_CC) begin
						timeout_cntr <= 0;
						state <= FVAL_LOW;
					end else begin
						if(sof_out) begin
							state <= FVAL_LOW;
						end else if (eol_cntr > 0) begin
							state <= LVAL_HIGH;
						end
					end
				end

				LVAL_HIGH: begin
					lval <= 1;
					rd_en <= 0;
					time_cntr <= time_cntr + 1;
					state <= blanking_time_end ? DVAL_HIGH : LVAL_HIGH;
				end

				DVAL_HIGH: begin
					dval <= 1;
					rd_en <= 1;
					if(eol_out) begin
						dval <= 0;
						rd_en <= 0;
						state <= LVAL_LOW;
					end
				end

				LVAL_LOW: begin
					dval <= 0;
					rd_en <= 0;
					time_cntr <= time_cntr + 1;
					if(blanking_time_end) begin
						state <= LINE_WAIT;
					end
				end

				FVAL_LOW: begin
					time_cntr <= time_cntr + 1;
					lval <= 0;
					if(blanking_time_end) begin
						fval <= 0;
						state <= IDLE;
					end
				end
			endcase
		end
    end



/*
    reg [$clog2(MAX_WIDTH):0] pix_cntr;
    reg [$clog2(MAX_HEIGHT):0] line_cntr;
    reg [$clog2(MAX_WIDTH):0] col_cntr;

    reg [$clog2(MAX_WIDTH):0] width_inferred;
    reg [$clog2(MAX_HEIGHT):0] height_inferred;

    reg is_first_frame;





    assign line_end = (pix_cntr >= width_inferred);
    assign frame_end = (line_cntr >= (height_inferred-1));


*/


endmodule
