

/*
Author: Semih GENC
Description : Line buffers for median filtering
Version : 1.00
*/


module median_filter_lines #(
    parameter SIZE = 3,
    parameter DW_FIFO = 9,
    parameter BUF_LEN = 4096,
    parameter USE_VENDOR_FIFO = 0
)(

    input clk,
    input rstb,

    // Write/Read FIFO
    input                       line_stack_glb_rd_en,
    output [SIZE*DW_FIFO-1:0]   line_stack_dout,

    input                       line_stack_wr_en,
    input [DW_FIFO-1:0]         line_stack_din,

    input [15:0]                rcvd_line_cntr,


    // Aux. signals
    output                      oflow,
    output                      uflow

);


    wire [DW_FIFO-1:0]          fifo_din [0:SIZE-1];
    wire [DW_FIFO-1:0]          fifo_dout [0:SIZE-1];
    wire                        fifo_wr_en [0:SIZE-1];
    wire                        fifo_rd_en [0:SIZE-1];
    wire                        fifo_empty [0:SIZE-1];
    wire                        fifo_full [0:SIZE-1];


    // Loop variable
    integer i;


    // ----------------------------------------
    // FIFO Instantiation
    // Required number of FIFO will be instantiated.
    // FIFOs for line stack are instantiated automatically depending on k (SIZE).
    // ----------------------------------------
    genvar m;
    generate
        for(m=0; m<SIZE; m=m+1) begin : GEN_LINE_BUFFER
            sync_fifo #(.WIDTH(DW_FIFO), .DEPTH(BUF_LEN), .USE_VENDOR(USE_VENDOR_FIFO)) LINE_FIFO[m:m] (.rst(!rstb), .clk(clk), .din(fifo_din[m]), .dout(fifo_dout[m]), .wr_en(fifo_wr_en[m]), .rd_en(fifo_rd_en[m]), .empty(fifo_empty[m]), .full(fifo_full[m]));
            assign line_stack_dout[m*DW_FIFO +: DW_FIFO] = fifo_dout[m];
        end
    endgenerate


    // ----------------------------------------
    // Line stack FIFOs are connected in cascaded fashion.
    // ----------------------------------------
    genvar n;
    generate
        for(n=0; n<SIZE-1; n=n+1) begin
            assign fifo_din[n+1] = fifo_dout[n];
        end
    endgenerate


    // ----------------------------------------
    // Line stack data input
    // ----------------------------------------
    assign fifo_din[0] = line_stack_din;


    // ----------------------------------------
    // Error
    // ----------------------------------------
    assign uflow = fifo_empty[0] && fifo_rd_en[0];
    assign oflow = fifo_full[0] && fifo_wr_en[0];


    // ----------------------------------------
    // Line stack data transfer logic
    // ----------------------------------------
    assign fifo_wr_en[0] = line_stack_wr_en;

    genvar p;
    generate
        for(p=0; p<SIZE; p=p+1) begin
            assign fifo_rd_en[p] = ((p + 1) <= rcvd_line_cntr) ? line_stack_glb_rd_en : 0;
        end
    endgenerate

    genvar r;
    generate
        for(r=1; r<SIZE; r=r+1) begin
            assign fifo_wr_en[r] = (r <= rcvd_line_cntr) ? line_stack_glb_rd_en : 0;
        end
    endgenerate



endmodule
