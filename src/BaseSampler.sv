module BaseSampler (
    input wire clk,
    input wire rst,
    input wire [71:0] u, // 72-bit random number
    output reg [31:0] data_out // 32-bit output
);


    parameter [71:0] dist_0 =  72'hA3F7F42ED3AC391802;
    parameter [71:0] dist_1 =  72'h54D32B181F3F7DDB82;
    parameter [71:0] dist_2 =  72'h227DCDD0934829C1FF;
    parameter [71:0] dist_3 =  72'h0AD1754377C7994AE4;
    parameter [71:0] dist_4 =  72'h0295846CAEF33F1F6F;
    parameter [71:0] dist_5 =  72'h00774AC754ED74BD5F;
    parameter [71:0] dist_6 =  72'h001024DD542B776AE4;
    parameter [71:0] dist_7 =  72'h0001A1FFDC65AD63DA;
    parameter [71:0] dist_8 =  72'h00001F80D88A7B6428;
    parameter [71:0] dist_9 =  72'h000001C3FDB2040C69;
    parameter [71:0] dist_10 = 72'h00000012CF24D031FB;
    parameter [71:0] dist_11 = 72'h00000000949F8B091F;
    parameter [71:0] dist_12 = 72'h0000000003665DA998;
    parameter [71:0] dist_13 = 72'h0000000000EBF6EBB;
    parameter [71:0] dist_14 = 72'h00000000002F5D7E;
    parameter [71:0] dist_15 = 72'h0000000000007098;
    parameter [71:0] dist_16 = 72'h000000000000000;
    parameter [71:0] dist_17 = 72'h000000000000001;

    // Create a temporary variable to store the result of the comparison
    reg [17:0] z;
    integer i;
    
    always@(*) begin
        z[0] = u < dist_0;
        z[1] = u < dist_1;
        z[2] = u < dist_2;
        z[3] = u < dist_3;
        z[4] = u < dist_4;
        z[5] = u < dist_5;
        z[6] = u < dist_6;
        z[7] = u < dist_7;
        z[8] = u < dist_8;
        z[9] = u < dist_9;
        z[10] = u < dist_10;
        z[11] = u < dist_11;
        z[12] = u < dist_12;
        z[13] = u < dist_13;
        z[14] = u < dist_14;
        z[15] = u < dist_15;
        z[16] = u < dist_16;
        z[17] = u < dist_17;
    end

    // Count the number of elements in each range
    reg [3:0] CountZ0to8;
    reg [3:0] CountZ9to17;

    always@(*) begin
        CountZ0to8 = ((z[0] + z[1]) + (z[2] + z[3])) + ((z[4] + z[5]) + (z[6] + z[7]) + (z[8]));
        CountZ9to17 = ((z[9] + z[10]) + (z[11] + z[12])) + ((z[13] + z[14]) + ((z[15] + z[16]) + z[17]));
    end

    // Sum the counts from all ranges to get the final result
    always@(*) begin
        data_out = {28'd0, CountZ0to8 + CountZ9to17};
    end

endmodule