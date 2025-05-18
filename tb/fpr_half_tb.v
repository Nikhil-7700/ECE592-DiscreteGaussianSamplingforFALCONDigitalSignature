module fpr_half_tb;

    reg [63:0] input_a;           // Input A
    //reg [63:0] input_b;           // Input B
    reg clk;                      // Clock signal
    reg rst;                      // Reset signal
    reg start;                    // Start signal
    wire [63:0] output_z;         // Output (result)
    wire done;                    // Done signal

    // Instantiate the DUT
    fpr_half uut (
        .input_a(input_a),
        //.input_b(input_b),
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
        $display("Starting Testbench for Half");
        rst = 1;
        start = 0;
        input_a = 64'b0;
        //input_b = 64'b0;
        #10 rst = 0; // Deassert reset

        // Test Case 1
        input_a = 64'h40138D9E83E425AF; // 4.8883
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 1: 4.8883 / 2 ");
        $display("Input A: %h", input_a);
        $display("Output Z (Expected 2.44415 = 64'h40038D9E83E425AF): 64'h%h", output_z);

        // Test Case 2: -4.8883
        input_a = 64'hC0138D9E83E425AF; // -4.8883
        //input_b = 64'h400D645A1CAC0831; // 3.674
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 2: -4.8883 / 2)");
        $display("Input A: %h", input_a);
        $display("Output Z (Expected -2.44415 = 64'hC0038D9E83E425AF): 64'h%h", output_z);

        // Test Case 3: -222.688496
        input_a = 64'hC06BD60828C36DA8; // -222.688496
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 3: -222.688496 / 2");
        $display("Input A: %h", input_a);
        $display("Output Z (Expected -111.344248 = 64'hC05BD60828C36DA8): 64'h%h", output_z);

        // Test Case 4: 7
        input_a = 64'h401C000000000000; // 7
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 7 / 2)");
        $display("Input A: %h", input_a);
        $display("Output Z (Expected 3.5 = 64'h400C000000000000): 64'h%h", output_z);

        // Test Case 5: Inf × -14
        input_a = 64'hC02C000000000000; // -14
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 5: -14 / 2)");
        $display("Input A: %h", input_a);
        //$display("Input B: %h", input_b);
        $display("Output Z (Expected -7 = 64'hC01C000000000000): 64'h%h", output_z);

        // Test Case 6:
        input_a = 64'h7FF800060000A020; // NaN
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 6: NaN");
        $display("Input A: %h", input_a);
        $display("Output Z (Expected NaN): %h", output_z);

        //Test Case 7
        input_a = 64'hFFF0000000000000; // -Infinity
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 7: -Inf / 2");
        $display("Input A: %h", input_a);
        $display("Output Z (Expected -Inf): 64'h%h", output_z);
		
		//Test Case 8: 4.358641530584E-311
        input_a = 64'h0000080607804002; // 4.358641530584E-311
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 7: 4.358641530584E-311 / 2");
        $display("Input A: %h", input_a);
        $display("Output Z (Expected 2.179320765292E-311 = 64'h0000040303C02001): %h", output_z);
		
		//Test Case 9: -4.358641530584E-311
        input_a = 64'h8000080607804002; // -4.358641530584E-311
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 7: -4.358641530584E-311");
        $display("Input A: %h", input_a);
        $display("Output Z (Expected -2.179320765292E-311 = 64'h8000040303C02001): %h", output_z);

        // End simulation
        $finish;
    end

endmodule
