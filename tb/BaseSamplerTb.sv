`timescale 1ns/1ps
`include "../src/BaseSampler.sv"
`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal %h != value %h", signal, value); \
            $finish; \
        end

module BaseSamplerTb;
    logic [71:0] u, value1;
    wire [31:0] data_o;
    logic [31:0] value2;
    logic clk;
    logic rst;
    integer file, r; 

    // Clock generation
    always #5 clk = ~clk;

    BaseSampler u_BaseSampler(.u(u), .data_out(data_o), .clk(clk), .rst(rst));

    initial begin
        clk = 0;
        rst = 1;
        #10 rst = 0;
        #10;
        // Open the file for reading
        file = $fopen("BaseSamplerTb.txt", "r");
        if (file == 0) begin
        $display("Failed to open the file");
        $finish;
        end

        // Read values line by line
        while (!$feof(file)) begin
            r = $fscanf(file, "%h %h\n", value1, value2);  // Read two hex values from each line
            if (r == 2) begin  // Ensure both values were read
                $display("Read: value1 = %h, value2 = %h", value1, value2);
            
            end
            u = value1;
            #10;
            $display("z = %h", u_BaseSampler.z);
            // assert the data_out
            `assert(data_o, value2);
            
        end

        // Close the file
        $fclose(file);
    end
endmodule