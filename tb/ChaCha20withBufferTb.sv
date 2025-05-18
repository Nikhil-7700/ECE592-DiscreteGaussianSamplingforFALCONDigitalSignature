`timescale 1ns/1ps
`include "../src/ChaCha20.sv"

module ChaCha20withBufferTb;
    // Signals
    reg clk;
    reg reset;
    reg set;
    reg [255:0] key;
    reg [63:0] nonce_in;
    reg [63:0] counter_in;
    reg get_u8;
    reg get_u64;
    wire [7:0] u8;
    wire u8_stb;
    wire [63:0] u64;
    wire u64_stb;


    // Test variables
    integer file, status, i;
    integer test_count = 0;
    reg [31:0] input_state [0:15];     // Array of 16 32-bit words for input
    reg [31:0] expected_output [0:15];  // Array of 16 32-bit words for output
    reg [7:0] received_bytes [0:63];
    reg [63:0] received_u64s [0:7];
    integer byte_count, u64_count;
    integer timeout_count;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // DUT instantiation
    ChaCha20withBuffer ChaCha20withBuffer_inst (
        .clk(clk),
        .reset(reset),
        .get_u8(get_u8),
        .set(set),
        .key(key),
        .nonce_in(nonce_in),
        .counter_in(counter_in),
        .u8(u8),
        .u8_stb(u8_stb),
        .get_u64(get_u64),
        .u64(u64),
        .u64_stb(u64_stb)
    );

    // Test procedure
    initial begin
        // Initialize signals
        reset = 0;
        set = 0;
        get_u8 = 0;
        get_u64 = 0;
        key = 256'h0;
        nonce_in = 64'h0;
        counter_in = 64'h0;

        // Open test vector file
        file = $fopen("ChaCha20.txt", "r");
        if (file == 0) begin
            $display("Error: Could not open test vector file");
            $finish;
        end

        // Reset sequence
        #20 reset = 1;
        #20;

        while (!$feof(file)) begin
            test_count = test_count + 1;
            $display("\n=== Starting test vector %0d ===", test_count);

            // Read input state (16 32-bit words)
            for (i = 0; i < 16; i = i + 1) begin
                status = $fscanf(file, "%h", input_state[i]);
                if (status != 1) begin
                    $display("End of test vectors reached");
                    $finish;
                end
            end

            // Read expected output (16 32-bit words)
            for (i = 0; i < 16; i = i + 1) begin
                status = $fscanf(file, "%h", expected_output[i]);
            end

            // Apply test vector
            @(posedge clk);
            set = 1;
            key = {input_state[4], input_state[5], 
                  input_state[6], input_state[7],
                  input_state[8], input_state[9],
                  input_state[10], input_state[11]};
            nonce_in = {input_state[12], input_state[13]};
            counter_in = {input_state[15], input_state[14]};
            @(posedge clk);
            set = 0;

            // Test get_u8 interface
            $display("\nTesting byte-wise reading:");
            byte_count = 0;
            while (byte_count < 32) begin
                @(posedge clk);
                get_u8 = 1;
                
                timeout_count = 0;
                while (!u8_stb && timeout_count < 1000) begin
                    @(posedge clk);
                    timeout_count = timeout_count + 1;
                end
                
                if (timeout_count >= 1000) begin
                    $display("Error: Timeout waiting for u8_stb");
                    $finish;
                end

                received_bytes[byte_count] = u8;
                $display("Byte[%0d] = %h", byte_count, u8);
                byte_count = byte_count + 1;
                @(posedge clk);
                get_u8 = 0;
                @(posedge clk);
            end

            // Verify byte-wise results
            for (i = 0; i < 32; i = i + 1) begin
                if (received_bytes[i] !== expected_output[15-(i/4)][(i%4)*8 +: 8]) begin
                    $display("Byte mismatch at index %0d: Got %h, Expected %h",
                            i, received_bytes[i], 
                            expected_output[15-(i/4)][(i%4)*8 +: 8]);
                end
            end
           

            // Test get_u64 interface
            $display("\nTesting 64-bit reading:");
            u64_count = 0;
            while (u64_count < 4) begin
                @(posedge clk);
                get_u64 = 1;
                
                timeout_count = 0;
                while (!u64_stb && timeout_count < 1000) begin
                    @(posedge clk);
                    timeout_count = timeout_count + 1;
                end
                
                if (timeout_count >= 1000) begin
                    $display("Error: Timeout waiting for u64_stb");
                    $finish;
                end

                received_u64s[u64_count] = u64;
                $display("U64[%0d] = %h", u64_count, u64);
                u64_count = u64_count + 1;
                @(posedge clk);
                get_u64 = 0;
                @(posedge clk);
            end

            // Verify 64-bit results
            for (i = 0; i < 4; i = i + 1) begin
                if (received_u64s[i] !== {expected_output[14-2*(i+4)], expected_output[15-2*(i+4)]}) begin
                    $display("U64 mismatch at index %0d: Got %h, Expected %h",
                            i, received_u64s[i],
                            {expected_output[14-2*(i+4)], expected_output[15-2*(i+4)]});
                end
            end

            // Wait between test vectors
            repeat(5) @(posedge clk);
        end

        $display("\nCompleted %0d test vectors", test_count);
        $fclose(file);
        $finish;
    end

    // Optional: Waveform dumping
    initial begin
        $dumpfile("ChaCha20withBuffer.vcd");
        $dumpvars(0, ChaCha20withBufferTb);
    end

endmodule
