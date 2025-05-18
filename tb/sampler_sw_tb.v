`timescale 1ns / 1ps

module sampler_sw_tb;

    // Inputs
    reg clk;
    reg rst;
    reg valid_in;
    reg [63:0] mu;          // Floating-point input mu
    reg [63:0] isigma;      // Floating-point input isigma
    reg [63:0] sigma_min;   // Floating-point input sigma_min

    // Outputs
    wire [63:0] r;          // Fractional part of mu
    wire [63:0] dss;        // dss = 0.5 * isigma^2
    wire [63:0] ccs;        // ccs = isigma * sigma_min
    wire [63:0] s_fpr;      // Floating-point integer part
    wire [31:0] s_int;      // Integer part of mu
    wire valid_out;         // Output valid signal

    // Instantiate the sampler_sw module
    sampler_sw uut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .mu(mu),
        .isigma(isigma),
        .sigma_min(sigma_min),
        .r(r),
        .dss(dss),
        .ccs(ccs),
        .s_fpr(s_fpr),
        .s_int(s_int),
        .valid_out(valid_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end

    // Reset generation
    initial begin
        rst = 1;
        #20 rst = 0;  // Deassert reset after 20ns
    end

    // Stimulus
    initial begin
        // Initialize inputs
        valid_in = 0;
        mu = 0;
        isigma = 0;
        sigma_min = 0;

        // Wait for reset
        @(negedge rst);

        // Test Case 1: Simple inputs
        #10;
        valid_in = 1;
        mu = 64'hc03520d4a63c896e;       // -21.128245 in IEEE-754
        isigma = 64'h3fe2b00fe5a7ad7a;   // 0.583992 in IEEE-754
        sigma_min = 64'h3ff41ce5358cb3a0; // 1.257055 in IEEE-754

        @(posedge clk);                  // Wait one clock cycle
        valid_in = 0;                    // Deassert valid_in

        // Wait for valid_out
        wait(valid_out);

        // Display outputs
        $display("Test Case 1:");
        $display("mu = %h, isigma = %h, sigma_min = %h", mu, isigma, sigma_min);
        $display("s_fpr = %h, s_int = %d", s_fpr, $signed(s_int));
        $display("r = %h", r);
        $display("dss = %h", dss);
        $display("ccs = %h", ccs);

        // Test Case 2: Another set of inputs
        #20;
        valid_in = 1;
        mu = 64'h402488a7d1d64b8b;       // 10.266905 in IEEE-754
        isigma = 64'h3fe2b00fe5a7ad7a;   //  0.583992 in IEEE-754
        sigma_min = 64'h3ff41ce5358cb3a0; // 1.257055 in IEEE-754

        @(posedge clk);
        valid_in = 0;

        // Wait for valid_out
        wait(valid_out);

        // Display outputs
        $display("Test Case 2:");
        $display("mu = %h, isigma = %h, sigma_min = %h", mu, isigma, sigma_min);
        $display("s_fpr = %h, s_int = %d", s_fpr, $signed(s_int));
        $display("r = %h", r);
        $display("dss = %h", dss);
        $display("ccs = %h", ccs);

        // Finish simulation
        #50;
        $finish;
    end

endmodule

