`timescale 1ns/1ps
`include "../src/Calx.sv"

module CalxTb();

    reg clk;
    reg rst;
    reg stb;
    wire ack;
    reg [63:0] z;
    reg [63:0] r;
    reg [63:0] dss;
    reg [63:0] z0square;
    wire [63:0] x;
    wire x_stb;
    reg x_ack;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    Calx uut(
        .clk(clk),
        .rst(rst),
        .stb(stb),
        .ack(ack),
        .z(z),
        .r(r), 
        .dss(dss),
        .z0square(z0square),
        .x(x),
        .x_stb(x_stb),
        .x_ack(x_ack)
    );

    // Test vectors
    reg [63:0] test_z, test_r, test_z0square, test_dss, expected_x;
    integer fd;
    integer scan_count;
    integer test_count = 0;
    integer timeout_count;

    initial begin
        // Initialize signals
        rst = 1;
        stb = 0;
        x_ack = 1;
        z = 0;
        r = 0;
        dss = 0;
        z0square = 0;
        
        // Open test vector file
        fd = $fopen("CalxTb.txt", "r");
        if (fd == 0) begin
            $display("Could not open test vector file");
            $finish;
        end

        // Reset sequence
        #20 rst = 0;
        
        // Process test vectors
        while (!$feof(fd)) begin
            scan_count = $fscanf(fd, "%h %h %h %h %h", test_z, test_r, test_z0square, test_dss, expected_x);
            
            if (scan_count == 5) begin
                test_count = test_count + 1;
                
                // Apply test vector
                @(posedge clk);
                stb = 1;
                z = test_z;
                r = test_r;
                dss = test_dss;
                z0square = test_z0square;
                
                // Wait for result with timeout
                timeout_count = 0;
                while (!x_stb && timeout_count < 2000) begin
                    @(posedge clk);
                    timeout_count = timeout_count + 1;
                end
                
                if (timeout_count >= 2000) begin
                    $display("Test %0d Timeout!", test_count);
                    $finish;
                end
                
                // Check result
                if (x !== expected_x) begin
                    $display("Test %0d Failed!", test_count);
                    $display("Expected: %h", expected_x);
                    $display("Got     : %h", x);
                end else begin
                    $display("Test %0d Passed!", test_count);
                end
                
                // Wait for handshake completion with timeout
                @(posedge clk);
                stb = 0;
                timeout_count = 0;
                while (ack && timeout_count < 2000) begin
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
        $dumpfile("CalxTb.vcd");
        $dumpvars(0, CalxTb);
    end

endmodule
