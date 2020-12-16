

/*
Author: Semih GENC
Description : Median filter output buffering
Version : 1.00
*/


module median_filter_tx #(
    parameter DW_VD             = 14,
    parameter DW_VX             = 4,
    parameter BUF_LEN           = 2048,
    parameter USE_VENDOR_FIFO   = 0
)(

    input clk,
    input rstb,


    // Receive interface
    input [DW_VX-1:0]   aux,
    input [DW_VD-1:0]   dat,
    input               val,
    output              rdy,


    // Config.
    input [15:0]        iw,
    output              uflow,
    output              oflow,

    // Master video bus
    output              m_vb_val,
    input               m_vb_rdy,
    output [DW_VX-1:0]  m_vb_aux,
    output [DW_VD-1:0]  m_vb_dat

);



    localparam DW_FIFO_TX = DW_VD + DW_VX;


    wire [DW_FIFO_TX-1:0]           din;
    wire [DW_FIFO_TX-1:0]           dout;
    wire                            empty;
    wire                            full;
    wire                            rd_en;
    reg [$clog2(BUF_LEN)-1:0]       lcnt;
    wire [$clog2(BUF_LEN)-1:0]      stop_cnt;


    assign din[DW_VD-1:0]           = dat;
    assign din[DW_VD+DW_VX-1:DW_VD] = aux;
    assign rd_en                    = m_vb_rdy && m_vb_val;

    assign m_vb_dat = dout[DW_VD-1:0];
    assign m_vb_aux = dout[DW_VD+DW_VX-1:DW_VD];
    assign m_vb_val = (m_vb_rdy && !empty);

    assign stop_cnt = ((BUF_LEN/iw) - 1);
    assign rdy = lcnt <= stop_cnt;
    assign line_out = m_vb_val && m_vb_rdy && m_vb_aux[1];
    assign line_in = val && aux[1];
    assign uflow = (empty && rd_en);
    assign oflow = (full && val);

    sync_fifo #(.WIDTH(DW_FIFO_TX), .DEPTH(BUF_LEN), .USE_VENDOR(USE_VENDOR_FIFO)) LINE_FIFO (.rst(!rstb), .clk(clk), .din(din), .dout(dout), .wr_en(val), .rd_en(rd_en), .empty(empty), .full(full));

    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            lcnt <= 0;
        end else begin
            if(line_in && !line_out) lcnt <= lcnt + 1;
            if(!line_in && line_out) lcnt <= (lcnt > 0) ? (lcnt - 1) : 0;
        end

    end


endmodule
