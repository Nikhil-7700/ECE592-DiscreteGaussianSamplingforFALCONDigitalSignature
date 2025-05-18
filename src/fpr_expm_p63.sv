`timescale 1ns/1ps
`include "../src/double_multiplier.v"
`include "../src/double_adder.v"
`include "../src/double_to_long.v"

module fpr_expm_p63 (
	input [63:0] d,
	input [63:0] ccs,
	input d_stb,
	input ccs_stb,
	input y_ack,
	output reg [63:0] y,
	output y_stb,
	output d_ack,
	output ccs_ack,
	input clk,
	input rst
);
wire [63:0] y_mux3_i1;
wire [63:0] y_mux3_i2;
wire [63:0] y_mux13;
wire [63:0] z_mul, z_sub;
wire [1:0] sel_mux3_i1, sel_mux3_i2;
wire [3:0] sel_mux13;

// Signal under control of state machine
// sel_mux3_i1, sel_mux3_i2, sel_mux13
// input_a_stb_mul, input_b_stb_mul, output_z_ack_mul
// input_a_stb_sub, input_b_stb_sub, output_z_ack_sub
// y_stb, d_ack, ccs_ack


mux3 #(64) mux3_inst_input_mul_1 (
	.d0(64'h3e21d0460e8dcd27),  // 0.000000002073772366009083
	.d1(z_sub),
	.d2(z_mul),
	.sel(sel_mux3_i1),
	.y(y_mux3_i1)
);

mux3 #(64) mux3_inst_input_sub_1 (
	.d0(d),
	.d1(ccs),
	.d2(64'h43e0000000000000),
	.sel(sel_mux3_i2),
	.y(y_mux3_i2)
);

wire input_a_stb_mul, input_b_stb_mul, output_z_ack_mul;
wire input_a_ack_mul, input_b_ack_mul, output_z_stb_mul;
wire input_a_stb_sub, input_b_stb_sub, output_z_ack_sub;
wire input_a_ack_sub, input_b_ack_sub, output_z_stb_sub;

double_multiplier double_multiplier_inst (
        .input_a(y_mux3_i1),
        .input_b(y_mux3_i2),
        .input_a_stb(input_a_stb_mul), // stb to this stage
        .input_b_stb(input_b_stb_mul), // stb to this stage
        .output_z_ack(output_z_ack_sub), // ack from next stage
        .clk(clk),
        .rst(rst),
        .output_z(z_mul),
        .output_z_stb(output_z_stb_mul), // send stb to next stage
        .input_a_ack(input_a_ack_mul), // send ack to previous stage
        .input_b_ack(input_b_ack_mul)); // send ack to previous stage

