`timescale 1ns/1ps
`include "../src/double_multiplier.v"

module double_multiplierTb();

    reg clk;
    reg rst;

    reg [63:0] input_a;
    reg input_a_stb;
    wire input_a_ack;

    reg [63:0] input_b;
    reg input_b_stb;
    wire input_b_ack;

    wire [63:0] output_z;
    wire output_z_stb;
    reg output_z_ack;

    // Test variables
    integer file, status;
    integer test_count;
    integer timeout_count;
    parameter TIMEOUT_LIMIT = 1000;
    reg [63:0] expected_output;
    reg done;
    
    double_multiplier double_multiplier_inst (
        .input_a(input_a),
        .input_b(input_b),
        .input_a_stb(input_a_stb),
        .input_b_stb(input_b_stb),
        .output_z_ack(output_z_ack),
        .clk(clk),
        .rst(rst),
        .output_z(output_z),
        .output_z_stb(output_z_stb),
        .input_a_ack(input_a_ack),
        .input_b_ack(input_b_ack)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Initialize signals
        rst = 1;
        #10 rst = 0;

        input_a = 64'h0;
        input_b = 64'h0;
        input_a_stb = 0;
        input_b_stb = 0;
        output_z_ack = 0;
        test_count = 0;
        done = 0;

        // Open test vector file
        file = $fopen("double_multiplierTb.txt", "r");
        if (file == 0) begin
            $display("Error: Could not open test vector file");
            $finish;
        end
        $display("Test file opened successfully");

        $display("Time=%0t: Reset deasserted", $time);

        // Wait a few clock cycles after reset
        repeat(5) @(posedge clk);
        
        while (!$feof(file) && !done) begin
            test_count = test_count + 1;
            
            // Read input and expected output from file
            status = $fscanf(file, "%h %h %h", input_a, input_b, expected_output);
            if (status == 3) begin  // Valid data read
                $display("\n=== Test Vector %0d ===", test_count);
                $display("Input A (hex): %h", input_a);
                $display("Input B (hex): %h", input_b);
                $display("Expected output (hex): %h", expected_output);

                // Apply input A
                @(negedge clk);
                input_a_stb = 1;
                
                // Wait for input A acknowledge with timeout
                timeout_count = 0;
                while (!input_a_ack && timeout_count < TIMEOUT_LIMIT) begin
                    @(posedge clk);
                    timeout_count = timeout_count + 1;
                end
                
                if (timeout_count >= TIMEOUT_LIMIT) begin
                    $display("ERROR: Timeout waiting for input_a_ack");
                    $finish;
                end
                
                @(negedge clk);
                input_a_stb = 0;

                // Apply input B
                @(negedge clk);
                input_b_stb = 1;
                
                // Wait for input B acknowledge with timeout
                timeout_count = 0;
                while (!input_b_ack && timeout_count < TIMEOUT_LIMIT) begin
                    @(posedge clk);
                    timeout_count = timeout_count + 1;
                end
                
                if (timeout_count >= TIMEOUT_LIMIT) begin
                    $display("ERROR: Timeout waiting for input_b_ack");
                    $finish;
                end
                
                @(negedge clk);
                input_b_stb = 0;
                
                // Wait for output strobe with timeout
                timeout_count = 0;
                while (!output_z_stb && timeout_count < TIMEOUT_LIMIT) begin
                    @(posedge clk);
                    timeout_count = timeout_count + 1;
                end
                
                if (timeout_count >= TIMEOUT_LIMIT) begin
                    $display("ERROR: Timeout waiting for output_z_stb");
                    $finish;
                end
                
                @(negedge clk);
                output_z_ack = 1;
                
                // Check output
                if (output_z !== expected_output) begin
                    $display("ERROR: Mismatch at test %0d", test_count);
                    $display("Got:      %h", output_z);
                    $display("Expected: %h", expected_output);
                end else begin
                    $display("Test %0d PASSED", test_count);
                end
                
                @(negedge clk);
                output_z_ack = 0;
                
                // Wait a few cycles between vectors
                repeat(5) @(posedge clk);
            end
            else begin
                done = 1;
                $display("End of test vectors reached");
            end
        end
        
        $display("\nCompleted %0d test vectors", test_count);
        $fclose(file);
        $finish;
    end

    // Debug: Monitor state transitions
    always @(output_z) begin
        $display("Time=%0t: Output changed to %h", $time, output_z);
    end

    // Generate waveform file
    initial begin
        $dumpfile("double_multiplier_wave.vcd");
        $dumpvars(0, double_multiplierTb);
    end

endmodule
