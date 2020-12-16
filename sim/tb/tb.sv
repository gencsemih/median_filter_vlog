`timescale 1ns/1ps

module tb ();

    // Testbench parameters
    parameter CLK_FREQ_HZ = 125_000_000;
    parameter CLK_PER_NS = 1_000_000_000 / CLK_FREQ_HZ; //Clock period in ns


    // Median Filter IP
    parameter BPP = 8;
    parameter SIZE = 3;
    parameter PAD_OPT = "zeros";
    parameter WIDTH = 640;
    parameter HEIGHT = 480;
    parameter IN_BUF_LEN = 4096;
    parameter OUT_BUF_LEN = 2048;
    parameter USE_VENDOR_FIFO = 0;


    // Video and memory bus widths
    parameter DW_VD = BPP;
    parameter DW_VX = 4;
    parameter DW_MA = 8;
    parameter DW_MD = 16;


    // File frame grabber
    parameter string OUTPUT_PATH = "../images/out/";
    parameter string FILE_PREFIX_INPUT = "../images/in/img";
    parameter string FILE_PREFIX_MASK = "../images/in/mask";
    parameter string FILE_EXT = ".pgm";
    parameter SCALETO8BIT = 0;
    parameter COLORED = 0;


    // Timing generation
    parameter T_IDLE2FVAL = 8192;
    parameter T_LVALHIGH_DVALHIGH = 16;
    parameter T_DVALLOW_LVALLOW = 16;
    parameter T_LVALLOW = 16;

    parameter FPS = 100;
    parameter TIMEOUT_MS = 1000;


    // Reference clock
    reg clk;

    // Async reset
    reg rstb;

    // Frame timing generator signals
    reg                 en_ftg;
    wire                fval_gen;
    wire                lval_gen;
    wire                dval_gen;
    reg                 reader_read;
    wire [$clog2(HEIGHT)-1:0] reader_row;
    wire [$clog2(WIDTH)-1:0] reader_col;


    // Reader data outputs
    wire [BPP-1:0]      pix_data_gen;
    wire [BPP-1:0]      mask_data_gen;


    // Mask always bit
    reg                 mask_always;
    wire                mask_data_sel;

    wire                error;

    wire                s_vb_val;
    wire                s_vb_rdy;
    wire [DW_VX-1:0]    s_vb_aux;
    wire [DW_VD-1:0]    s_vb_dat;

    wire                m_vb_val;
    wire                m_vb_rdy;
    wire  [DW_VX-1:0]   m_vb_aux;
    wire  [DW_VD-1:0]   m_vb_dat;

    wire                fval_out;
    wire                lval_out;
    wire                dval_out;
    wire [BPP-1:0]      pix_data_out;

    reg [DW_MA-1:0]     s_mb_adr;
    reg [DW_MD-1:0]     s_mb_wdt;
    wire [DW_MD-1:0]    s_mb_rdt;
    reg                 s_mb_val;


    // Input image file reader
    pgm_reader #(
        .FILE_PREFIX(FILE_PREFIX_INPUT),
        .FILE_EXT(FILE_EXT),
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .BPP(BPP))
    PGM_READER_IMAGE (
        .rstb(rstb),
        .clk(clk),
        .read(reader_read),
        .row(reader_row),
        .column(reader_col),
        .data_out(pix_data_gen)
    );


    // Mask image file reader
    pgm_reader #(
        .FILE_PREFIX(FILE_PREFIX_MASK),
        .FILE_EXT(FILE_EXT),
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .BPP(BPP))
    PGM_READER_MASK (
        .rstb(rstb),
        .clk(clk),
        .read(reader_read),
        .row(reader_row),
        .column(reader_col),
        .data_out(mask_data_gen)
    );


    // Video timing generation
    frame_timing_generator #(
        .CLK_PERIOD(CLK_PER_NS),
        .FPS(FPS), //frames per second
        .WIDTH(WIDTH), //Number of pixels in horizontal line
        .HEIGHT(HEIGHT), //Number of horizontal lines to be read in each frame
        .T_IDLE2FVAL(T_IDLE2FVAL),
        .T_LVALHIGH_DVALHIGH(T_LVALHIGH_DVALHIGH),
        .T_DVALLOW_LVALLOW(T_DVALLOW_LVALLOW),
        .T_LVALLOW(T_LVALLOW))
    FRAME_TIMING_GEN (
        .clk(clk), //Clock
        .rstb(rstb), //Active low reset
        .en(en_ftg), //Enable pulse that triggers the whole operation
        .fval(fval_gen), //Frame valid signal
        .lval(lval_gen), //Line valid signal
        .dval(dval_gen), //data valid signal
        .row(reader_row),
        .col(reader_col)
    );


    // FLDval to VBUS conversion
    parallel_2_vbus #(
        .BPP(BPP+1),
        .DW_VD(DW_VD),
        .DW_VX(DW_VX),
        .USE_VENDOR_FIFO(USE_VENDOR_FIFO))
    PAR_2_VBUS (
        .clk(clk),
        .rstb(rstb),

        .fval(fval_gen),
        .lval(lval_gen),
        .dval(dval_gen),
        .pix_data({mask_data_sel, pix_data_gen}),

        .m_vb_dat(s_vb_dat),
        .m_vb_val(s_vb_val),
        .m_vb_rdy(s_vb_rdy),
        .m_vb_aux(s_vb_aux)
    );


    // DUT
    median_filter #(
        .SIZE(SIZE),
        .PAD_OPT(PAD_OPT),
        .IN_BUF_LEN(IN_BUF_LEN),
        .OUT_BUF_LEN(OUT_BUF_LEN),
        .USE_VENDOR_FIFO(USE_VENDOR_FIFO),
        .DW_VD(DW_VD),
        .DW_VX(DW_VX),
        .DW_MA(DW_MA),
        .DW_MD(DW_MD))
    DUT (

        .clk(clk),
        .rstb(rstb),

        .error(error),

        // Slave video bus
        .s_vb_val(s_vb_val),
        .s_vb_rdy(s_vb_rdy),
        .s_vb_aux(s_vb_aux),
        .s_vb_dat(s_vb_dat),

        // Master video bus
        .m_vb_val(m_vb_val),
        .m_vb_rdy(m_vb_rdy),
        .m_vb_aux(m_vb_aux),
        .m_vb_dat(m_vb_dat),

        // Slave memory bus
        .s_mb_adr(s_mb_adr),
        .s_mb_wdt(s_mb_wdt),
        .s_mb_rdt(s_mb_rdt),
        .s_mb_val(s_mb_val)
    );


    // AXIS to FLDval conversion
    vbus_2_parallel #(
        .DW_VD(DW_VD),
        .DW_VX(DW_VX),
        .USE_VENDOR_FIFO(USE_VENDOR_FIFO),
        .MAX_HEIGHT(HEIGHT),
        .MAX_WIDTH(WIDTH),
        .BUF_LEN(OUT_BUF_LEN),
        .TIMEOUT_MS(TIMEOUT_MS),
        .CLK_FREQ_HZ(CLK_FREQ_HZ))
    VBUS_2_PAR (
        .clk(clk),
        .rstb(rstb),

        .s_vb_dat(m_vb_dat),
        .s_vb_val(m_vb_val),
        .s_vb_rdy(m_vb_rdy),
        .s_vb_aux(m_vb_aux),

        .fval(fval_out),
        .lval(lval_out),
        .dval(dval_out),
        .pix_data(pix_data_out)
    );


    // Grab output files and write it to PGM file
    file_frame_grabber #(
        .WIDTH(WIDTH),
        .HEIGHT(HEIGHT),
        .BPP(BPP),
        .OUTPUT_PATH(OUTPUT_PATH),
        .SCALETO8BIT(SCALETO8BIT),
        .COLORED(COLORED))
    FILE_FRAME_GRABBER(
        .rstb(rstb),
        .pix_clk(clk),
        .fval(fval_out),
        .lval(lval_out),
        .dval(dval_out),
        .pix_data(pix_data_out)
    );


    reg chk;
    wire res_1;
    wire res_2;
    file_compare #( .ISSUE_MESSAGES(0))
    FILE_COMP_1 (
        .file_path_1("../images/golden/filtered_w_mask.pgm"),
        .file_path_2("../images/out/_img0.pgm"),
        .check(chk),
        .result(res_1)
    );
    file_compare #( .ISSUE_MESSAGES(0))
    FILE_COMP_2 (
        .file_path_1("../images/golden/filtered.pgm"),
        .file_path_2("../images/out/_img2.pgm"),
        .check(chk),
        .result(res_2)
    );


    // Task for IP configuration
    task WRITE_TO_CONFIG;
        input [7:0] addr;
        input [15:0] data;
    begin
        s_mb_adr = addr;
        s_mb_wdt = data;
        s_mb_val = 1'b1;
        @(posedge clk);
        #2 s_mb_val = 1'b0;
        @(posedge clk);
    end
    endtask


    // Clock generation
    always #(CLK_PER_NS/2) clk = !clk;

    assign mask_data_sel = mask_always ? 1'b1 : mask_data_gen[0];

    initial begin
        rstb = 0;
        clk = 0;
        en_ftg = 0;
        reader_read = 0;
        s_mb_adr = 0;
        s_mb_wdt = 0;
        s_mb_val = 0;
        mask_always = 0;
        chk = 0;


        repeat (100) @(posedge clk);
        rstb = 1;
        repeat (100) @(posedge clk);

        // Read image/mask from file
        @(posedge clk);
        reader_read = 1;
        @(posedge clk);
        reader_read = 0;

        // Write custom image width value and see if the module resets blocks
        repeat (100) @(posedge clk);
        WRITE_TO_CONFIG(8'b01, 16'd640);    // Set WIDTH
        WRITE_TO_CONFIG(8'b10, 16'd480);    // Set HEIGHT
        WRITE_TO_CONFIG(8'b00, 16'd1);         // Enable the module



        en_ftg = 1;
        $display("### TB: Filtering image with mask (k=3)...");
        @(negedge fval_out);    // First frame

        mask_always = 1;
        $display("### TB: Filtering image without mask (k=3)...");
        @(negedge fval_out);    // Second frame

        // Skip 1 more frame because we assert "mask_always" after the second frame is started
        // The third frame will have "mask_always" correctly.
        @(negedge fval_out);     // Third frame
        repeat (100) @(posedge clk);

        $display("#############################################");
        $display("######## MEDIAN FILTER TEST RESULT ##########");
        // Check for tests
        @(posedge clk) chk = 1;
        @(posedge clk) chk = 0;
        if(res_1==0) $display("TEST 1 _____________________________ PASSED");
        else         $display("TEST 1 _____________________________ FAILED !!!");
        if(res_2==0) $display("TEST 2 _____________________________ PASSED");
        else         $display("TEST 2 _____________________________ FAILED !!!");
        $display("#############################################");

        @(posedge clk);
        $finish;

    end

endmodule
