

/*
Author: Semih GENC
Description : Adds delay to data
Version : 1.00
*/


module add_latency #(
    parameter DW = 8,
    parameter LAT = 4
)(
    input clk,
    input [DW-1:0]  din,
    output [DW-1:0] dout
 );


    integer i;


    // Shift register to create latency
    reg [DW-1:0] din_samp[0:LAT-1];


    // Output data
    assign dout = (LAT == 0) ? din : din_samp[LAT-1];


    // Shift bits
    always @(posedge clk) begin
        din_samp[0] <= din;
        for(i=0; i<LAT-1; i=i+1) begin
            din_samp[i+1] <= din_samp[i];
        end
    end


endmodule
