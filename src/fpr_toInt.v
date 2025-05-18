module fpr_toInt (
    input clk,                  // Clock signal
    input rst,                  // Reset signal
    input start,                // Start signal
    input [63:0] input_a,       // 64-bit IEEE 754 floating-point input
    output reg [63:0] result,   // 64-bit integer output
    output reg invalid,         // Invalid flag (e.g., NaN, infinity)
    output reg done             // Done signal
);

    // Internal Registers
    reg [63:0] temp_a;
    reg [51:0] mantissa;
    reg [10:0] exponent;
    reg [63:0] int_result;
    reg [11:0] shift_amount; // Increased width to handle larger shifts
    reg sign, is_nan, is_inf, is_zero;

    // FSM State Declaration
    reg [2:0] state;
    parameter IDLE          = 3'd0,
              UNPACK        = 3'd1,
              SPECIAL_CASES = 3'd2,
              CONVERT       = 3'd3,
              APPLY_SIGN    = 3'd4,
              DONE          = 3'd5;

    // FSM Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all signals
            state <= IDLE;
            result <= 64'b0;
            temp_a <= 64'b0;
            mantissa <= 52'b0;
            exponent <= 11'b0;
            int_result <= 64'b0;
            shift_amount <= 12'b0;
            sign <= 1'b0;
            is_nan <= 1'b0;
            is_inf <= 1'b0;
            is_zero <= 1'b0;
            invalid <= 0;
            done <= 0;
        end else begin
            case (state)

                IDLE: begin
                    done <= 0; // Deassert done
                    result <= 64'b0; // Clear result on restart
                    if (start) begin
                        temp_a <= input_a; // Capture input
                        state <= UNPACK;
                    end
                end

                UNPACK: begin
                    // Extract fields
                    sign <= temp_a[63];
                    exponent <= temp_a[62:52];
                    mantissa <= temp_a[51:0];

                    // Identify special cases
                    //is_zero <= (temp_a[62:0] == 0); // Zero
                    //is_inf <= (exponent == 11'h7FF) && (mantissa == 0); // Infinity
                    //is_nan <= (exponent == 11'h7FF) && (mantissa != 0); // NaN

                    state <= SPECIAL_CASES;
                end

                SPECIAL_CASES: begin
                    if (exponent == 11'h7FF) begin
                        // Handle NaN and Infinity
                        invalid <= 1; // Invalid result
                        result <= 64'hFFFFFFFFFFFFFFFF; // Set result to 0
                        state <= DONE;
                    end else if (exponent < 11'h3FF) begin
                        // Handle Zero
                        invalid <= 0; // Valid result
                        result <= 64'b0; // Zero remains zero
                        state <= DONE;
                    end else begin
                        // Normal case
                        // invalid <= 0;
                        //if (exponent != 0) begin
                            //mantissa <= {1'b1, mantissa}; // Add implicit leading 1
                        //end
			//int_result <= {1'b1, mantissa} >> (52 - (exponent - 1023));
			if (exponent - 1023 > 52) begin
				invalid <= 1;
				result <= 64'hFFFFFFFFFFFFFFFF;
				state <= DONE;
			end else begin
				invalid <= 0;
				int_result <= {1'b1, mantissa} >> (52 - (exponent - 1023));
				state <= APPLY_SIGN;
			end
                        state <= APPLY_SIGN;
                    end
                end

                CONVERT: begin
                    // Calculate the shift amount
                    if (exponent > 1023 + 63) begin
                        // Overflow
                        invalid <= 1;
                        int_result <= 64'b0;
                        state <= DONE;
                    end else if (exponent <= 1023) begin
                        // Underflow to zero
                        int_result <= 64'b0;
                        state <= APPLY_SIGN;
                    end else begin
                        shift_amount <= exponent - 1023 - 52;

                        if (shift_amount > 0) begin
                            int_result <= mantissa << shift_amount; // Shift left
                        end else begin
                            int_result <= mantissa >> (-shift_amount); // Shift right
                        end
                        state <= APPLY_SIGN;
                    end
                end

                APPLY_SIGN: begin
                    // Apply the sign bit
                    if (sign) begin
                        result <= -int_result;
                    end else begin
                        result <= int_result;
                    end
                    state <= DONE;
                end

                DONE: begin
                    done <= 1; // Signal that computation is complete
                    if (!start) state <= IDLE; // Wait for next computation
                end

            endcase
        end
    end

endmodule

