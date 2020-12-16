
/*
Author: Semih GENC
Description : Median filter configuration memory module;
Version : 1.00
*/

module median_filter_conf #(
	parameter DW_MA = 8,
	parameter DW_MD = 16

) (

	input clk,
	input rstb,

	input [DW_MA-1:0] 	s_mb_adr,
	input [DW_MD-1:0] 	s_mb_wdt,
	output [DW_MD-1:0] 	s_mb_rdt,
	output 				s_mb_val,

	output [15:0] iw,
	output [15:0] ih,
	output en,

	output rstb_int

);


	localparam                  NUM_OF_REG = 4;
    localparam [NUM_OF_REG-1:0] DIR_M = 4'b_0000;
    localparam [DW_MD-1:0]      DEF_IMAGE_W = 640;
    localparam [DW_MD-1:0]      DEF_IMAGE_H = 480;
	localparam [DW_MD-1:0]		DEF_CTRL = 16'h0000;
    // All output

    wire [15:0] conf_m0;
    wire [15:0] conf_m1;
    wire [15:0] conf_m2;
    wire [15:0] conf_m3;


	assign en = conf_m0[0];
	assign iw = conf_m1;
	assign ih = conf_m2;


	assign ext_reset = ((s_mb_adr == 2'b01) || (s_mb_adr == 2'b10)) && s_mb_wdt && s_mb_val;

	reset_gen #(.LEN(8), .INV(1))
	RST_GEN (
		.clk(clk),
		.rstb(rstb),
		.ext_reset(ext_reset),
		.gen_reset(rstb_int)
	);

    conf_mem_4 #(
    	.DW_MA(DW_MA),
    	.DW_MD(DW_MD),
    	.NUM_OF_REG(NUM_OF_REG),

    	.DEF_M0(DEF_CTRL),
    	.DEF_M1(DEF_IMAGE_W),
    	.DEF_M2(DEF_IMAGE_H),
    	.DEF_M3(),

    	.DIR_M(DIR_M))
    CONF_MEM (
    	.clk(clk),
    	.rstb(rstb),

    	.adr(s_mb_adr),
    	.wdt(s_mb_wdt),
    	.rdt(s_mb_rdt),
    	.val(s_mb_val),

    	.m0(conf_m0),
    	.m1(conf_m1),
    	.m2(conf_m2),
    	.m3(conf_m3)
    );


endmodule
