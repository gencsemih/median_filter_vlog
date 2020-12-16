







module comparator #(
    parameter DATA_WIDTH=8
    )(

    input [2*DATA_WIDTH-1:0] data,
    output [DATA_WIDTH-1:0] greater,
    output [DATA_WIDTH-1:0] smaller
    );

    wire [DATA_WIDTH-1:0] data_1;
    wire [DATA_WIDTH-1:0] data_2;
    wire gt;

    assign data_1 = data[2*DATA_WIDTH-1:DATA_WIDTH];
    assign data_2 = data[DATA_WIDTH-1:0];
    assign gt = (data_1 > data_2);

    assign greater = gt ? data_1 : data_2;
    assign smaller = gt ? data_2 : data_1;



endmodule
