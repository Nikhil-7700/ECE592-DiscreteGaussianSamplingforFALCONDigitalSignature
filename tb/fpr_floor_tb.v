module fpr_floor_tb;

    reg clk, rst, start;
    reg [63:0] input_a;
    wire [63:0] output_z;
    wire done;

    // Instantiate the DUT
    fpr_floor uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(input_a),
        .result(output_z),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Generate a 10 ns clock period
    end

    // Test cases
    initial begin
        // Display start of the simulation
        $display("Starting Testbench for fpr_floor_seq");

        // Reset the DUT
        rst = 1;
        start = 0;
        input_a = 64'b0;
        #10 rst = 0;

        // Test Case 1: Floor(4.75)
        input_a = 64'h4013C00000000000; // 4.75 in IEEE 754 double-precision
        start = 1;
        #10 start = 0; // Deassert start after one clock cycle
        wait(done);    // Wait for the operation to complete
        #10;
        $display("Test Case 1: Input: %h, Output (Expected 4.0 = 64'h4010000000000000): 64'h%h", input_a, output_z);

        // Test Case 2: Floor(-4.75)
        input_a = 64'hC013C00000000000; // -4.75 in IEEE 754 double-precision
        start = 1;
        #10 start = 0;
        wait(done);
        #10;
        $display("Test Case 2: Input: %h, Output (Expected -5.0 = 64'hC014000000000000): 64'h%h", input_a, output_z);

        // Test Case 3: Floor(0.5)
        input_a = 64'h3FE0000000000000; // 0.5 in IEEE 754 double-precision
        start = 1;
        #10 start = 0;
        wait(done);
        #10;
        $display("Test Case 3: Input: %h, Output (Expected 0.0): 64'h%h", input_a, output_z);

        // Test Case 4: Floor(Inf)
        input_a = 64'h7FF0000000000000; // +Infinity in IEEE 754 double-precision
        start = 1;
        #10 start = 0;
        wait(done);
        #10;
        $display("Test Case 4: Input: %h, Output (Expected Inf): 64'h%h", input_a, output_z);

        // Test Case 5: Floor(NaN)
        input_a = 64'h7FF8000000000000; // NaN in IEEE 754 double-precision
        start = 1;
        #10 start = 0;
        wait(done);
        #10;
        $display("Test Case 5: Input: %h, Output (Expected NaN): 64'h%h", input_a, output_z);

        // Test Case 6: Floor(-0.75)
        input_a = 64'hBFE8000000000000; // -0.75 in IEEE 754 double-precision
        start = 1;
        #10 start = 0;
        wait(done);
        #10;
        $display("Test Case 6: Input: %h, Output (Expected -1.0 = 64'hBFF0000000000000): 64'h%h", input_a, output_z);

        // End simulation
        $finish;
    end

endmodule
