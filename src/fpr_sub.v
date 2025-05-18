module fpr_sub (
    input [63:0] input_a,       // 64-bit floating-point input A
    input [63:0] input_b,       // 64-bit floating-point input B
    input clk,                  // Clock signal
    input rst,                  // Reset signal
    input start,                // Start the calculation
    output reg [63:0] output_z, // 64-bit floating-point output Z
    output reg done             // Calculation is done
);

    // Internal Registers
    reg [63:0] a, b, z;
    reg [52:0] a_m, b_m;
    reg [52:0] z_m;
    reg [10:0] a_e, b_e, z_e;
    reg a_s, b_s, z_s;
    reg [53:0] sum;
    reg [10:0] diff_e;

    // FSM State Declaration
    reg [3:0] state;
    parameter get_inputs    = 4'd0,
              unpack        = 4'd1,
              special_cases = 4'd2,
              align         = 4'd3,
              add_0         = 4'd4,
              add_1         = 4'd5,
              normalise_1   = 4'd6,
              pack          = 4'd7,
              put_z         = 4'd8;

    // FSM Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all signals
            state <= get_inputs;
            output_z <= 64'b0;
            z <= 64'b0;
            a <= 64'b0;
            b <= 64'b0;
            done <= 0;
            a_m <= 53'b0;
            b_m <= 53'b0;
            z_m <= 53'b0;
            a_e <= 11'b0;
            b_e <= 11'b0;
            z_e <= 11'b0;
            a_s <= 1'b0;
            b_s <= 1'b0;
            z_s <= 1'b0;
            sum <= 54'b0;
        end else begin
            case (state)

                get_inputs: begin
                    done <= 0; // Deassert `done`
                    if (start) begin
                        a <= input_a;
                        b <= input_b;
                        state <= unpack;
                    end
                end

                unpack: begin
                    a_m <= {1'b1, a[51:0]};
                    b_m <= {1'b1, b[51:0]};
                    a_e <= a[62:52];
                    b_e <= b[62:52];
                    a_s <= a[63];
                    b_s <= b[63] ^ 1; // Flip sign for subtraction
                    state <= special_cases;
                end

                special_cases: begin
                    diff_e <= (a_e > b_e) ? (a_e - b_e) : (b_e - a_e);
                    if (a[62:0] == 63'h7FF0000000000000) begin
			z <= {a_s, 11'h7FF, 52'd0}; // Infinity
                        /*z <= {1'b1, 11'b11111111111, 52'b1}; // NaN*/
                        state <= put_z;
                    end else if (b[62:0] == 63'h7FF0000000000000) begin
                        z <= {b_s, 11'h7FF, 52'd0}; // Infinity
                        state <= put_z;
                    end else if (a[62:0] > 63'h7FF0000000000000 || b[62:0] > 63'h7FF0000000000000) begin
                        z <= {1'b0, 11'b11111111111, 52'd1}; // Negative Infinity
                        state <= put_z;
                    end else if (b[62:0] == 63'b0) begin
                        z <= {a_s, a_e, a_m[51:0]}; // Zero
                        state <= put_z;
		    end else if (a[62:0] == 63'b0) begin
                        z <= {b_s, b_e, b_m[51:0]}; // Zero
                        state <= put_z;
                    end else begin
                        state <= align;
                    end
                end

                align: begin
                    if (a_e > b_e) begin
                        b_m <= b_m >> diff_e;
                        z_e <= a_e;
                    end else if (a_e < b_e) begin
                        a_m <= a_m >> diff_e;
                        z_e <= b_e;
                    end else begin
                        z_e <= a_e;
                    end
                    state <= add_0;
                end

                add_0: begin
                    if (a_s == b_s) begin
                        sum <= a_m + b_m;
                        z_s <= a_s;
                    end else if (a_m >= b_m) begin
                        sum <= a_m - b_m;
                        z_s <= a_s;
                    end else begin
                        sum <= b_m - a_m;
                        z_s <= b_s;
                    end
                    state <= add_1;
                end

                add_1: begin
                    if (sum[53]) begin
                        z_m <= sum[53:1];
                        z_e <= z_e + 1;
                    end else begin
                        z_m <= sum[52:0];
                    end
                    state <= normalise_1;
                end

                normalise_1: begin
                    if (z_m[52] == 0 && z_e > 0) begin
                        z_e <= z_e - 1;
                        z_m <= z_m << 1;
                    end else begin
                        state <= pack;
                    end
                end

                pack: begin
                    z <= {z_s, z_e[10:0], z_m[51:0]};
                    state <= put_z;
                end

                put_z: begin
                    output_z <= z;
                    done <= 1; // Indicate completion
                    if (!start) state <= get_inputs; // Wait for next calculation
                end

            endcase
        end
    end

endmodule
