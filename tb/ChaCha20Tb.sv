`timescale 1ns/1ps
`include "../src/ChaCha20.sv"

module ChaCha20Tb;
    // Signals
    reg clk;
    reg reset;
    reg set;
    reg [255:0] key;
    reg [63:0] nonce_in;
    reg [63:0] counter_in;
    wire [511:0] output_data;
    wire done;
    
    // Test variables
    integer file, status, i;
    integer test_count;  // Added test counter
    reg [31:0] expected_state [0:15];
    reg [31:0] expected_output [0:15];
    reg timeout;

    // DUT instantiation
    ChaCha20 u_ChaCha20 (
        .clk(clk),
        .reset(reset),
        .set(set),
        .key(key),
        .nonce_in(nonce_in),
        .counter_in(counter_in),
        .output_data(output_data),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        reset = 0;  // Active low reset
        set = 0;
        key = 256'h0;  // Fixed to 256 bits
        nonce_in = 64'h0;
        counter_in = 64'h0;
        timeout = 0;
        test_count = 0;

        // Open test vector file
        file = $fopen("ChaCha20.txt", "r");
        if (file == 0) begin
            $display("Error: Could not open test vector file");
            $finish;
        end
        $display("Test file opened successfully");

        // Initial reset sequence
        $display("Time=%0t: Initial reset asserted (active low)", $time);
        repeat(10) @(posedge clk);
        
        reset = 1;  // Release reset
        $display("Time=%0t: Reset deasserted", $time);

        // Wait a few clock cycles after reset
        repeat(5) @(posedge clk);
        $display("Time=%0t: Starting test vectors", $time);
        
        while (!$feof(file)) begin
            test_count = test_count + 1;
            $display("\n=== Starting test vector %0d ===", test_count);
            
            // Read input state
            for (i = 0; i < 16; i = i + 1) begin
                status = $fscanf(file, "%h", expected_state[i]);
                if (status != 1) begin
                    $display("End of test vectors reached");
                    $finish;
                end
                $display("State[%0d] = %h", i, expected_state[i]);
            end

            // Apply test vector
            @(posedge clk);
            set = 1;
            key = {expected_state[4], expected_state[5], 
                  expected_state[6], expected_state[7], 
                  expected_state[8], expected_state[9],
                  expected_state[10], expected_state[11]};
            nonce_in = {expected_state[12], expected_state[13]};
            counter_in = {expected_state[15], expected_state[14]};
            
            $display("\nPrepared inputs at time %0t:", $time);
            $display("  key = %h", key);
            $display("  nonce = %h", nonce_in);
            $display("  counter = %h", counter_in);
            
            // Apply test vector with set pulse
            @(posedge clk);
            $display("Time=%0t: Setting set=1", $time);
            set = 1;
            
            @(posedge clk);
            $display("Time=%0t: Setting set=0", $time);
            set = 0;
            
            // Read expected output
            for (i = 15; i >= 0; i = i - 1) begin
                status = $fscanf(file, "%h", expected_output[i]);
                $display("Expected[%0d] = %h", i, expected_output[i]);
            end

            // Wait for done to be asserted
            i = 0;
            while (!done && i < 100) begin  // Wait up to 100 clock cycles
                @(posedge clk);
                i = i + 1;
            end

            if (i >= 100) begin
                $display("Error: Done signal not asserted after 100 cycles!");
                $finish;
            end

            // Check output
            $display("\nGot result at time %0t!", $time);
            for (i = 0; i < 16; i = i + 1) begin
                if (output_data[i*32 +: 32] !== expected_output[i]) begin
                    $display("Mismatch at word %0d: Got %h, Expected %h", 
                            i, output_data[i*32 +: 32], expected_output[i]);
                end else begin
                    $display("Match at word %0d: %h", i, output_data[i*32 +: 32]);
                end
            end

            // Wait a few cycles between test vectors
            repeat(5) @(posedge clk);
        end
        
        $display("\nCompleted %0d test vectors", test_count);
        $fclose(file);
        $finish;
    end


    // Add debug for done signal
    always @(done) begin
        $display("Time=%0t: Done signal changed to %b", $time, done);
    end

    // Add waveform monitoring
    initial begin
        $dumpfile("ChaCha20_wave.vcd");
        $dumpvars(0, ChaCha20Tb);
    end

endmodule