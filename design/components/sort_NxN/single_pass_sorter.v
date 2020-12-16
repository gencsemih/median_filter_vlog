








module single_pass_sorter #(
    parameter N = 5,
    parameter DATA_WIDTH = 8

    )(
    input [N*DATA_WIDTH-1:0] data,
    output [N*DATA_WIDTH-1:0] single_pass
    );


    wire [DATA_WIDTH-1:0] n [0:N-1];

    wire [DATA_WIDTH-1:0] g [0:N-2];
    wire [DATA_WIDTH-1:0] s [0:N-1];

    generate
        genvar j;
        for(j=0; j<N; j=j+1) begin
            assign n[j] = data[(N-j)*DATA_WIDTH-1 -: DATA_WIDTH];
            assign single_pass[(N-j)*DATA_WIDTH-1 -: DATA_WIDTH] = s[j];
        end
    endgenerate;



    comparator #(DATA_WIDTH) COMP[0:0] (.data({n[0], n[1]}), .smaller(s[0]), .greater(g[0]));
    assign s[N-1] = g[N-2];
    generate
        genvar i;
        for(i=1; i<N-1; i=i+1) begin
            comparator #(DATA_WIDTH) COMP[i:i] (.data({g[i-1], n[i+1]}), .smaller(s[i]), .greater(g[i]));
        end
    endgenerate;



endmodule
