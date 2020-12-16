

/*
Author: Semih GENC
Description : Converts parallel video bus to VBUS interface
Version : 1.00
*/


module parallel_2_vbus #(
	parameter BPP = 16,
	parameter DW_VD = 12,
	parameter DW_VX = 4,
	parameter USE_VENDOR_FIFO = 0

)(

    input clk,
    input rstb,

    input 				fval,
    input 				lval,
    input 				dval,
    input [BPP-1:0]		pix_data,

    output [DW_VD-1:0] 	m_vb_dat,
    output 				m_vb_val,
    input 				m_vb_rdy,
    output [DW_VX-1:0] 	m_vb_aux

);


    localparam FIFO_DEPTH = 4096;
    localparam SOF_LEN = 1;
    localparam EOL_LEN = 1;
    localparam FIFO_DATA_WIDTH = SOF_LEN + EOL_LEN + BPP;


    reg [2:0] fval_samp;
    reg [2:0] lval_samp;
    reg [2:0] dval_samp;
    reg [BPP-1:0] pix_data_samp [0:2];
    reg sof;
    wire rd_en;
    wire wr_en;

    wire eol_bit;
    wire sof_bit;
    wire [FIFO_DATA_WIDTH-1:0] din;
    wire [FIFO_DATA_WIDTH-1:0] dout;

    wire empty;
    wire full;



    assign eol_bit = !dval && dval_samp[0];
    assign sof_bit = sof;
    assign din = {sof_bit, eol_bit, pix_data_samp[0]};
    assign rd_en = (m_vb_rdy && m_vb_val);
    assign wr_en = dval_samp[0];

    assign m_vb_dat = dout[BPP-2:0];
    assign m_vb_val = !empty;
    assign m_vb_aux[0] = dout[BPP+1];
    assign m_vb_aux[1] = dout[BPP];
	assign m_vb_aux[2] = dout[BPP-1];
	assign m_vb_aux[3] = 1'b0;


    sync_fifo #(.WIDTH(FIFO_DATA_WIDTH), .DEPTH(FIFO_DEPTH), .USE_VENDOR(USE_VENDOR_FIFO)) VIDEO_DATA_FIFO (
        .rst(!rstb),
        .clk(clk),
        .din(din),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .dout(dout),
        .full(full),
        .empty(empty)
    );


    // Samplings
    always @(posedge clk) begin
        fval_samp <= {fval_samp[1:0], fval};
        lval_samp <= {lval_samp[1:0], lval};
        dval_samp <= {dval_samp[1:0], dval};
        pix_data_samp [0] <= pix_data;
        pix_data_samp [1] <= pix_data_samp[0];
        pix_data_samp [2] <= pix_data_samp[1];
    end


    // SOF bit
    always @(posedge clk or negedge rstb) begin
		if(!rstb) begin
			sof <= 1;
		end else begin
	        if(sof) begin
	            if(dval_samp[0] && fval_samp[0]) begin
	                sof <= 0;
	            end
	        end else begin
	            if(fval_samp[0] && !fval_samp[1]) begin
	                sof <= 1;
	            end
	        end
		end
    end


endmodule
