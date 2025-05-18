module fpr_toInt_tb;

    reg clk, rst, start;
    reg [63:0] input_a;
    wire [63:0] result;
    wire invalid, done;

    // Instantiate the DUT
    fpr_toInt uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .input_a(input_a),
        .result(result),
        .invalid(invalid),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Generate a 10 ns clock period
    end

    // Test cases
    initial begin
        $display("Starting Testbench for fpu_to_int_seq");

        // Reset the DUT
        rst = 1;
        start = 0;
        input_a = 64'b0;
        #10 rst = 0;

        // Test Case 1: Convert 4.5 to integer
        input_a = 64'h4012000000000000; // 4.5
        start = 1; #10 start = 0; wait(done); #10;
        $display("Test 1: Input: %h, Result: %d, Invalid: %b", input_a, $signed(result), invalid);

        // Test Case 2: Convert -8.0 to integer
        input_a = 64'hC020000000000000; // -8.0
        start = 1; #10 start = 0; wait(done); #10;
        $display("Test 2: Input: %h, Result: %d, Invalid: %b", input_a, $signed(result), invalid);

	// Test Case 3: Convert 8.0 to integer
        input_a = 64'h4020000000000000; // 8.0
        start = 1; #10 start = 0; wait(done); #10;
        $display("Test 3: Input: %h, Result: %d, Invalid: %b", input_a, $signed(result), invalid);

	// Test Case 4: Convert -8.7 to integer
        input_a = 64'hC021666666666666; // -8.7
        start = 1; #10 start = 0; wait(done); #10;
        $display("Test 4: Input: %h, Result: %d, Invalid: %b", input_a, $signed(result), invalid);

        // Test Case 5: Convert Infinity
        input_a = 64'h7FF0000000000000; // +Infinity
        start = 1; #10 start = 0; wait(done); #10;
        $display("Test 5: Input: %h, Result: %d, Invalid: %b", input_a, $signed(result), invalid);

        // Test Case 6: Convert NaN
        input_a = 64'h7FF8000000000000; // NaN
        start = 1; #10 start = 0; wait(done); #10;
        $display("Test 6: Input: %h, Result: %d, Invalid: %b", input_a, $signed(result), invalid);

        // Test Case 7: Convert 0.0 to integer
        input_a = 64'h0000000000000000; // 0.0
        start = 1; #10 start = 0; wait(done); #10;
        $display("Test 7: Input: %h, Result: %d, Invalid: %b", input_a, $signed(result), invalid);

	// Test Case 8: Convert 0.5 to integer
        input_a = 64'h3FE0000000000000; // 0.5
        start = 1; #10 start = 0; wait(done); #10;
        $display("Test 8: Input: %h, Result: %d, Invalid: %b", input_a, $signed(result), invalid);

	// Test Case 9: Convert 0.5 to integer
        input_a = 64'hBFE0000000000000; // -0.5
        start = 1; #10 start = 0; wait(done); #10;
        $display("Test 9: Input: %h, Result: %d, Invalid: %b", input_a, $signed(result), invalid);

        $finish;
    end

endmodule

