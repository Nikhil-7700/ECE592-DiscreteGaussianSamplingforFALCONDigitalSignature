module fpr_sqr (
    input [63:0] input_a,       // 64-bit floating-point input A
    //input [63:0] input_b,       // 64-bit floating-point input B
    input clk,                  // Clock signal
    input rst,                  // Reset signal
    input start,                // Start the calculation
    output reg [63:0] output_z, // 64-bit floating-point output Z
    output reg done             // Calculation is done
);

    // Internal Registers
    reg [63:0] a, z;
    reg [52:0] a_m;       // Mantissas
    reg [52:0] z_m;            // Result mantissa
    reg [10:0] a_e, z_e;  // Exponents
    reg a_s, z_s;         // Signs
    reg [105:0] product;       // Mantissa product (52-bit x 52-bit = 106-bit)
    reg guard, round_bit, sticky;

    // FSM State Declaration
    reg [3:0] state;
    parameter get_inputs    = 4'd0,
              unpack        = 4'd1,
              special_cases = 4'd2,
              normalise_a   = 4'd3,
              multiply      = 4'd4,
              normalise_1   = 4'd5,
              normalise_2   = 4'd6,
              round         = 4'd7,
              pack          = 4'd8,
              put_z         = 4'd9;

    // FSM Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all signals
            state <= get_inputs;
            output_z <= 64'b0;
            z <= 64'b0;
            a <= 64'b0;
            //b <= 64'b0;
            done <= 0;
            a_m <= 53'b0;
            //b_m <= 53'b0;
            z_m <= 53'b0;
            a_e <= 11'b0;
            //b_e <= 11'b0;
            z_e <= 11'b0;
            a_s <= 1'b0;
            //b_s <= 1'b0;
            z_s <= 1'b0;
            product <= 106'b0;
            guard <= 1'b0;
            round_bit <= 1'b0;
            sticky <= 1'b0;
        end else begin
            case (state)

                get_inputs: begin
                    done <= 0; // Deassert `done`
                    if (start) begin
                        a <= input_a;
                        //b <= input_b;
                        state <= unpack;
                    end
                end

                unpack: begin
                    // Extract mantissas, exponents, and signs
                    a_m <= {1'b1, a[51:0]};
                    //b_m <= {1'b1, b[51:0]};
                    a_e <= a[62:52];
                    //b_e <= b[62:52];
                    a_s <= a[63];
                    //b_s <= b[63];
                    z_s <= 1'b0; // XOR signs for multiplication
                    state <= special_cases;
                end

                special_cases: begin
                    if (a[62:0] > 63'h7FF0000000000000) begin
                        // NaN case
                        z <= {1'b1, 11'b11111111111, 52'b1};
                        state <= put_z;
                    end else if (a[62:0] == 63'h7FF0000000000000) begin
                        // Infinity case
                        z <= {z_s, 11'b11111111111, 52'b0};
                        state <= put_z;
                    end else if (a[62:0] == 63'd0) begin
                        // Zero case
                        z <= 64'b0;
                        state <= put_z;
                    end else begin
                        state <= normalise_a;
                    end
                end

                normalise_a: begin
                    if (!a_m[52]) begin
                        a_m <= a_m << 1;
                        a_e <= a_e - 1;
                    end else begin
                        state <= multiply;
                    end
                end

                multiply: begin
                    // Multiply mantissas and add exponents
                    product <= a_m * a_m; // 53-bit * 53-bit = 106-bit
                    z_e <= (a_e << 1) - 1023; // Subtract the bias
                    state <= normalise_1;
                end

                normalise_1: begin
                    if (product[105]) begin
                        z_m <= product[105:53];
                        guard <= product[52];
                        round_bit <= product[51];
                        sticky <= |product[50:0];
                        z_e <= z_e + 1;
                    end else begin
                        z_m <= product[104:52];
                        guard <= product[51];
                        round_bit <= product[50];
                        sticky <= |product[49:0];
                    end
                    state <= normalise_2;
                end

                normalise_2: begin
                    if (!z_m[52] && z_e > 0) begin
                        z_m <= z_m << 1;
                        z_e <= z_e - 1;
                    end else begin
                        state <= round;
                    end
                end

                round: begin
                    if (guard && (round_bit | sticky | z_m[0])) begin
                        z_m <= z_m + 1;
                        if (z_m == 53'h1fffffffffffff) z_e <= z_e + 1; // Handle carry
                    end
                    state <= pack;
                end

                pack: begin
                    z <= {z_s, z_e[10:0], z_m[51:0]};
                    state <= put_z;
                end

                put_z: begin
                    output_z <= z;
                    done <= 1;
                    if (!start) state <= get_inputs;
                end

            endcase
        end
    end

endmodule
