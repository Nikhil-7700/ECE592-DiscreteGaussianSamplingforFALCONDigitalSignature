//`include "fpr_mul.v"
//`include "fpr_floor.v"
//`include "fpr_toInt.v"
//`include "fpr_sub.v"

module sampler_sw (
    input wire clk,                   // Clock signal
    input wire rst,                   // Reset signal
    input wire valid_in,              // Input valid signal
    input wire [63:0] mu,             // Input: mu (floating-point)
    input wire [63:0] isigma,         // Input: isigma (floating-point)
    input wire [63:0] sigma_min,      // Input: sigma_min (floating-point)
    output reg [63:0] r,              // Output: fractional part of mu
    output reg [63:0] dss,            // Output: dss = 0.5 * isigma^2
    output reg [63:0] ccs,            // Output: ccs = isigma * sigma_min
    output reg [63:0] s_fpr,          // Output: floating-point integer part
    output reg [31:0] s_int,          // Output: integer part of mu
    output reg valid_out              // Output valid signal
);

    // FSM States
	reg [3:0] state;
    parameter IDLE          = 4'd0,
              START_FLOOR   = 4'd1,
              WAIT_FLOOR 	= 4'd2,
              START_TO_INT  = 4'd3,
              WAIT_TO_INT   = 4'd4,
              START_SUB     = 4'd5,
			  WAIT_SUB		= 4'd6,
			  START_MUL1	= 4'd7,			  
			  WAIT_MUL1		= 4'd8, 
			  START_MUL2	= 4'd9, 
			  WAIT_MUL2		= 4'd10, 
			  START_MUL3	= 4'd11, 
			  WAIT_MUL3		= 4'd12, 
			  OUTPUT		= 4'd13;

    // Intermediate signals
    wire [63:0] floor_result;
    wire floor_done;
    reg floor_start;

    wire [63:0] toInt_result;
    wire toInt_done;
    reg toInt_start;
	wire invalid_flag;

    wire [63:0] sub_result;
    wire sub_done;
    reg sub_start;

    wire [63:0] mul1_result;
    wire mul1_done;
    reg mul1_start;

    wire [63:0] mul2_result;
    wire mul2_done;
    reg mul2_start;

    wire [63:0] mul3_result;
    wire mul3_done;
    reg mul3_start;

    // Floating-Point Module Instances
    fpr_floor floor_op (
        .a(mu),
        .clk(clk),
        .rst(rst),
        .start(floor_start),
        .result(floor_result),
        .done(floor_done)
    );

    fpr_toInt toInt_op (
        .input_a(floor_result),
        .clk(clk),
        .rst(rst),
        .start(toInt_start),
        .result(toInt_result),
        .done(toInt_done),
		.invalid(invalid_flag)
    );

    fpr_sub sub_op (
        .input_a(mu),
        .input_b(s_fpr),
        .clk(clk),
        .rst(rst),
        .start(sub_start),
        .output_z(sub_result),
        .done(sub_done)
    );

    fpr_mul mul1 (
        .input_a(isigma),
        .input_b(isigma),
        .clk(clk),
        .rst(rst),
        .start(mul1_start),
        .output_z(mul1_result),
        .done(mul1_done)
    );

    fpr_mul mul2 (
        .input_a(mul1_result),
        .input_b(64'h3FE0000000000000), // 0.5 in IEEE-754 format
        .clk(clk),
        .rst(rst),
        .start(mul2_start),
        .output_z(mul2_result),
        .done(mul2_done)
    );

    fpr_mul mul3 (
        .input_a(isigma),
        .input_b(sigma_min),
        .clk(clk),
        .rst(rst),
        .start(mul3_start),
        .output_z(mul3_result),
        .done(mul3_done)
    );

    // FSM Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            s_int <= 0;
            s_fpr <= 0;
            r <= 0;
            dss <= 0;
            ccs <= 0;
            floor_start <= 0;
            toInt_start <= 0;
            sub_start <= 0;
            mul1_start <= 0;
            mul2_start <= 0;
            mul3_start <= 0;
            valid_out <= 0;
        end else begin
            case (state)
                IDLE: begin
                    valid_out <= 0;
                    if (valid_in) begin
                        floor_start <= 1;      // Start floor operation
                        state <= START_FLOOR;
                    end
                end
                START_FLOOR: begin
                    floor_start <= 0;         // Deassert start signal
                    state <= WAIT_FLOOR;     // Wait for floor to finish
                end
                WAIT_FLOOR: begin
                    if (floor_done) begin
                        s_fpr <= floor_result;    // Store floating-point result
                        toInt_start <= 1;        // Start floating-point to integer conversion
                        state <= START_TO_INT;
                    end
                end
                START_TO_INT: begin
                    toInt_start <= 0;         // Deassert start signal
                    state <= WAIT_TO_INT;    // Wait for conversion to finish
                end
                WAIT_TO_INT: begin
                    if (toInt_done) begin
                        s_int <= toInt_result;  // Store integer result
                        sub_start <= 1;         // Start subtraction
                        state <= START_SUB;
                    end
                end
                START_SUB: begin
                    sub_start <= 0;          // Deassert start signal
                    state <= WAIT_SUB;      // Wait for subtraction to finish
                end
                WAIT_SUB: begin
                    if (sub_done) begin
                        r <= sub_result;     // Store remainder
                        mul1_start <= 1;     // Start first multiplication
                        state <= START_MUL1;
                    end
                end
                START_MUL1: begin
                    mul1_start <= 0;         // Deassert start signal
                    state <= WAIT_MUL1;      // Wait for multiplication to finish
                end
                WAIT_MUL1: begin
                    if (mul1_done) begin
                        mul2_start <= 1;     // Start second multiplication (multiply by 0.5)
                        state <= START_MUL2;
                    end
                end
                START_MUL2: begin
                    mul2_start <= 0;         // Deassert start signal
                    state <= WAIT_MUL2;      // Wait for multiplication to finish
                end
                WAIT_MUL2: begin
                    if (mul2_done) begin
                        dss <= mul2_result;  // Store dss
                        mul3_start <= 1;     // Start third multiplication
                        state <= START_MUL3;
                    end
                end
                START_MUL3: begin
                    mul3_start <= 0;         // Deassert start signal
                    state <= WAIT_MUL3;      // Wait for multiplication to finish
                end
                WAIT_MUL3: begin
                    if (mul3_done) begin
                        ccs <= mul3_result;  // Store ccs
                        state <= OUTPUT;
                    end
                end
                OUTPUT: begin
                    valid_out <= 1;          // Signal that outputs are valid
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

