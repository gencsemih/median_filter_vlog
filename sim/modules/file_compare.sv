

/*
Author: Semih GENC
Description : Compares two files and outputs the result
Version : 1.00
*/


module file_compare #(
	parameter ISSUE_MESSAGES = 0
)(

	input string file_path_1,
	input string file_path_2,

	input check,
	output reg result


);

localparam ARRAY_SIZE = 2048 * 2048;


integer file_1;
integer file_2;

integer r_1;
integer r_2;
integer i;


reg [7:0] array_1 [0:ARRAY_SIZE-1];
reg [7:0] array_2 [0:ARRAY_SIZE-1];

always @(posedge check) begin
	// Open files for read
	file_1 = $fopen(file_path_1,"rb");
	file_2 = $fopen(file_path_2,"rb");


	// Check if files are opened properly
	assert (file_1 != 0) begin
		if(ISSUE_MESSAGES) $display("FILE_1 is opened successfully");
	end
	else begin
		$error("input file %s could not be opened,",file_path_1);
	end

	assert (file_2 != 0) begin
		if(ISSUE_MESSAGES) $display("FILE_2 is opened successfully");
	end	else begin
	 	$error("input file %s could not be opened,",file_path_2);
	end

	r_1 = $fread(array_1, file_1);
	r_2 = $fread(array_2, file_2);
	$fclose(file_1);
	$fclose(file_2);

	result = 0;
	for(i=0; i<r_1; i=i+1) begin
		if(array_1[i] != array_2[i]) begin
			result = 1;
			break;
		end
	end

	$fclose(file_1);
	$fclose(file_2);


end







endmodule