mux13 #(64) mux13_inst_input_sub_1 (
	.d0(64'h3e5b2a467e033000),  // 0.000000025299506379442070
	.d1(64'h3e927ee5f8a05035),  // 0.000000275607356160477812
	.d2(64'h3ec71d939de045c4),  // 0.000002755586350219122515
	.d3(64'h3efa019eb1edf088),  // 0.000024801566833585381210
	.d4(64'h3f2a01a073de5b8f),  // 0.000198412739277311890541
	.d5(64'h3f56c16c182d87f5),  // 0.001388888894063186997888
	.d6(64'h3f81111110e066fd),  // 0.008333333327800835146904
	.d7(64'h3fa5555555541c3c),  // 0.041666666666110491190622
	.d8(64'h3fc55555555581ff),  // 0.166666666666984014666397
	.d9(64'h3fe00000000000ad), // 0.500000000000019206858326
	.d10(64'h3fefffffffffffd2), // 0.999999999999994892974087
	.d11(64'h3ff0000000000000), // 1.000000000000000000000000
	.sel(sel_mux13),
	.y(y_mux13)
);

double_adder double_adder_inst (
        .input_a(y_mux13),
        .input_b(z_mul),
        .input_a_stb(input_a_stb_sub), // stb to this stage
        .input_b_stb(input_b_stb_sub), // stb to this stage
        .output_z_ack(output_z_ack_mul), // ack from next stage
        .sub(1'b1),
        .clk(clk),
        .rst(rst),
        .output_z(z_sub),
        .output_z_stb(output_z_stb_sub), // send stb to next stage
        .input_a_ack(input_a_ack_sub), // send ack to previous stage
        .input_b_ack(input_b_ack_sub)); // send ack to previous stage

wire input_a_stb_conv, output_z_stb_conv;
wire [63:0] y_temp;
always@(posedge clk) begin
    if (rst) begin
        y <= 0;
    end else if (output_z_stb_conv) begin
        y <= y_temp;
    end
end

double_to_long double_to_long_inst (
	.input_a(z_mul),
	.input_a_stb(input_a_stb_conv),
	.output_z_ack(y_ack),
	.clk(clk),
	.rst(rst),
	.output_z(y_temp),
	.output_z_stb(output_z_stb_conv)
);

fsm_expm_p63 fsm_expm_p63_inst (
	.clk(clk),
	.rst(rst),
	.d_stb(d_stb),
	.ccs_stb(ccs_stb),
	.y_ack(y_ack),
	.output_z_stb_mul(output_z_stb_mul),
	.output_z_stb_sub(output_z_stb_sub),
	.output_z_stb_conv(output_z_stb_conv),
	.input_a_ack_mul(input_a_ack_mul),
	.input_b_ack_mul(input_b_ack_mul),
	.input_a_ack_sub(input_a_ack_sub),
	.input_b_ack_sub(input_b_ack_sub),
	.sel_mux3_i1(sel_mux3_i1),
	.sel_mux3_i2(sel_mux3_i2),
	.sel_mux13(sel_mux13),
	.input_a_stb_mul(input_a_stb_mul),
	.input_b_stb_mul(input_b_stb_mul),
	.input_a_stb_sub(input_a_stb_sub),
	.input_b_stb_sub(input_b_stb_sub),
	.input_a_stb_conv(input_a_stb_conv),
	.output_z_ack_mul(output_z_ack_mul),
	.output_z_ack_sub(output_z_ack_sub),
	.y_stb(y_stb),
	.d_ack(d_ack),
	.ccs_ack(ccs_ack)
);

endmodule

module fsm_expm_p63 (
	input clk,
	input rst,
	input d_stb,
	input ccs_stb,
	input y_ack,
	input output_z_stb_mul,
	input output_z_stb_sub,
	input output_z_stb_conv,
	input input_a_ack_mul,
	input input_b_ack_mul,
	input input_a_ack_sub,
	input input_b_ack_sub,
	output reg [1:0] sel_mux3_i1,
	output reg [1:0] sel_mux3_i2,
	output reg [3:0] sel_mux13,
	output reg input_a_stb_mul,
	output reg input_b_stb_mul,
	output reg input_a_stb_sub,
	output reg input_b_stb_sub,
	output reg input_a_stb_conv,
	output reg output_z_ack_mul,
	output reg output_z_ack_sub,
	output reg y_stb,
	output reg d_ack,
	output reg ccs_ack
);
parameter IDLE = 0;
parameter MUL_1 = 1;
parameter SUB_1 = 2;
parameter CONV = 3;
parameter FINAL = 4;
reg [3:0] state;
reg [3:0] next_state;
always@(posedge clk) begin
	if (rst) begin
		state <= 0;
	end else begin
		state <= next_state;
	end
end

reg output_z_stb_sub_reg, output_z_stb_mul_reg;

always @(posedge clk) begin
	if (rst) begin
		output_z_stb_sub_reg <= 0;
		output_z_stb_mul_reg <= 0;
	end else begin
		output_z_stb_sub_reg <= output_z_stb_sub;
		output_z_stb_mul_reg <= output_z_stb_mul;
	end
end

reg [3:0] sel_mux13_reg;

always @(posedge clk) begin
	if (rst) begin
		sel_mux13_reg <= 0;
	end else if (output_z_stb_sub && !output_z_stb_sub_reg) begin
		sel_mux13_reg <= sel_mux13_reg + 1;
	end
end

reg [3:0] sel_mux3_i1_reg;
always @(posedge clk) begin
	if (rst || y_stb) begin
		sel_mux3_i1_reg <= 0;
	end else if (output_z_stb_mul && !output_z_stb_mul_reg) begin
		sel_mux3_i1_reg <= sel_mux3_i1_reg + 1;
	end
end

always@(*) begin
	output_z_ack_mul = 0;
	output_z_ack_sub = 0;
	ccs_ack = 0;
	d_ack = 0;
	case (state)
		IDLE: begin
			input_a_stb_conv = 0;
			input_a_stb_sub = 0;
			input_b_stb_sub = 0;
			sel_mux13 = 0;
			sel_mux3_i1 = 0;
			sel_mux3_i2 = 0;
			input_a_stb_mul = 0;
			input_b_stb_mul = 0;
			d_ack = 0;
			ccs_ack = 0;
			y_stb = 0;
			next_state = IDLE;
			if (d_stb && ccs_stb) begin
				next_state = MUL_1;
				d_ack = 1;
				ccs_ack = 1;
			end
		end
		MUL_1: begin
			input_a_stb_conv = 0;
			output_z_ack_mul = 1;
			y_stb = 0;
			sel_mux13 = sel_mux13_reg;
			sel_mux3_i1 = 0;
			sel_mux3_i2 = 0;
			input_a_stb_sub = 0;
			input_b_stb_sub = 0;
			input_a_stb_mul = 0;
			input_b_stb_mul = 0;
			next_state = MUL_1;
			if (output_z_stb_mul && input_a_ack_sub && sel_mux3_i1_reg < 12) begin
				next_state = SUB_1;
				input_a_stb_mul = 0;
				input_b_stb_mul = 0;
			end else if (sel_mux3_i1_reg == 14) begin
				next_state = CONV;
				input_a_stb_mul = 0;
				input_b_stb_mul = 0;
			end else begin
				input_a_stb_mul = 1;
				input_b_stb_mul = 1;
				sel_mux3_i1 = sel_mux3_i1_reg == 0 ? 2'd0 : (sel_mux3_i1_reg < 13 ? 2'd1 : 2'd2);
				sel_mux3_i2 = sel_mux3_i1_reg < 12 ? 2'd0 : (sel_mux3_i1_reg == 12 ? 2'd1 : 2'd2);
			end
		end
		SUB_1: begin
			input_a_stb_conv = 0;
			output_z_ack_sub = 1;
			input_a_stb_sub = 0;
			input_b_stb_sub = 0;
			input_a_stb_mul = 0;
			input_b_stb_mul = 0;
			sel_mux13 = sel_mux13_reg;
			sel_mux3_i1 = 0;
			sel_mux3_i2 = 0;
			y_stb = 0;
			next_state = SUB_1;
			if (output_z_stb_sub && input_a_ack_mul) begin
				next_state = MUL_1;
				input_a_stb_sub = 0;
				input_b_stb_sub = 0;
			end else begin
				input_a_stb_sub = 1;
				input_b_stb_sub = 1;
				sel_mux13 = sel_mux13_reg;
			end
		end
		CONV: begin
			input_a_stb_conv = 1;
			input_a_stb_sub = 0;
			input_b_stb_sub = 0;
			input_a_stb_mul = 0;
			input_b_stb_mul = 0;
			sel_mux13 = sel_mux13_reg;
			sel_mux3_i1 = 0;
			sel_mux3_i2 = 0;
			y_stb = 0;
			next_state = CONV;
			if (output_z_stb_conv) begin
				next_state = FINAL;
				input_a_stb_conv = 0;
			end
		end
		FINAL: begin
			input_a_stb_conv = 0;
			input_a_stb_sub = 0;
			input_b_stb_sub = 0;
			input_a_stb_mul = 0;
			input_b_stb_mul = 0;
			sel_mux13 = sel_mux13_reg;
			sel_mux3_i1 = 0;
			sel_mux3_i2 = 0;
			y_stb = 1;
			next_state = FINAL;
			if (y_ack) begin
				next_state = IDLE;
			end
		end
		default: begin
			input_a_stb_conv = 0;
			input_a_stb_sub = 0;
			input_b_stb_sub = 0;
			sel_mux13 = 0;
			sel_mux3_i1 = 0;
			sel_mux3_i2 = 0;
			input_a_stb_mul = 0;
			input_b_stb_mul = 0;
			y_stb = 0;
			next_state = IDLE;
		end
	endcase
end

endmodule

module mux13 #(parameter WIDTH = 64) (
	input [WIDTH-1:0] d0,
	input [WIDTH-1:0] d1,
	input [WIDTH-1:0] d2,
	input [WIDTH-1:0] d3,
	input [WIDTH-1:0] d4,
	input [WIDTH-1:0] d5,
	input [WIDTH-1:0] d6,
	input [WIDTH-1:0] d7,
	input [WIDTH-1:0] d8,
	input [WIDTH-1:0] d9,
	input [WIDTH-1:0] d10,
	input [WIDTH-1:0] d11,
	input [3:0] sel,
	output reg [WIDTH-1:0] y
);

always@(*) begin
	case (sel)
		4'd0: y = d0;
		4'd1: y = d1;
		4'd2: y = d2;
		4'd3: y = d3;
		4'd4: y = d4;
		4'd5: y = d5;
		4'd6: y = d6;
		4'd7: y = d7;
		4'd8: y = d8;
		4'd9: y = d9;
		4'd10: y = d10;
		4'd11: y = d11;
		default: y = 0;
	endcase
end

endmodule

module mux3 #(parameter WIDTH = 64) (
	input [WIDTH-1:0] d0,
	input [WIDTH-1:0] d1,
	input [WIDTH-1:0] d2,
	input [1:0] sel,
	output reg [WIDTH-1:0] y
);

always@(*) begin
	case (sel)
		2'd0: y = d0;
		2'd1: y = d1;
		2'd2: y = d2;
		default: y = 0;
	endcase
end

endmodule
