

/*
Author: Semih GENC
Description : N-length data sorter
Version : 1.00
*/


module sort_N #(
    parameter N=5,
    parameter DATA_WIDTH = 8
    )(


    input [N*DATA_WIDTH-1:0] data,
    input valid,
    output [N*DATA_WIDTH-1:0] sorted_data

    );


    wire [DATA_WIDTH-1:0] n [0:N-1];
    reg [DATA_WIDTH-1:0] s [0:N-1];

    integer i;
    integer j;

    generate
        genvar g;
        for(g=0; g<N; g=g+1) begin :sorted_output_gen
            assign n[g] = data[(N-g)*DATA_WIDTH-1 -: DATA_WIDTH];
            //assign sorted_data[(N-g)*DATA_WIDTH-1 -: DATA_WIDTH] = s[g];
        end
    endgenerate


    wire [(N+1)*DATA_WIDTH-1:0] single_pass_stages[0:N-1];
    assign single_pass_stages[0] = {data, {DATA_WIDTH{1'b0}}};
    assign sorted_data[(N-1)*DATA_WIDTH +: DATA_WIDTH] = single_pass_stages[N-1][DATA_WIDTH +: DATA_WIDTH];
    generate
        genvar h;
        for(h=0; h<N-1; h=h+1) begin :single_pass_stage_gen
            assign sorted_data[h*DATA_WIDTH +: DATA_WIDTH] = single_pass_stages[h+1][0 +: DATA_WIDTH];
            single_pass_sorter #(N-h, DATA_WIDTH) SPS[h:h] ( .data(single_pass_stages[h][(N-h+1)*DATA_WIDTH-1:DATA_WIDTH]), .single_pass(single_pass_stages[h+1][(N-h)*DATA_WIDTH-1:0]));
        end
    endgenerate




endmodule
