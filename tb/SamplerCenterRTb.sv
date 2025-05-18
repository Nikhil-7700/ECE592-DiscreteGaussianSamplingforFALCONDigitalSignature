`timescale 1ns/1ps
`include "../src/SamplerCenterR.sv"

module SamplerCenterRTb ();
    // Signal declarations
    reg clk, reset;
    reg start, set;
    reg [255:0] key;
    reg [63:0] nonce;
    reg [63:0] counter;
    reg r_stb, s_stb, dss_stb, ccs_stb;
    reg [31:0] s;
    reg [63:0] r, dss, ccs;
    reg sample_ack;
    wire r_ack, s_ack, dss_ack, ccs_ack;
    wire signed [31:0] sample;
    wire sample_stb;
    reg [31:0] input_state [0:15];     // Array of 16 32-bit words for input

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // DUT instantiation
    SamplerCenterR SamplerCenterR_inst(
        .clk(clk),
        .reset(reset),
        .start(start),
        .set(set),
        .key(key),
        .nonce(nonce),
        .counter(counter),
        .r_stb(r_stb),
        .r(r),
        .r_ack(r_ack),
        .s_stb(s_stb),
        .s(s),
        .s_ack(s_ack),
        .dss_stb(dss_stb),
        .dss(dss),
        .dss_ack(dss_ack),
        .ccs_stb(ccs_stb),
        .ccs(ccs),
        .ccs_ack(ccs_ack),
        .sample_ack(sample_ack),
        .sample(sample),
        .sample_stb(sample_stb)
    );

    // Test vectors
    reg [63:0] test_nonce;
    reg [63:0] test_counter;
    reg [255:0] test_key;
    reg [63:0] test_s, test_r, test_dss, test_ccs;
    reg signed [31:0] expected_sample;
    integer fd, i, status;
    integer scan_count;
    integer test_count = 0;
    integer timeout_count;

    // Add cycle counter
    reg [31:0] cycle_count;
    initial begin
        cycle_count = 0;
        forever begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            //$display("Cycle: %0d, Timeout count: %0d", cycle_count, timeout_count);
        end
    end

    initial begin
        // Initialize signals
        reset = 1;
        start = 0;
        set = 0;
        r_stb = 0;
        s_stb = 0;
        dss_stb = 0;
        ccs_stb = 0;
        sample_ack = 1;
        key = 0;
        nonce = 0;
        counter = 0;
        
        // Open test vector file
        fd = $fopen("SamplerCenterRTb.txt", "r");
        if (fd == 0) begin
            $display("Could not open test vector file");
            $finish;
        end

        // Reset sequence
        #20 reset = 0;
        
        // Add debug print
        $display("Starting test vector processing...");
        
        // Process test vectors
        // Read ChaCha20 state (key, nonce, counter)

        for (i = 0; i < 16; i = i + 1) begin
            status = $fscanf(fd, "%h", input_state[i]);
            if (status != 1) begin
                $display("End of test vectors reached");
                $finish;
            end
        end
        test_key = {input_state[4], input_state[5], 
                  input_state[6], input_state[7],
                  input_state[8], input_state[9],
                  input_state[10], input_state[11]};
        test_nonce = {input_state[12], input_state[13]};
        test_counter = {input_state[15], input_state[14]};
        
            
        // Read s, r, dss, ccs values
        scan_count = $fscanf(fd, "%h %h %h %h", test_s, test_r, test_dss, test_ccs);
        
        // Add debug print
        $display("Read %0d additional values", scan_count);
        if (scan_count != 4) begin
            $display("Error: Could not read all values. Expected 4, got %0d", scan_count);
            $finish;
        end
        
        // Read expected sample
        scan_count = $fscanf(fd, "%d", expected_sample);
        $display("Read expected sample: %0d", expected_sample);
        
        test_count = test_count + 1;
        
        // Apply test vector
        @(posedge clk);
        key = test_key;
        nonce = test_nonce;
        counter = test_counter;
        set = 1;
        start = 1;
        
        @(posedge clk);
        set = 0;
        start = 0;
        
        // Provide r value
        r_stb = 1;
        r = test_r;
        
        // Wait for r_ack with timeout
        timeout_count = 0;
        while (!r_ack && timeout_count < 2000) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end

        $display("Checkpoint 1");
        
        if (timeout_count >= 2000) begin
            $display("Test %0d r_ack Timeout!", test_count);
            $finish;
        end
        
        // Provide s value
        s_stb = 1;
        s = test_s;

        $display("Checkpoint 2");
        // Wait for s_ack with timeout
        timeout_count = 0;
        while (!s_ack && timeout_count < 2000) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end
        
        if (timeout_count >= 2000) begin
            $display("Test %0d s_ack Timeout!", test_count);
            $finish;
        end

        $display("Checkpoint 3");
        // Provide dss value
        dss_stb = 1;
        dss = test_dss;
        
        // Wait for dss_ack with timeout
        timeout_count = 0;
        while (!dss_ack && timeout_count < 2000) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end

        $display("Checkpoint 4");
        
        if (timeout_count >= 2000) begin
            $display("Test %0d dss_ack Timeout!", test_count);
            $finish;
        end
        
        $display("Checkpoint 5");
        // Provide ccs value
        ccs_stb = 1;
        ccs = test_ccs;
        
        // Wait for ccs_ack with timeout
        timeout_count = 0;
        while (!ccs_ack && timeout_count < 2000) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end
        
        if (timeout_count >= 2000) begin
            $display("Test %0d ccs_ack Timeout!", test_count);
            $finish;
        end

        $display("Checkpoint 6");
        timeout_count = 0;
        
        while (!sample_stb && timeout_count < 2000) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end
    
        timeout_count = 0;
        while (!sample_stb && timeout_count < 2000) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end

        if (timeout_count >= 2000) begin
            $display("Test %0d sample_stb Timeout!", test_count);
            $finish;
        end
        

        $display("Checkpoint 7");
        // Check result
        if ($signed(sample) !== expected_sample) begin
            $display("Test %0d Failed!", test_count);
            $display("Expected sample: %d", expected_sample);
            $display("Got sample     : %d", $signed(sample));
            $display("For inputs:");
            $display("r    : %h", test_r);
            $display("s    : %h", test_s);
            $display("dss  : %h", test_dss);
            $display("ccs  : %h", test_ccs);
        end else begin
            $display("Cycle: %0d, Timeout count: %0d", cycle_count, timeout_count);
            $display("Test %0d Passed!", test_count);
        end
        
        // Close file and finish simulation
        $fclose(fd);
        #100;
        $display("All tests completed!");
        $finish;
    end

    // Optional: Add waveform dumping
    initial begin
        $dumpfile("SamplerCenterRTb.vcd");
        $dumpvars(0, SamplerCenterRTb);
    end

    // Add simulation timeout
    initial begin
        #200000;  // 200,000 time units
        $display("ERROR: Global simulation timeout reached!");
        $display("Simulation appears to be stuck!");
        $finish;
    end

endmodule
