module fpr_mul_tb;

    reg [63:0] input_a;           // Input A
    reg [63:0] input_b;           // Input B
    reg clk;                      // Clock signal
    reg rst;                      // Reset signal
    reg start;                    // Start signal
    wire [63:0] output_z;         // Output (result)
    wire done;                    // Done signal

    // Instantiate the DUT
    fpr_mul uut (
        .input_a(input_a),
        .input_b(input_b),
        .clk(clk),
        .rst(rst),
        .start(start),
        .output_z(output_z),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns clock period
    end

    // Test cases
    initial begin
        // Reset the DUT
        $display("Starting Testbench for Multiplication");
        rst = 1;
        start = 0;
        input_a = 64'b0;
        input_b = 64'b0;
        #10 rst = 0; // Deassert reset

        // Test Case 1: 4.8883 × 3.674
        input_a = 64'h40138D9E83E425AF; // 4.8883
        input_b = 64'h400D645A1CAC0831; // 3.674
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 1: 4.8883 × 3.674");
        $display("Input A: %h", input_a);
        $display("Input B: %h", input_b);
        $display("Output Z (Expected 17.9596142): %h", output_z);

        // Test Case 2: -4.8883 × 3.674
        input_a = 64'hC0138D9E83E425AF; // -4.8883
        input_b = 64'h400D645A1CAC0831; // 3.674
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 2: -4.8883 × 3.674");
        $display("Input A: %h", input_a);
        $display("Input B: %h", input_b);
        $display("Output Z (Expected -17.9596142): %h", output_z);

        // Test Case 3: -4.8883 × -3.674
        input_a = 64'hC0138D9E83E425AF; // -4.8883
        input_b = 64'hC00D645A1CAC0831; // -3.674
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 3: -4.8883 × -3.674");
        $display("Input A: %h", input_a);
        $display("Input B: %h", input_b);
        $display("Output Z (Expected 17.9596142): %h", output_z);

        // Test Case 4: 4.8883 × 0
        input_a = 64'h40138D9E83E425AF; // 4.8883
        input_b = 64'h0000000000000000; // 0
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 4: 4.8883 × 0");
        $display("Input A: %h", input_a);
        $display("Input B: %h", input_b);
        $display("Output Z (Expected 0): %h", output_z);

        // Test Case 5: Inf × -3.674
        input_a = 64'h7FF0000000000000; // +Infinity
        input_b = 64'hC00D645A1CAC0831; // -3.674
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 5: +Inf × -3.674");
        $display("Input A: %h", input_a);
        $display("Input B: %h", input_b);
        $display("Output Z (Expected -Inf): %h", output_z);

        // Test Case 6: -Inf × -3.674
        input_a = 64'hFFF0000000000000; // -Infinity
        input_b = 64'hC00D645A1CAC0831; // -3.674
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 6: -Inf × -3.674");
        $display("Input A: %h", input_a);
        $display("Input B: %h", input_b);
        $display("Output Z (Expected +Inf): %h", output_z);

        // Test Case 7: NaN × 3.674
        input_a = 64'h7FF8000000000000; // NaN
        input_b = 64'h400D645A1CAC0831; // 3.674
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 7: NaN × 3.674");
        $display("Input A: %h", input_a);
        $display("Input B: %h", input_b);
        $display("Output Z (Expected NaN): %h", output_z);
		
		// Test Case 8
        input_a = 64'h3B4E392010175EE6; // 5E-23
        input_b = 64'h3B4E392010175EE6; // 5E-23
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 8: 5E-23 × 5E-23");
        $display("Input A: %h", input_a);
        $display("Input B: %h", input_b);
        $display("Output Z (Expected 36AC8B8218854568): %h", output_z);

	// Test Case 9: 4.8883 × 3
        input_a = 64'h40138D9E83E425AF; // 4.8883
        input_b = 64'h4008000000000000; // 3
        start = 1;
        #10 start = 0;
        wait(done == 1);
                #10;
        $display("\nTest Case 1: 4.8883 × 3");
        $display("Input A: %h", input_a);
        $display("Input B: %h", input_b);
        $display("Output Z (Expected 14.6649 = 64'h402D546DC5D63886): 64'h%h", output_z);

        // End simulation
        $finish;
    end

endmodule
