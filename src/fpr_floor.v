module fpr_floor (
    input clk,                   // Clock signal
    input rst,                   // Reset signal
    input start,                 // Start signal
    input [63:0] a,              // 64-bit double-precision input
    output reg [63:0] result,    // 64-bit double-precision output
    output reg done              // Done signal
);

    // Internal Registers
    reg [63:0] temp_a, temp_result;
    reg [51:0] mantissa, int_mantissa;
    reg [10:0] exponent, shift_amount;
    reg sign, has_fractional;

    reg [53:0] sum; // Used for summation and normalization

    // FSM State Declaration
    reg [2:0] state;
    parameter IDLE          = 3'd0,
              UNPACK        = 3'd1,
              SPECIAL_CASES = 3'd2,
              MASK_FRACTION = 3'd3,
              ADJUST_NEG    = 3'd4,
              NORM          = 3'd5,
              PACK          = 3'd6,
              DONE          = 3'd7;

    // FSM Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all signals
            state <= IDLE;
            result <= 64'b0;
            temp_a <= 64'b0;
            temp_result <= 64'b0;
            mantissa <= 52'b0;
            exponent <= 11'b0;
            shift_amount <= 11'b0;
            sign <= 1'b0;
            has_fractional <= 1'b0;
            sum <= 54'b0;
            done <= 0;
        end else begin
            case (state)
                // IDLE: Wait for the start signal
                IDLE: begin
                    done <= 0; // Deassert done
                    if (start) begin
                        temp_a <= a; // Capture input
                        state <= UNPACK;
                    end
                end

                // UNPACK: Extract IEEE 754 fields
                UNPACK: begin
                    sign <= temp_a[63];
                    exponent <= temp_a[62:52];
                    mantissa <= temp_a[51:0];
                    shift_amount <= temp_a[62:52] - 11'd1023;
                    state <= SPECIAL_CASES;
                end

                // SPECIAL_CASES: Handle zero, infinity, and NaN
                SPECIAL_CASES: begin
                    if (temp_a[62:0] == 0) begin
                        temp_result <= 64'b0; // Zero
                        state <= PACK;
                    end else if (exponent == 11'h7FF) begin
                        temp_result <= temp_a; // NaN or infinity: pass through
                        state <= PACK;
                    end else if (exponent < 11'd1023) begin
                        // Less than 1
                        temp_result <= sign ? 64'hBFF0000000000000 : 64'b0; // -1 or 0
                        state <= PACK;
                    end else begin
                        state <= MASK_FRACTION;
                    end
                end

                // MASK_FRACTION: Remove fractional bits
                MASK_FRACTION: begin
                    if (shift_amount >= 52) begin
                        // Already an integer
                        temp_result <= {sign, exponent, mantissa};
                        has_fractional <= 1'b0;
                    end else begin
                        // Mask fractional bits
                        int_mantissa <= mantissa & (~((1 << (52 - shift_amount)) - 1));
                        has_fractional <= |(mantissa & ((1 << (52 - shift_amount)) - 1)); // Check fractional bits
                        //temp_result <= {sign, exponent, int_mantissa};
                    end
                    state <= ADJUST_NEG;
                end

                // ADJUST_NEG: Handle negative numbers with fractional parts
                ADJUST_NEG: begin
                    if (sign && has_fractional) begin
                        // Add 1 to the mantissa for negative numbers with fractional parts
                        sum <= {1'b1, int_mantissa} + ({1'b1, 52'd0} >> (exponent-11'hBFF));
                        state <= NORM;
                    end else begin
						temp_result <= {sign, exponent, int_mantissa};
                        state <= PACK;
                    end
                end

                // NORM: Normalize the result if necessary
                NORM: begin
                    if (sum[53]) begin
                        temp_result <= {sign, exponent + 1, sum[52:1]}; // Handle carry/overflow
                    end else begin
                        temp_result <= {sign, exponent, sum[51:0]}; // No carry
                    end
                    state <= PACK;
                end

                // PACK: Combine the fields into IEEE 754 format
                PACK: begin
                    result <= temp_result; // Assign the final result
                    state <= DONE;
                end

                // DONE: Indicate completion and wait for next start
                DONE: begin
                    done <= 1; // Signal that computation is complete
                    state <= IDLE; // Wait for next computation
                end
            endcase
        end
    end

endmodule

