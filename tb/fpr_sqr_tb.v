module fpr_sqr_tb;

    reg [63:0] input_a;           // Input A
    //reg [63:0] input_b;           // Input B
    reg clk;                      // Clock signal
    reg rst;                      // Reset signal
    reg start;                    // Start signal
    wire [63:0] output_z;         // Output (result)
    wire done;                    // Done signal

    // Instantiate the DUT
    fpr_sqr uut (
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
        $display("Starting Testbench for Multiplication");
        rst = 1;
        start = 0;
        input_a = 64'b0;
        //input_b = 64'b0;
        #10 rst = 0; // Deassert reset

        // Test Case 1: 4.8883 ^ 2
        input_a = 64'h40138D9E83E425AF; // 4.8883
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 1: sqr(4.8883)");
        $display("Input A: %h", input_a);
        //$display("Input B: %h", input_b);
        $display("Output Z (Expected 23.89547689 - 64'h4037E53DF934DFB1): 64'h%h", output_z);

        // Test Case 2: -4.8883
        input_a = 64'hC0138D9E83E425AF; // -4.8883
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 2: sqr(-4.8883)");
        $display("Input A: %h", input_a);
        $display("Output Z (Expected 23.89547689 - 64'h4037E53DF934DFB1): 64'h%h", output_z);

        // Test Case 3: -0
        input_a = 64'h8000000000000000; // 0
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 3: sqr(-0)");
        $display("Input A: %h", input_a);
        $display("Output Z (Expected 0): 64'h%h", output_z);

        // Test Case 4: Inf
        input_a = 64'h7FF0000000000000; // +Infinity
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case sqr(Inf)");
        $display("Input A: %h", input_a);
        $display("Output Z (Expected Inf): 64'h%h", output_z);

        // Test Case 5: Inf × -3.674
        input_a = 64'hFFF0000000000000; // -Infinity
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 5: sqr(-Inf)");
        $display("Input A: %h", input_a);
        $display("Output Z (Expected Inf): 64'h%h", output_z);

        // Test Case 6: -Inf × -3.674
        input_a = 64'h7FF800060000A020; // NaN
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 6: NaN");
        $display("Input A: %h", input_a);
        $display("Output Z (Expected NaN): 64'h%h", output_z);

        //Test Case 7: 2.236E-162
        input_a = 64'h3B4E392010175EE6; // 5E-23
        start = 1;
        #10 start = 0;
        wait(done == 1);
		#10;
        $display("\nTest Case 7: 5E-23");
        $display("Input A: %h", input_a);
        $display("Output Z (Expected 2.5E-45 - 64'h36AC8B8218854568): 64'h%h", output_z);

        // End simulation
        $finish;
    end

endmodule
