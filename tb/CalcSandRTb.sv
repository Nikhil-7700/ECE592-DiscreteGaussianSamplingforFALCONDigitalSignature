`timescale 1ns/1ps
`include "../src/BerExp.sv"

module CalcSandRTb();
    reg clk, rst, x_stb, s_ack, r_ack;
    reg [63:0] x, ccs;
    wire [31:0] s;
    wire s_stb;
    wire [63:0] r;
    wire x_ack;


    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    CalcSandR calcSandR_inst (
        .clk(clk),
        .rst(rst),
        .x_stb(x_stb),
        .s_ack(s_ack),
        .r_ack(r_ack),
        .x(x),
        .ccs(ccs),
        .s(s),
        .s_stb(s_stb),
        .r(r),
        .x_ack(x_ack)
    );

    // Test vectors
    logic [63:0] test_x, test_ccs, expected_s, expected_r;
    integer fd;
    integer scan_count;
    integer test_count = 0;
    integer timeout_count;

    initial begin
        // Initialize signals
        rst = 1;
        x_stb = 0;
        s_ack = 1;
        r_ack = 1;
        x = 0;
        ccs = 0;
        
        // Open test vector file
        fd = $fopen("CalcSandRTb.txt", "r");
        if (fd == 0) begin
            $display("Could not open test vector file");
            $finish;
        end

        // Reset sequence
        #20 rst = 0;
        
        // Process test vectors
        while (!$feof(fd)) begin
            scan_count = $fscanf(fd, "%h %h %h %h", test_x, test_ccs, expected_s, expected_r);
            
            if (scan_count == 4) begin
                test_count = test_count + 1;
                
                // Apply test vector
                @(posedge clk);
                x_stb = 1;
                x = test_x;
                ccs = test_ccs;
                
                // Wait for result with timeout
                timeout_count = 0;
                while ((!s_stb) && timeout_count < 2000) begin
                    @(posedge clk);
                    timeout_count = timeout_count + 1;
                end
                
                if (timeout_count >= 2000) begin
                    $display("Test %0d Timeout!", test_count);
                    $finish;
                end
                
                // Check results
                if (s !== expected_s || r !== expected_r) begin
                    $display("Test %0d Failed!", test_count);
                    if (s !== expected_s) begin
                        $display("S Expected: %h", expected_s);
                        $display("S Got     : %h", s);
                    end
                    if (r !== expected_r) begin
                        $display("R Expected: %h", expected_r);
                        $display("R Got     : %h", r);
                    end
                end else begin
                    $display("Test %0d Passed!", test_count);
                end
                
                // Wait for handshake completion with timeout
                @(posedge clk);
                x_stb = 0;
                timeout_count = 0;
                while ((x_ack) && timeout_count < 2000) begin
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
        $dumpfile("CalcSandRTb.vcd");
        $dumpvars(0, CalcSandRTb);
    end

endmodule