`include "../src/long_to_double.v"
`include "../src/double_multiplier.v"
`include "../src/double_adder.v"

module Calx(
    input clk,
    input rst,
    input stb, // Receive stb from previous stage
    output ack, // Send ack to previous stage
    input [63:0] z, // integer z
    input [63:0] r, // double r
    input [63:0] dss, // double dss
    input [63:0] z0square, // integer z0square
    output [63:0] x, // double x
    output x_stb, // Send stb to next stage
    input x_ack // Receive ack from next stage
    
);

// define constants
parameter [63:0] fpr_inv_2sqrsigma0 = 64'h3fc34f8bc183bbc2;

wire [63:0] z_double;
wire [63:0] z0square_double;
wire z_double_stb;
wire z0square_double_stb;
wire z_double_ack;
wire z0square_double_ack;

wire z0square_ack;
wire z_ack;
assign ack = z_ack & z0square_ack;

wire [63:0] z_double_minus_r;
wire z_double_minus_r_stb;
wire z_double_minus_r_ack_a;
wire z_double_minus_r_ack_b;

// Multiply z_double_minus_r by itself
wire [63:0] z_double_minus_r_squared;
wire z_double_minus_r_squared_stb;
wire z_double_minus_r_squared_ack_a;
wire z_double_minus_r_squared_ack_b;

// Multiply z0square_double by dss
wire [63:0] z0square_double_times_dss;
wire z0square_double_times_dss_stb;
wire z0square_double_times_dss_ack_a;
wire z0square_double_times_dss_ack_b;

wire zsquare_double_times_dss_times_fpr_inv_2sqrsigma0_ack_a;
wire zsquare_double_times_dss_times_fpr_inv_2sqrsigma0_ack_b;

// Multiply z0square_double by fpr_inv_2sqrsigma0
wire [63:0] z0square_double_times_fpr_inv_2sqrsigma0;
wire z0square_double_times_fpr_inv_2sqrsigma0_stb;
wire z0square_double_times_fpr_inv_2sqrsigma0_ack_a;
wire z0square_double_times_fpr_inv_2sqrsigma0_ack_b;

// convert integer z to double
long_to_double long_to_double_inst(
        .input_a(z),
        .input_a_stb(stb), // stb to this stage
        .output_z_ack(z_double_minus_r_ack_a), // ack from next stage
        .clk(clk),
        .rst(rst),
        .output_z(z_double),
        .output_z_stb(z_double_stb), // send stb to next stage
        .input_a_ack(z_ack)); // send ack to previous stage


// subtract r from z_double
double_adder double_adder_inst(
        .input_a(z_double),
        .input_b(r),
        .input_a_stb(z_double_stb), // stb to this stage
        .input_b_stb(1'b1), // stb to this stage
        .sub(1'b1),
        .output_z_ack(z_double_minus_r_squared_ack_a), // ack from next stage
        .clk(clk),
        .rst(rst),
        .output_z(z_double_minus_r),
        .output_z_stb(z_double_minus_r_stb), // send stb to next stage
        .input_a_ack(z_double_minus_r_ack_a), // send ack to previous stage
        .input_b_ack(z_double_minus_r_ack_b)); // send ack to previous stage


double_multiplier double_multiplier_inst(
        .input_a(z_double_minus_r),
        .input_b(z_double_minus_r),
        .input_a_stb(z_double_minus_r_stb), // stb to this stage
        .input_b_stb(1'b1), // stb to this stage
        .output_z_ack(z0square_double_times_dss_ack_a), // ack from next stage
        .clk(clk),
        .rst(rst),
        .output_z(z_double_minus_r_squared),
        .output_z_stb(z_double_minus_r_squared_stb), // send stb to next stage
        .input_a_ack(z_double_minus_r_squared_ack_a), // send ack to previous stage
        .input_b_ack(z_double_minus_r_squared_ack_b)); // send ack to previous stage


double_multiplier double_multiplier_inst_z0square_times_dss(
        .input_a(z_double_minus_r_squared),
        .input_b(dss),
        .input_a_stb(z_double_minus_r_squared_stb), // stb to this stage
        .input_b_stb(1'b1), // stb to this stage
        .output_z_ack(zsquare_double_times_dss_times_fpr_inv_2sqrsigma0_ack_a), // ack from next stage
        .clk(clk),
        .rst(rst),
        .output_z(z0square_double_times_dss),
        .output_z_stb(z0square_double_times_dss_stb), // send stb to next stage
        .input_a_ack(z0square_double_times_dss_ack_a), // send ack to previous stage
        .input_b_ack(z0square_double_times_dss_ack_b)); // send ack to previous stage

long_to_double long_to_double_inst_z0square(
        .input_a(z0square), 
        .input_a_stb(stb), // stb to this stage
        .output_z_ack(z0square_double_times_fpr_inv_2sqrsigma0_ack_a), // ack from next stage
        .clk(clk),
        .rst(rst),
        .output_z(z0square_double),
        .output_z_stb(z0square_double_stb), // send stb to next stage
        .input_a_ack(z0square_ack)); // send ack to previous stage


double_multiplier double_multiplier_inst_z0square_double_times_fpr_inv_2sqrsigma0(
        .input_a(z0square_double),
        .input_b(fpr_inv_2sqrsigma0),
        .input_a_stb(z0square_double_stb), // stb to this stage
        .input_b_stb(1'b1), // stb to this stage
        .output_z_ack(z0square_double_times_dss_ack_b), // ack from next stage
        .clk(clk),
        .rst(rst),
        .output_z(z0square_double_times_fpr_inv_2sqrsigma0),
        .output_z_stb(z0square_double_times_fpr_inv_2sqrsigma0_stb), // send stb to next stage
        .input_a_ack(z0square_double_times_fpr_inv_2sqrsigma0_ack_a), // send ack to previous stage
        .input_b_ack(z0square_double_times_fpr_inv_2sqrsigma0_ack_b)); // send ack to previous stage

// Subtract z0square_double_times_fpr_inv_2sqrsigma0 from z0square_double_times_dss

double_adder double_adder_inst_z0square_double_times_dss_minus_z0square_double_times_fpr_inv_2sqrsigma0(
        .input_a(z0square_double_times_dss),
        .input_b(z0square_double_times_fpr_inv_2sqrsigma0),
        .input_a_stb(z0square_double_times_dss_stb), // stb to this stage
        .input_b_stb(1'b1), // stb to this stage
        .sub(1'b1),
        .output_z_ack(x_ack), // ack from next stage
        .clk(clk),
        .rst(rst),
        .output_z(x),
        .output_z_stb(x_stb), // send stb to next stage
        .input_a_ack(zsquare_double_times_dss_times_fpr_inv_2sqrsigma0_ack_a), // send ack to previous stage
        .input_b_ack(zsquare_double_times_dss_times_fpr_inv_2sqrsigma0_ack_b)); // send ack to previous stage

endmodule