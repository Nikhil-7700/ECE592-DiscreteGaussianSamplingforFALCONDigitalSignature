module fpr_sub_tb;

    reg [63:0] input_a;           // Input A
    reg [63:0] input_b;           // Input B
    reg clk;                      // Clock signal
    reg rst;                      // Reset signal
    reg start;                    // Start signal
    wire [63:0] output_z;         // Output (result)
    wire done;                    // Done signal

    // Instantiate the DUT
    fpr_sub uut (
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

    // Test case
    initial begin
        // Display start of the test
        $display("Starting Testbench: Testing subtraction of 4.8883 - 3.674");

        // Reset the DUT
        rst = 1;
        start = 0;
        input_a = 64'b0;
        input_b = 64'b0;
        #10 rst = 0; // Deassert reset

        /////////////////////////////// Test 1 ///////////////////////////////
        input_a = 64'h40138D9E83E425AF; // 4.8883 in double-precision
        input_b = 64'h400D645A1CAC0831; // 3.674 in double-precision
        start = 1; // Start the calculation
        #10 start = 0; // Deassert start after one clock cycle

        // Wait for done signal
        wait(done == 1);
        #10; // Small delay to allow output_z to stabilize

        // Display result
        $display("Test result:");
        $display("Input A (4.8883): %h", input_a);
        $display("Input B (3.674): %h", input_b);
        $display("Output Z (Expected 1.2143 - 64'h3FF36DC5D638865A): %h", output_z);
		
		/////////////////////////////// Test 2 ///////////////////////////////
        input_a = 64'h40138D9E83E425AF; // 4.8883 in double-precision
        input_b = 64'hC00D645A1CAC0831; // -3.674 in double-precision
        start = 1; // Start the calculation
        #10 start = 0; // Deassert start after one clock cycle

        // Wait for done signal
        wait(done == 1);
        #10; // Small delay to allow output_z to stabilize
		
		// Display result
        $display("Test result:");
        $display("Input A (4.8883): %h", input_a);
        $display("Input B (-3.674): %h", input_b);
        $display("Output Z (Expected 8.5623 - 64'h40211FE5C91D14E4): %h", output_z);
		
		/////////////////////////////// Test 3 ///////////////////////////////
        input_a = 64'hC0138D9E83E425AF; // -4.8883 in double-precision
        input_b = 64'hC00D645A1CAC0831; // -3.674 in double-precision
        start = 1; // Start the calculation
        #10 start = 0; // Deassert start after one clock cycle

        // Wait for done signal
        wait(done == 1);
        #10; // Small delay to allow output_z to stabilize
		
		// Display result
        $display("Test result:");
        $display("Input A (-4.8883): %h", input_a);
        $display("Input B (-3.674): %h", input_b);
        $display("Output Z (Expected -1.2143 - 64'hBFF36DC5D638865A): %h", output_z);
		
		/////////////////////////////// Test 4 ///////////////////////////////
        input_a = 64'h40138D9E83E425AF; // 4.8883 in double-precision
        input_b = 64'h0000000000000000; // 0 in double-precision
        start = 1; // Start the calculation
        #10 start = 0; // Deassert start after one clock cycle

        // Wait for done signal
        wait(done == 1);
        #10; // Small delay to allow output_z to stabilize
		
		// Display result
        $display("Test result:");
        $display("Input A (4.8883): %h", input_a);
        $display("Input B (0): %h", input_b);
        $display("Output Z (Expected 4.8883 - 64'h40138D9E83E425AF): %h", output_z);
		
		/////////////////////////////// Test 5 ///////////////////////////////
        input_a = 64'h8000000000000000; // -0.0 in double-precision
        input_b = 64'hC00D645A1CAC0831; // -3.674 in double-precision
        start = 1; // Start the calculation
        #10 start = 0; // Deassert start after one clock cycle

        // Wait for done signal
        wait(done == 1);
        #10; // Small delay to allow output_z to stabilize
		
		// Display result
        $display("Test result:");
        $display("Input A (0): %h", input_a);
        $display("Input B (-3.674): %h", input_b);
        $display("Output Z (Expected 3.674 - 64'h400D645A1CAC0831): %h", output_z);
		
		/////////////////////////////// Test 6 ///////////////////////////////
        input_a = 64'h7FF0000000000000; // Inf in double-precision
        input_b = 64'hC00D645A1CAC0831; // -3.674 in double-precision
        start = 1; // Start the calculation
        #10 start = 0; // Deassert start after one clock cycle

        // Wait for done signal
        wait(done == 1);
        #10; // Small delay to allow output_z to stabilize
		
		// Display result
        $display("Test result:");
        $display("Input A (Inf): %h", input_a);
        $display("Input B (-3.674): %h", input_b);
        $display("Output Z (Expected Inf): %h", output_z);
		
		/////////////////////////////// Test 7 ///////////////////////////////
        input_a = 64'h7FF8000000000000; // NaN in double-precision
        input_b = 64'hC00D645A1CAC0831; // -3.674 in double-precision
        start = 1; // Start the calculation
        #10 start = 0; // Deassert start after one clock cycle

        // Wait for done signal
        wait(done == 1);
        #10; // Small delay to allow output_z to stabilize
		
		// Display result
        $display("Test result:");
        $display("Input A (NaN): %h", input_a);
        $display("Input B (-3.674): %h", input_b);
        $display("Output Z (Expected NaN): %h", output_z);
		
	/////////////////////////////// Test 8 ///////////////////////////////
        input_a = 64'h3B4E392010175EE6; // 5E-23 in double-precision
        input_b = 64'h3B482DB34012B251; // 4E-23 in double-precision
        start = 1; // Start the calculation
        #10 start = 0; // Deassert start after one clock cycle

        // Wait for done signal
        wait(done == 1);
        #10; // Small delay to allow output_z to stabilize

                // Display result
        $display("Test result:");
        $display("Input A (5E-23): %h", input_a);
        $display("Input B (4E-23): %h", input_b);
        $display("Output Z (Expected 1E-23 = 64'h3B282DB34012B254): 64'h%h", output_z);
		
		
		
		

        // End simulation
        $finish;
    end

endmodule
