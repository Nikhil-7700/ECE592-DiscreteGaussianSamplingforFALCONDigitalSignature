module fpr_half (
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
    reg [4:0] state;
    parameter get_inputs    = 5'b00001,
              unpack        = 5'b00010,
              cases_half 	= 5'b00100,
              pack          = 5'b01000,
              put_z         = 5'b10000;

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
                        //b <= 64'h3FE0000000000000;
                        state <= unpack;
                    end
                end

                unpack: begin
                    // Extract mantissas, exponents, and signs
                    a_m <= (a[62:52] == 0) ? {1'b0, a[51:0]} : {1'b1, a[51:0]};
                    //b_m <= {1'b1, b[51:0]};
                    a_e <= a[62:52];
                    //b_e <= b[62:52];
                    a_s <= a[63];
                    //b_s <= b[63];
                    z_s <= a[63]; // XOR signs for multiplication
                    state <= cases_half;
                end

                cases_half: begin
                    if (a_e == 11'h7FF) begin
                        // NaN case
                        z <= {a_s, 11'h7FF, a_m[51:0]};
                        state <= put_z;
                    end else if (a[62:52] == 11'd0) begin
                        // Zero case
                        z_e <= a[62:52];
						z_m <= a_m >> 1;
                        state <= pack;
					end else if (a[62:52] == 11'd1) begin
                        z_e <= 64'b0;
						z_m <= a_m >> 1;
                        state <= pack;
                    end else begin
						z_e <= a_e - 1;
						z_m <= a_m;
                        state <= pack;
                    end
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
