`timescale 1ns/1ps
`include "../src/BerExp.sv"

module BerExpTb ();
    // Signal declarations
    reg clk, rst;
    reg [7:0] prng_get_u8;
    reg prng_get_u8_stb;
    reg x_stb, ccs_stb;
    reg y_ack, b_ack;
    reg [63:0] x, ccs;
    wire prng_get_u8_ack;
    wire get_u8;
    wire [63:0] y;
    wire x_ack, ccs_ack;
    wire y_stb;
    wire b;
    wire b_stb;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // DUT instantiation
    BerExp BerExp_inst(
        .prng_get_u8(prng_get_u8),
        .prng_get_u8_ack(prng_get_u8_ack),
        .prng_get_u8_stb(prng_get_u8_stb),
        .get_u8(get_u8),
        .clk(clk),
        .rst(rst),
        .x_stb(x_stb),
        .ccs_stb(ccs_stb),
        .x(x),
        .ccs(ccs),
        .x_ack(x_ack),
        .ccs_ack(ccs_ack),
        .b(b),
        .b_stb(b_stb),
        .b_ack(b_ack)
    );

    // Test vectors
    reg [63:0] test_x;
    reg [63:0] test_ccs;
    reg [7:0] test_prng;
    reg expected_b;
    integer fd;
    integer scan_count;
    integer test_count = 0;
    integer timeout_count;

    initial begin
        // Initialize signals
        rst = 1;
        x_stb = 0;
        ccs_stb = 0;
        y_ack = 1;
        b_ack = 1;
        prng_get_u8_stb = 0;
        x = 0;
        ccs = 0;
        prng_get_u8 = 0;
        
        // Open test vector file
        fd = $fopen("BerExpTb.txt", "r");
        if (fd == 0) begin
            $display("Could not open test vector file");
            $finish;
        end

        // Reset sequence
        #20 rst = 0;
        
        // Process test vectors
        while (!$feof(fd)) begin
            scan_count = $fscanf(fd, "%h %h %h %b", test_x, test_ccs, test_prng, expected_b);
            
            if (scan_count == 4) begin
                test_count = test_count + 1;
                
                // Apply test vector
                @(posedge clk);
                x_stb = 1;
                ccs_stb = 1;
                x = test_x;
                ccs = test_ccs;

            

                
                // Wait for get_u8 request and provide PRNG value
                timeout_count = 0;
                while (!get_u8 && timeout_count < 2000) begin
                    @(posedge clk);
                    timeout_count = timeout_count + 1;
                end
                
                if (timeout_count >= 2000) begin
                    $display("Test %0d PRNG Request Timeout!", test_count);
                    $finish;
                end

                // Provide PRNG value
                prng_get_u8_stb = 1;
                prng_get_u8 = test_prng;
                
                // Wait for result with timeout
                timeout_count = 0;
                while (!b_stb && timeout_count < 2000) begin
                    @(posedge clk);
                    timeout_count = timeout_count + 1;
                end
                
                if (timeout_count >= 2000) begin
                    $display("Test %0d Result Timeout!", test_count);
                    $finish;
                end
                
                // Check result
                if (b !== expected_b) begin
                    $display("Test %0d Failed!", test_count);
                    $display("Expected b: %b", expected_b);
                    $display("Got b     : %b", b);
                    $display("For inputs:");
                    $display("x         : %h", test_x);
                    $display("ccs       : %h", test_ccs);
                    $display("prng_get_u8: %h", test_prng);
                end else begin
                    $display("Test %0d Passed!", test_count);
                end
                
                // Wait for handshake completion with timeout
                @(posedge clk);
                x_stb = 0;
                ccs_stb = 0;
                prng_get_u8_stb = 0;
                timeout_count = 0;
                while ((x_ack || ccs_ack || prng_get_u8_ack) && timeout_count < 2000) begin
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
        $dumpfile("BerExpTb.vcd");
        $dumpvars(0, BerExpTb);
    end

endmodule