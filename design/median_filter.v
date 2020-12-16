

/*
Author: Semih GENC
Description : Median Filter with VB interface
Version : 1.00
*/


module median_filter #(
    parameter SIZE              = 3,
    parameter IN_BUF_LEN        = 2048,
    parameter OUT_BUF_LEN       = 2048,
    parameter USE_VENDOR_FIFO   = 0,
    parameter PAD_OPT           = "zeros",

    parameter DW_VD             = 14,
    parameter DW_VX             = 4,
    parameter DW_MA             = 8,
    parameter DW_MD             = 16
)(

    input clk,
    input rstb,


    output              error,

    // Slave video bus
    input               s_vb_val,
    output              s_vb_rdy,
    input [DW_VX-1:0]   s_vb_aux,
    input [DW_VD-1:0]   s_vb_dat,

    // Master video bus
    output              m_vb_val,
    input               m_vb_rdy,
    output [DW_VX-1:0]  m_vb_aux,
    output [DW_VD-1:0]  m_vb_dat,

    // Slave memory bus
    input [DW_MA-1:0]   s_mb_adr,
    input [DW_MD-1:0]   s_mb_wdt,
    input [DW_MD-1:0]   s_mb_rdt,
    input               s_mb_val


    );

    /////////////////////////////////////////////////
    // Params
    /////////////////////////////////////////////////
    localparam SIZE_HALF = SIZE/2;


    // Do not change this parameters
    localparam DELAY_CORE_REG = SIZE/2 + 1;                 // Core register delay: Counter delays; +2 consists of one clock cycle for middle elements
    localparam DELAY_CORE_SORT = 5;                    // Core sorting pipeline delay
    localparam DELAY_CORE_TOTAL = DELAY_CORE_REG + DELAY_CORE_SORT;    // Core total delay


    /////////////////////////////////////////////////
    // IP Configuration
    /////////////////////////////////////////////////
    // Enable bit
    wire en;

    // Image size
    wire [DW_MD-1:0] iw;
    wire [DW_MD-1:0] ih;

    // Block resets
    wire rstb_int;


    /////////////////////////////////////////////////
    // Buffering data into line FIFOs
    /////////////////////////////////////////////////
    wire                line_stack_glb_rd_en;
    wire [SIZE*(DW_VD+1)-1:0] line_stack_dout;
    wire [15:0]         sent_line_cntr;
    wire [15:0]         rcvd_line_cntr;
    wire                rcv_oflow;
    wire                rcv_uflow;
    wire                tx_uflow;
    wire                tx_oflow;

    wire [DW_VX-1:0]    s_buf_vb_aux;
    wire [DW_VD-1:0]    s_buf_vb_dat;
    wire                s_buf_vb_val;
    wire                s_buf_vb_rdy;

    wire [DW_VX-1:0]    m_filt_vb_aux;
    wire [DW_VD-1:0]    m_filt_vb_dat;
    wire             m_filt_vb_val;
    wire                m_filt_vb_rdy;

    wire [DW_VX-1:0]    m_tx_vb_aux;
    wire [DW_VD-1:0]    m_tx_vb_dat;
    wire                m_tx_vb_val;
    wire                m_tx_vb_rdy;

    assign error = rcv_oflow | rcv_uflow | tx_oflow | tx_uflow;


    // Enable
    assign m_vb_aux = en ? m_tx_vb_aux : s_vb_aux;
    assign m_vb_dat = en ? m_tx_vb_dat : s_vb_dat;
    assign m_vb_val = en ? m_tx_vb_val : s_vb_val;
    assign s_vb_rdy = en ? s_buf_vb_rdy : m_vb_rdy;
    assign m_tx_rdy = en ? m_vb_rdy : 1'b0;
    assign m_tx_vb_rdy = m_vb_rdy;

    assign s_buf_vb_val = en ? s_vb_val : 1'b0;
    assign s_buf_vb_dat = s_vb_dat;
    assign s_buf_vb_aux = s_vb_aux;


    // ----------------------------------------
    // Configuration
    // ----------------------------------------
    median_filter_conf #(DW_MA, DW_MD)
    MED_FILT_CONFIG (
        .clk(clk),
        .rstb(rstb),

        // Slave memory bus
        .s_mb_adr(s_mb_adr),
        .s_mb_wdt(s_mb_wdt),
        .s_mb_rdt(s_mb_rdt),
        .s_mb_val(s_mb_val),

        .en(en),
        .iw(iw),
        .ih(ih),
        .rstb_int(rstb_int)
    );


    // ----------------------------------------
    // Line Buffering
    // ----------------------------------------
    median_filter_buf #(SIZE, IN_BUF_LEN, USE_VENDOR_FIFO, DW_VD, DW_VX, DW_MA, DW_MD)
    MED_FILT_BUFFER(

        .clk(clk),
        .rstb(rstb_int),

        // Slave video bus
        .s_vb_val(s_buf_vb_val),
        .s_vb_rdy(s_buf_vb_rdy),
        .s_vb_aux(s_buf_vb_aux),
        .s_vb_dat(s_buf_vb_dat),

        .iw(iw),
        .ih(ih),
        .oflow(rcv_oflow),
        .uflow(rcv_uflow),
        .sent_line_cntr(sent_line_cntr),
        .rcvd_line_cntr(rcvd_line_cntr),
        .line_stack_glb_rd_en(line_stack_glb_rd_en),
        .line_stack_dout(line_stack_dout)

    );


    // ----------------------------------------
    // Median finding
    // ----------------------------------------
    median_filter_filt #(SIZE, PAD_OPT, DELAY_CORE_TOTAL, DW_VD, DW_VX, DW_MA, DW_MD)
    MED_FILT_FILTER(

        .clk(clk),
        .rstb(rstb_int),

        .aux(m_filt_vb_aux),
        .dat(m_filt_vb_dat),
        .val(m_filt_vb_val),
        .rdy(m_filt_vb_rdy),
        .iw(iw),
        .ih(ih),
        .line_stack_dout(line_stack_dout),
        .line_stack_glb_rd_en(line_stack_glb_rd_en),
        .sent_line_cntr(sent_line_cntr),
        .rcvd_line_cntr(rcvd_line_cntr)
    );


    // ----------------------------------------
    // Output buffering
    // ----------------------------------------
    median_filter_tx #(DW_VD, DW_VX, OUT_BUF_LEN, USE_VENDOR_FIFO)
    MED_FILT_TX (
        .clk(clk),
        .rstb(rstb_int),

        .aux(m_filt_vb_aux),
        .dat(m_filt_vb_dat),
        .val(m_filt_vb_val),
        .rdy(m_filt_vb_rdy),

        .iw(iw),
        .oflow(tx_oflow),
        .uflow(tx_uflow),

        .m_vb_val(m_tx_vb_val),
        .m_vb_rdy(m_tx_vb_rdy),
        .m_vb_aux(m_tx_vb_aux),
        .m_vb_dat(m_tx_vb_dat)
    );




endmodule
