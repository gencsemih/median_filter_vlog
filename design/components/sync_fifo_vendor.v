

/*
Author: Semih GENC
Description : Vendor-dependent synchronous FIFO module/macro instantiation;
Version : 1.00
*/


module sync_fifo_vendor #(
	parameter WIDTH = 8,
	parameter DEPTH = 2048,
	parameter [0:0] REGOUT = 0

)(

	input clk,
	input rst,

	output 						full,
	output 						empty,
	output [$clog2(DEPTH):0] 	dcnt,

	input [WIDTH-1:0] 			din,
	input 						wr_en,

	output [WIDTH-1:0] 			dout,
	input 						rd_en


);
	// ------------------------------------------------
	// Instantiate vendor dependent module/macro here
	// ------------------------------------------------
	xpm_fifo_sync #(
		.DOUT_RESET_VALUE("0"),    // String
		.ECC_MODE("no_ecc"),       // String
		.FIFO_MEMORY_TYPE("auto"), // String
		.FIFO_READ_LATENCY(1),     // DECIMAL
		.FIFO_WRITE_DEPTH(DEPTH),   // DECIMAL
		.FULL_RESET_VALUE(0),      // DECIMAL
		.PROG_EMPTY_THRESH(10),    // DECIMAL
		.PROG_FULL_THRESH(10),     // DECIMAL
		.RD_DATA_COUNT_WIDTH(1),   // DECIMAL
		.READ_DATA_WIDTH(WIDTH),      // DECIMAL
		.READ_MODE("fwft"),         // String
		.SIM_ASSERT_CHK(0),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
		.USE_ADV_FEATURES("0707"), // String
		.WAKEUP_TIME(0),           // DECIMAL
		.WRITE_DATA_WIDTH(WIDTH),     // DECIMAL
		.WR_DATA_COUNT_WIDTH(1)    // DECIMAL
	)
	xpm_fifo_sync_inst (
		.almost_empty(almost_empty),
		.almost_full(almost_full),
		.data_valid(data_valid),
		.dout(dout),
		.empty(empty),
		.full(full),
		.overflow(overflow),
		.prog_empty(prog_empty),
		.prog_full(prog_full),
		.rd_data_count(rd_data_count),
		.rd_rst_busy(rd_rst_busy),
		.underflow(underflow),
		.wr_data_count(wr_data_count),
		.wr_rst_busy(wr_rst_busy),
		.din(din),
		.injectdbiterr(0),
		.injectsbiterr(0),
		.rd_en(rd_en),
		.rst(rst),
		.sleep(0),
		.wr_clk(clk),
		.wr_en(wr_en)
	);
	// ------------------------------------------------


endmodule
