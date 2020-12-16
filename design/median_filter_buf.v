

/*
Author: Semih GENC
Description : Median filter line buffering logic with VB interface
Version : 1.00
*/


module median_filter_buf #(
	parameter SIZE 				= 3,
	parameter BUF_LEN 			= 4096,
	parameter USE_VENDOR_FIFO 	= 0,

    parameter DW_VD 			= 14,
    parameter DW_VX 			= 4,
	parameter DW_MA 			= 8,
	parameter DW_MD 			= 16,
	parameter DW_FIFO 			= DW_VD + 1 // pixel + mask
)(

    input clk,
    input rstb,

    // Slave Video Bus
    input 						s_vb_val,
    output reg         			s_vb_rdy,
    input [DW_VX-1:0]  			s_vb_aux,
    input [DW_VD-1:0]  			s_vb_dat,

	// Config
	input [DW_MD-1:0] 			iw,
	input [DW_MD-1:0]			ih,

	// Status
	output 						oflow,
	output 						uflow,

	// Aux. signals
	input [15:0] 				sent_line_cntr,
	output reg [15:0]			rcvd_line_cntr,
	input 						line_stack_glb_rd_en,
	output [SIZE*DW_FIFO-1:0]	line_stack_dout

);


	// States
	localparam MF_RX_IDLE = 0;
	localparam MF_RX_FILL_FIFO = 1;
	localparam MF_RX_WAIT = 2;
	localparam MF_RX_RESET = 3;


	// State variable
	reg [3:0] state;
	reg [3:0] wait_cntr;
	reg line_stack_wr_en;
	reg [DW_FIFO-1:0] line_stack_din;
	wire rstb_lines;


	// Slave Video Bus
	wire 	s_vb_sof;
	wire 	s_vb_eol;
	wire 	s_vb_msk;


	assign 	s_vb_sof = s_vb_aux[0];
	assign 	s_vb_eol = s_vb_aux[1];
	assign 	s_vb_msk = s_vb_aux[2];
	assign 	wait_read = (rcvd_line_cntr - sent_line_cntr) > (BUF_LEN/iw);
	assign 	rstb_lines = (state != MF_RX_RESET) && rstb;



	median_filter_lines #( .SIZE(SIZE), .BUF_LEN(BUF_LEN), .DW_FIFO(DW_FIFO), .USE_VENDOR_FIFO(USE_VENDOR_FIFO))
	LINE_STACK (
	    .clk(clk),
	    .rstb(rstb_lines),
		.rcvd_line_cntr(rcvd_line_cntr),
		.line_stack_glb_rd_en(line_stack_glb_rd_en),
		.line_stack_dout(line_stack_dout),
		.line_stack_wr_en(line_stack_wr_en),
		.line_stack_din(line_stack_din),
		.oflow(oflow),
		.uflow(uflow)
	);


    /////////////////////////////////////////////////
    // State machine
    /////////////////////////////////////////////////
    always @(posedge clk or negedge rstb) begin
        if(!rstb) begin
            state <= MF_RX_IDLE;

            s_vb_rdy <= 0;
            rcvd_line_cntr <= 0;
			wait_cntr <= 0;

			line_stack_din <= 0;
			line_stack_wr_en <= 0;
        end else begin
			line_stack_wr_en <= 0;
            case(state)
                MF_RX_IDLE: begin
                    if(!s_vb_sof) begin
                        // If buffer do not contain a pixel with SOF asserted,
                        // then continue receiving until a SOF is caught.
                        s_vb_rdy <= 1;
                    end else begin
                        // Catch the first pixel with SOF and write it to FIFO
                        line_stack_din <= {s_vb_msk, s_vb_dat};
						s_vb_rdy <= 1;
						if(s_vb_rdy && s_vb_val) begin
							line_stack_wr_en <= 1;
	                        state <= MF_RX_FILL_FIFO;
						end
                    end

                end
                MF_RX_FILL_FIFO: begin
                    s_vb_rdy <= 1;

					if(s_vb_rdy && s_vb_val) begin
						line_stack_wr_en <= 1;
						line_stack_din <= {s_vb_msk, s_vb_dat};

						if(s_vb_eol)
							rcvd_line_cntr <= rcvd_line_cntr + 1;
					end

                    if(wait_read) begin
                        s_vb_rdy <= 0;
                    end

					if(rcvd_line_cntr == ih) begin
						state <= MF_RX_WAIT;
						s_vb_rdy <= 0;
					end
                end
                MF_RX_WAIT: begin
					if(rcvd_line_cntr == sent_line_cntr) begin
						rcvd_line_cntr <= 0;
						state <= MF_RX_RESET;
					end
                end

				MF_RX_RESET: begin
					wait_cntr <= wait_cntr + 1;
					if(&wait_cntr) begin
						wait_cntr <= 0;
						state <= MF_RX_IDLE;
					end
				end
            endcase
        end
    end


endmodule
