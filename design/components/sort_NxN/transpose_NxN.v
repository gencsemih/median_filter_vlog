








module transpose_NxN #(
    parameter SIZE = 3,
    parameter DATA_WIDTH = 8
    )(

    input [SIZE*SIZE*DATA_WIDTH-1:0] data,
    output [SIZE*SIZE*DATA_WIDTH-1:0] transposed
    );


    // Separate input data into lines
    wire [DATA_WIDTH-1:0] cells [0:SIZE-1][0:SIZE-1];

    // Extract lines from data
    // Put sorted lines to sorted data
    genvar i;
    genvar j;
    generate
    for(i=0; i<SIZE; i=i+1) begin
        for(j=0; j<SIZE; j=j+1) begin
        //assign cells[i][j] = data[SIZE*(SIZE-i)*DATA_WIDTH-1 -: SIZE*DATA_WIDTH];
            assign cells[i][j] = data[SIZE*(SIZE-i)*DATA_WIDTH- (j*DATA_WIDTH) - 1 -: DATA_WIDTH];
            assign transposed[SIZE*(SIZE-i)*DATA_WIDTH- (j*DATA_WIDTH) - 1 -: DATA_WIDTH] = cells[j][i];
        end
    end
    endgenerate













endmodule
