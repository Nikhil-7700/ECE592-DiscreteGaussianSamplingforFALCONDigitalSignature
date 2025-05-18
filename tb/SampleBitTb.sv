`timescale 1ns/1ps
`include "../src/BerExp.sv"

module SampleBitTb();

    reg clk, rst;
    reg [63:0] y_fpr_expm_p63;
    reg y_fpr_expm_p63_stb;
    reg [7:0] prng_get_u8;
    reg prng_get_u8_stb;
    reg [31:0] s;
    wire y_fpr_expm_p63_ack;
    wire prng_get_u8_ack;
    wire get_u8;
    wire b;
    wire b_stb;
    reg b_ack;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    SampleBit SampleBit (
        .clk(clk),
        .rst(rst),
        .y_fpr_expm_p63(y_fpr_expm_p63),
        .y_fpr_expm_p63_stb(y_fpr_expm_p63_stb),
        .prng_get_u8(prng_get_u8),
        .prng_get_u8_stb(prng_get_u8_stb),
        .s(s),
        .y_fpr_expm_p63_ack(y_fpr_expm_p63_ack),
        .prng_get_u8_ack(prng_get_u8_ack),
        .get_u8(get_u8),
        .b(b),
        .b_stb(b_stb),
        .b_ack(b_ack)
    );

    // Test vectors
    reg [63:0] test_y;
    reg [31:0] test_s;
    reg [7:0] test_prng;
    reg expected_b;
    integer fd;
    integer scan_count;
    integer test_count = 0;
    integer timeout_count;

    initial begin
        // Initialize signals
        rst = 1;
        y_fpr_expm_p63_stb = 0;
        prng_get_u8_stb = 0;
        b_ack = 1;
        y_fpr_expm_p63 = 0;
        prng_get_u8 = 0;
        s = 0;
        
        // Open test vector file
        fd = $fopen("SampleBitTb.txt", "r");
        if (fd == 0) begin
            $display("Could not open test vector file");
            $finish;
        end

        // Reset sequence
        #20 rst = 0;
        
        // Process test vectors
        while (!$feof(fd)) begin
            scan_count = $fscanf(fd, "%h %h %h %b", test_y, test_s, test_prng, expected_b);
            
            if (scan_count == 4) begin
                test_count = test_count + 1;
                
                // Apply test vector
                @(posedge clk);
                y_fpr_expm_p63_stb = 1;
                prng_get_u8_stb = 1;
                y_fpr_expm_p63 = test_y;
                s = test_s;
                prng_get_u8 = test_prng;
                
                // Wait for result with timeout
                timeout_count = 0;
                while (!b_stb && timeout_count < 2000) begin
                    @(posedge clk);
                    timeout_count = timeout_count + 1;
                end
                
                if (timeout_count >= 2000) begin
                    $display("Test %0d Timeout!", test_count);
                    $finish;
                end
                
                // Check result
                if (b !== expected_b) begin
                    $display("Test %0d Failed!", test_count);
                    $display("Expected b: %b", expected_b);
                    $display("Got b     : %b", b);
                    $display("For inputs:");
                    $display("y_fpr_expm_p63: %h", test_y);
                    $display("s            : %h", test_s);
                    $display("prng_get_u8   : %h", test_prng);
                end else begin
                    $display("Test %0d Passed!", test_count);
                end
                
                // Wait for handshake completion with timeout
                @(posedge clk);
                y_fpr_expm_p63_stb = 0;
                prng_get_u8_stb = 0;
                timeout_count = 0;
                while ((y_fpr_expm_p63_ack || prng_get_u8_ack) && timeout_count < 2000) begin
                    @(posedge clk);
                    timeout_count = timeout_count + 1;
                end
                
                if (timeout_count >= 2000) begin
                    $display("Test %0d Handshake Timeout!", test_count);
                    $finish;
                end
            end
        end
        
        // Close file and finish simulation
        $fclose(fd);
        #100;
        $display("All tests completed!");
        $finish;
    end

    // Optional: Add waveform dumping
    initial begin
        $dumpfile("SampleBitTb.vcd");
        $dumpvars(0, SampleBitTb);
    end

endmodule
