

/*
Author: Semih GENC
Description : NxN window matrix sorter
Version : 1.00
*/


module sort_NxN #(
    parameter SIZE = 3,
    parameter DATA_WIDTH = 8
    )(

    input clk,
    input rstb,

    input valid,
    input [SIZE*SIZE*DATA_WIDTH-1:0] data,
    output reg [DATA_WIDTH-1:0] median
    );



    wire [SIZE*SIZE*DATA_WIDTH-1:0] hor_sorted_data;
    wire [SIZE*SIZE*DATA_WIDTH-1:0] trn_sorted_data;
    wire [SIZE*SIZE*DATA_WIDTH-1:0] ver_sorted_data;
    wire [SIZE*DATA_WIDTH-1:0] dia_data;

    reg [SIZE*SIZE*DATA_WIDTH-1:0] hor_sorted_data_reg;
    reg [SIZE*SIZE*DATA_WIDTH-1:0] trn_sorted_data_reg;
    reg [SIZE*SIZE*DATA_WIDTH-1:0] ver_sorted_data_reg;
    reg [SIZE*DATA_WIDTH-1:0] dia_data_reg;

    wire [SIZE*DATA_WIDTH-1:0] dia_sorted_data;

    genvar i;

    // Horizontal Sorting
    // Sort every line along horizontal axis
    generate
        for(i=0;i<SIZE;i=i+1) begin : HOR_SORTING_GEN
            sort_N #(SIZE, DATA_WIDTH) HOR_SORT[i:i] ( .valid(valid), .data(data[SIZE*i*DATA_WIDTH +: SIZE*DATA_WIDTH]), .sorted_data(hor_sorted_data[SIZE*i*DATA_WIDTH +: SIZE*DATA_WIDTH]));
        end
    endgenerate


    // Vertical Sorting
    // To sort vertically, first take transpose and then sort every line horizontally
    transpose_NxN #(SIZE, DATA_WIDTH) TRANSPOSE ( .data(hor_sorted_data_reg), .transposed(trn_sorted_data));
    generate
        for(i=0;i<SIZE;i=i+1) begin : VER_SORTING_GEN
            sort_N #(SIZE, DATA_WIDTH) VER_SORT[i:i] ( .valid(valid), .data(trn_sorted_data_reg[SIZE*i*DATA_WIDTH +: SIZE*DATA_WIDTH]), .sorted_data(ver_sorted_data[SIZE*i*DATA_WIDTH +: SIZE*DATA_WIDTH]));
        end
    endgenerate

    // Diagonal Sorting
    dia_data_NxN #(SIZE, DATA_WIDTH) DIA_DATA( .data(ver_sorted_data_reg), .dia_data(dia_data));
    sort_N #(SIZE, DATA_WIDTH) DIA_SORT ( .data(dia_data_reg), .valid(valid), .sorted_data(dia_sorted_data));


    // Register each stage
    always @(posedge clk) begin
        hor_sorted_data_reg <= hor_sorted_data;
        trn_sorted_data_reg <= trn_sorted_data;
        ver_sorted_data_reg <= ver_sorted_data;
        dia_data_reg <= dia_data;
        median <= dia_sorted_data[((SIZE+1)/2)*DATA_WIDTH-1 -: DATA_WIDTH];
    end




endmodule
