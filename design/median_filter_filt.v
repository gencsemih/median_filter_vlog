

/*
Author: Semih GENC
Description : Median Filtering Logic
Version : 1.00
*/


module median_filter_filt #(
    parameter SIZE              = 3,
    parameter PAD_OPT           = "zeros",
    parameter DELAY_CORE_TOTAL  = 0,

    parameter DW_VD             = 14,
    parameter DW_VX             = 4,
    parameter DW_MA             = 8,
    parameter DW_MD             = 16
)(

    input clk,
    input rstb,

    // Input from line FIFOs;
    // All outputs of line FIFOs are stacked
    // Containing pixels to be processed in median filter core
    input [SIZE*(DW_VD+1)-1:0]  line_stack_dout,

    // Config
    input [DW_MD-1:0]           iw,
    input [DW_MD-1:0]           ih,

    // Aux. signals
    output reg                  line_stack_glb_rd_en,
    input [15:0]                rcvd_line_cntr,
    output reg [15:0]           sent_line_cntr,            // The number of lines sent

    // Output to TX FIFO
    output [DW_VX-1:0]          aux,
    output [DW_VD-1:0]          dat,
    output                      val,
    input                       rdy

);


    // ----------------------------------------
    // States
    // ----------------------------------------
    localparam MF_TX_WAIT_RCV       = 0;
    localparam MF_TX_FILL_MIDLINE   = 1;
    localparam MF_TX_SEND_LINE      = 2;
    localparam MF_TX_NEW_FRAME      = 3;



    // ----------------------------------------
    // Variables
    // ----------------------------------------
    reg [2:0]           state_tx;             // State variable
    reg [15:0]          sent_pix_cntr;         // The number of pixels sent
    reg [15:0]          dummy_read_cntr;     // The number of dummy reads
    wire                free_to_send;         // The threshold comparator output
    reg                 tx;


    reg                 core_din_val;    // Median filter core input valid flag
    wire                core_dout_val;    // Median filter core output valid flag
    wire [SIZE*DW_VD-1:0] core_din;    // Median filter core stacked pixels input
    wire [DW_VD-1:0]    core_din_mid;    // Median filter core stacked pixels midline
    wire [DW_VD-1:0]    core_dout;        // Median filter core data output
    wire                core_din_mask;


    wire [DW_VD+2:0]    data_lat_in;
    wire [DW_VD+2:0]    data_lat_out;

    wire                sof;
    wire                eol;



    // Assignments
    assign free_to_send = (rcvd_line_cntr < ih) ? (rcvd_line_cntr - sent_line_cntr) > SIZE/2 : 1'b1;
    assign core_din_mask = line_stack_dout[((SIZE/2) + 1) * (DW_VD+1) - 1]; // MSBit of middle line data
    assign core_din_mid = line_stack_dout[(SIZE/2)*(DW_VD+1) +: DW_VD];


    // Set outputs
    assign dat = core_dout_val ? core_dout : data_lat_out[DW_VD-1:0];
    assign val = data_lat_out[DW_VD+2];
    assign aux = {1'b0, core_dout_val, data_lat_out[DW_VD +: 2]};

    assign data_lat_in = {tx, eol, sof, core_din_mid};
    genvar m;
    generate
        for(m=0; m<SIZE; m=m+1) begin : STACK_PARSING
            assign core_din[m*DW_VD +: DW_VD] = line_stack_dout[m*(DW_VD+1) +: DW_VD];
        end
    endgenerate


    // ----------------------------------------
    // Median Filter Core
    // ----------------------------------------
    median_filter_core #(.SIZE(SIZE), .DW(DW_VD), .PAD_OPT(PAD_OPT))
    MED_FILT_CORE (
        .clk(clk),
        .rstb(rstb),

        .iw(iw),
        .ih(ih),
        .sent_pix_cntr(sent_pix_cntr),
        .sent_line_cntr(sent_line_cntr),

        .stack_data(core_din),
        .valid(core_din_mask),
        .dout(core_dout),
        .dout_valid(core_dout_val)
    );


    // ----------------------------------------
    // Create some latency for sync. signals to compensate the core pipeline latency
    // ----------------------------------------
    add_latency #(.DW(DW_VD+3), .LAT(DELAY_CORE_TOTAL))
    PIPELINE_LATENCY (
        .clk(clk),
        .din(data_lat_in),
        .dout(data_lat_out)
    );

    assign sof = (sent_line_cntr == 0) && (sent_pix_cntr == 0);
    assign eol = (sent_pix_cntr == (iw - 1));


    // ----------------------------------------
    // State machine
    // ----------------------------------------
    always @(posedge clk or negedge rstb) begin
        if(!rstb) begin
            state_tx <= MF_TX_WAIT_RCV;

            //sof <= 0;
            //eol <= 0;
            tx <= 0;

            sent_pix_cntr       <= 0;
            sent_line_cntr      <= 0;
            dummy_read_cntr     <= 0;
            line_stack_glb_rd_en <= 0;
        end else begin
            line_stack_glb_rd_en <= 0;
            core_din_val        <= 0;
            tx                 <= 0;

            if(tx) sent_pix_cntr <= sent_pix_cntr + 1;

            case(state_tx)
                // Bring the first line to FIFO in the middle
                MF_TX_FILL_MIDLINE: begin
                    line_stack_glb_rd_en <= 1;
                    sent_pix_cntr <= sent_pix_cntr + 1;
                    if(sent_pix_cntr == (iw-1)) begin
                        dummy_read_cntr <= dummy_read_cntr + 1;
                        state_tx <= MF_TX_WAIT_RCV;
                    end
                end

                // Data throttling
                MF_TX_WAIT_RCV: begin
                    line_stack_glb_rd_en <= 0;
                    sent_pix_cntr <= 0;
                    tx <= 0;

                    if(rdy) begin // If TX FIFO is ok to receive
                        // The first line should be brought to the output of FIFO in the middle
                        if(dummy_read_cntr < SIZE/2) begin
                            if(rcvd_line_cntr > dummy_read_cntr) begin
                                state_tx <= MF_TX_FILL_MIDLINE;
                            end

                        // The remaining lines
                        end else begin
                            if(free_to_send) begin
                                state_tx <= MF_TX_SEND_LINE;
                                line_stack_glb_rd_en <= 1'b0;
                            end
                        end
                    end

                end

                MF_TX_SEND_LINE: begin
                    tx <= 1;
                    line_stack_glb_rd_en <= 1;

                    // If first line and first pixel is sent
                    //if((sent_line_cntr == 0) && (sent_pix_cntr == 0)) begin
                    //    sof <= 1'b1;
                //end

                    // Last pixel in a line
                    if(sent_pix_cntr == (iw-1)) begin
                        //eol <= 1'b1;
                        tx <= 1'b0;
                        line_stack_glb_rd_en <= 1'b0;
                        sent_line_cntr <= sent_line_cntr + 1;

                        if(sent_line_cntr == (ih - 1)) begin
                            state_tx <= MF_TX_NEW_FRAME;
                        end else begin
                            state_tx <= MF_TX_WAIT_RCV;
                        end
                    end
                end

                MF_TX_NEW_FRAME: begin
                    if(rcvd_line_cntr == 0) begin
                        sent_line_cntr <= 0;
                        sent_pix_cntr <= 0;
                        dummy_read_cntr <= 0;
                        state_tx <= MF_TX_WAIT_RCV;
                    end
                end

                    // Mask info sent to median filter core
                    /*if((sent_line_cntr < SIZE/2) || (sent_line_cntr >= (ih - SIZE/2))) begin
                        core_din_val <= 0;
                    end else begin
                        core_din_val <= core_din_mask;
                    end*/
            endcase
        end
    end




endmodule
