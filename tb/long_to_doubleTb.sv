`timescale 1ns/1ps
`include "../src/long_to_double.v"

module long_to_doubleTb();

    reg     clk;
    reg     rst;

    reg     [63:0] input_a;
    reg     input_a_stb;
    wire    input_a_ack;

    wire    [63:0] output_z;
    wire    output_z_stb;
    reg     output_z_ack;

    // Test variables
    integer file, status;
    integer test_count;
    integer timeout_count;  // Added timeout counter
    parameter TIMEOUT_LIMIT = 1000;  // Maximum cycles to wait
    reg [63:0] expected_output;
    reg done;
    
    long_to_double long_to_double_inst(
        .input_a(input_a),
        .input_a_stb(input_a_stb),
        .output_z_ack(output_z_ack),
        .clk(clk),
        .rst(rst),
        .output_z(output_z),
        .output_z_stb(output_z_stb),
        .input_a_ack(input_a_ack));

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
        input_a_stb = 0;
        output_z_ack = 0;
        test_count = 0;
        done = 0;

        // Open test vector file
        file = $fopen("long_to_doubleTb.txt", "r");
        if (file == 0) begin
            $display("Error: Could not open test vector file");
            $finish;
        end
        $display("Test file opened successfully");

        // Initial reset sequence
        #10 rst = 0;
        $display("Time=%0t: Reset deasserted", $time);

        // Wait a few clock cycles after reset
        repeat(5) @(posedge clk);
        
        while (!$feof(file) && !done) begin
            test_count = test_count + 1;
            
            // Read input and expected output from file
            status = $fscanf(file, "%d %h", input_a, expected_output);
            if (status == 2) begin  // Valid data read
                $display("\n=== Test Vector %0d ===", test_count);
                $display("Input (decimal): %0d", input_a);
                $display("Expected output (hex): %h", expected_output);

                // Apply test vector - make changes at negedge to ensure stability
                @(negedge clk);
                input_a_stb = 1;
                $display("Time=%0t: Setting input_a_stb=1", $time);
                
                // Wait for input acknowledge with timeout
                timeout_count = 0;
                while (!input_a_ack && timeout_count < TIMEOUT_LIMIT) begin
                    @(posedge clk);
                    timeout_count = timeout_count + 1;
                end
                
                if (timeout_count >= TIMEOUT_LIMIT) begin
                    $display("ERROR: Timeout waiting for input_a_ack");
                    $finish;
                end
                
                @(negedge clk);  // Change at negedge
                input_a_stb = 0;
                $display("Time=%0t: Setting input_a_stb=0", $time);
                
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
                
                output_z_ack = 1;
                
                // Check output
                if (output_z !== expected_output) begin
                    $display("ERROR: Mismatch at test %0d", test_count);
                    $display("Got:      %h", output_z);
                    $display("Expected: %h", expected_output);
                end else begin
                    $display("Test %0d PASSED", test_count);
                end
                
                @(posedge clk);
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
        $dumpfile("long_to_double_wave.vcd");
        $dumpvars(0, long_to_doubleTb);
    end

endmodule

