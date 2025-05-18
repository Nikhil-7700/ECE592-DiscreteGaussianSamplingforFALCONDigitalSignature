`timescale 1ns/1ps
`include "../src/fpr_expm_p63.sv"

module fpr_expm_p63Tb;
	reg [63:0] d;
	reg [63:0] ccs;
	reg d_stb;
	reg ccs_stb;
	wire [63:0] y;
	wire y_stb;
	wire d_ack;
	wire ccs_ack;
	reg y_ack;
	reg clk;
	reg rst;    

	// Clock generation
	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end

	fpr_expm_p63 fpr_expm_p63_inst (
		.d(d),
		.ccs(ccs),
		.d_stb(d_stb),
		.ccs_stb(ccs_stb),
		.y_ack(y_ack),
		.y(y),
		.y_stb(y_stb),
		.d_ack(d_ack),
		.ccs_ack(ccs_ack),
		.clk(clk),
		.rst(rst)
	);

	// Test vectors
	reg [63:0] test_d, test_ccs, expected_y;
	integer fd;
	integer scan_count;
	integer test_count = 0;
	integer timeout_count;

	initial begin
		// Initialize signals
		rst = 1;
		d_stb = 0;
		ccs_stb = 0;
		d = 0;
		ccs = 0;
        y_ack = 1;
		
		// Open test vector file
		fd = $fopen("fpr_expm_p63Tb.txt", "r");
		if (fd == 0) begin
			$display("Could not open test vector file");
			$finish;
		end

		// Reset sequence
		#20 rst = 0;
		
		// Process test vectors
		while (!$feof(fd)) begin
			scan_count = $fscanf(fd, "%h %h %h", test_d, test_ccs, expected_y);
			
			if (scan_count == 3) begin
				test_count = test_count + 1;
				
				// Apply test vector
				@(posedge clk);
				d_stb = 1;
				ccs_stb = 1;
				d = test_d;
				ccs = test_ccs;
				
				// Wait for result with timeout
				timeout_count = 0;
				while (!y_stb && timeout_count < 2000) begin
					@(posedge clk);
					timeout_count = timeout_count + 1;
				end
				
				if (timeout_count >= 2000) begin
					$display("Test %0d Timeout!", test_count);
					$finish;
				end
				
				// Check result
				if (y !== expected_y) begin
					$display("Test %0d Failed!", test_count);
					$display("Expected: %h", expected_y);
					$display("Got     : %h", y);
				end else begin
					$display("Test %0d Passed!", test_count);
				end
				
				// Wait for handshake completion with timeout
				@(posedge clk);
				d_stb = 0;
				ccs_stb = 0;
				timeout_count = 0;
				while ((d_ack || ccs_ack) && timeout_count < 2000) begin
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
		$dumpfile("fpr_expm_p63Tb.vcd");
		$dumpvars(0, fpr_expm_p63Tb);
	end

endmodule
