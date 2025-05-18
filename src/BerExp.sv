`include "../src/long_to_double.v"
`include "../src/fpr_expm_p63.sv"

module BerExp (
    input wire [7:0] prng_get_u8,
    output wire prng_get_u8_ack,
    input wire prng_get_u8_stb,
    output wire get_u8,
	input wire clk,
	input wire rst,
	input wire x_stb,
    input wire ccs_stb,
	input wire [63:0] x,
	input wire [63:0] ccs,
    output wire x_ack,
    output wire ccs_ack,
    output wire b,
    output wire b_stb,
    input wire b_ack
);

 wire [31:0] s;
 wire [63:0] r;
 wire s_stb, s_ack, r_ack, r_stb;
 assign r_stb = s_stb;
 wire rst_1;
 assign rst_1 = rst /*|| !x_stb*/;

CalcSandR CalcSandR_inst(
	.clk(clk),
	.rst(rst_1),
	.x_stb(x_stb),
	.s_ack(s_ack), // TODO
	.r_ack(r_ack), 
	.x(x),
	.ccs(ccs),
	.s(s),
	.r(r),
	.s_stb(s_stb),
	.x_ack(x_ack)
);
wire y_fpr_expm_p63_stb, y_fpr_expm_p63_ack;
wire [63:0] y_fpr_expm_p63;
fpr_expm_p63 fpr_expm_p63_inst(
	.d(r),
	.ccs(ccs),
	.d_stb(r_stb),
	.ccs_stb(ccs_stb),
	.y_ack(y_fpr_expm_p63_ack), // TODO
	.y(y_fpr_expm_p63), // TODO
	.y_stb(y_fpr_expm_p63_stb), // TODO
	.d_ack(r_ack),
	.ccs_ack(ccs_ack),
	.clk(clk),
	.rst(rst_1)
);

SampleBit SampleBit_inst(
    .clk(clk),
    .rst(rst),
    .y_fpr_expm_p63(y_fpr_expm_p63),
    .y_fpr_expm_p63_stb(y_fpr_expm_p63_stb),
    .prng_get_u8(prng_get_u8),
    .prng_get_u8_stb(prng_get_u8_stb),
    .s(s_stb ? s : 0),
    .s_ack(s_ack),
    .y_fpr_expm_p63_ack(y_fpr_expm_p63_ack),
    .prng_get_u8_ack(prng_get_u8_ack),
    .get_u8(get_u8),
    .b(b),
    .b_stb(b_stb),
    .b_ack(b_ack),
    .s_stb(s_stb)
);






endmodule

module SampleBit (
    input wire clk,
    input wire rst,
    input wire [63:0] y_fpr_expm_p63,
    input wire y_fpr_expm_p63_stb,
    input wire [7:0] prng_get_u8,
    input wire prng_get_u8_stb,
    input wire [31:0] s,
    output reg s_ack,
    output reg y_fpr_expm_p63_ack,
    output reg prng_get_u8_ack,
    output reg get_u8,
    output reg b,
    output reg b_stb,
    input wire b_ack,
    input wire s_stb
);
parameter IDLE = 0, GET_U8 = 1, COMPUTE = 2, DONE = 3;
wire [5:0] s_trunc;
assign s_trunc = s[5:0];

reg [63:0] z;
always@(*) begin
    z = ({y_fpr_expm_p63[62:0], 1'b0} - 1) >> s_trunc;
end

reg prng_get_u8_stb_reg;
always@(posedge clk) begin
    if (rst) begin
        prng_get_u8_stb_reg <= 0;
    end else begin
        prng_get_u8_stb_reg <= prng_get_u8_stb;
    end
end

reg [6:0] i;
always@(posedge clk) begin
    if (rst) begin
        i <= 0;
    end else if (y_fpr_expm_p63_stb) begin
        i <= 56;
    end else if (prng_get_u8_stb_reg && !prng_get_u8_stb) begin
        i <= i - 8;
    end
end

reg [31:0] w;
always@(*) begin
    w = prng_get_u8_reg - ((z >> i) & 255);
    b = w[31] & s_stb;
end

reg [7:0] prng_get_u8_reg;
always@(posedge clk) begin
    if (rst) begin
        prng_get_u8_reg <= 0;
    end else if (prng_get_u8_stb) begin
        prng_get_u8_reg <= prng_get_u8;
    end
end

reg [3:0] state, next_state;
always@(posedge clk) begin
    if (rst) begin
        state <= 0;
    end else  begin
        state <= next_state;
    end
end

always@(*) begin
    case (state)
        IDLE: begin
            y_fpr_expm_p63_ack = 0;
            prng_get_u8_ack = 0;
            get_u8 = 0;
            b_stb = 0;
            s_ack = 0;
            if (y_fpr_expm_p63_stb && b_ack) begin
                s_ack = 1;
                y_fpr_expm_p63_ack = 1;
                next_state = GET_U8;
            end else begin
                next_state = IDLE;
            end
        end
        GET_U8: begin
            s_ack = 0;
            y_fpr_expm_p63_ack = 0;
            prng_get_u8_ack = 0;
            get_u8 = 1;
            b_stb = 0;
            if (prng_get_u8_stb) begin
                prng_get_u8_ack = 1;
                next_state = COMPUTE;
                get_u8 = 0;
            end else begin
                next_state = GET_U8;
            end
        end
        COMPUTE: begin
            s_ack = 0;
            y_fpr_expm_p63_ack = 0;
            prng_get_u8_ack = 0;
            get_u8 = 0;
            b_stb = 0;
            if (w != 0 || i == 0) begin
                next_state = DONE;
            end else begin
                next_state = COMPUTE;
            end
        end
        DONE: begin
            s_ack = 0;
            y_fpr_expm_p63_ack = 0;
            prng_get_u8_ack = 0;
            get_u8 = 0;
            b_stb = 1;
            next_state = IDLE;
        end
        default: begin
            s_ack = 0;
            y_fpr_expm_p63_ack = 0;
            prng_get_u8_ack = 0;
            get_u8 = 0;
            b_stb = 0;
            next_state = IDLE;
        end
    endcase
end


endmodule

module CalcSandR (
	input wire clk,
	input wire rst,
	input wire x_stb,
    input wire s_ack,
    input wire r_ack,
	input wire [63:0] x,
	input wire [63:0] ccs,
	output reg [31:0] s,
	output wire [63:0] r,
    output reg s_stb,
    output wire x_ack
);
parameter fpr_inv_log2 = 64'h3ff71547652b82fe;
parameter fpr_log2 = 64'h3fe62e42fefa39ef;
wire input_a_ack_trunc; 
wire [63:0] output_z_mul_inv_log2, output_z_trunc;
wire output_z_stb_mul_inv_log2, output_z_stb_trunc;
wire input_b_ack_mul_inv_log2;
// fpr_mul(x, fpr_inv_log2)
double_multiplier  double_multiplier_inst(
        .input_a(x),
        .input_b(fpr_inv_log2),
        .input_a_stb(x_stb), // stb to this multiplier
        .input_b_stb(1'b1), // stb to this multiplier
        .output_z_ack(input_a_ack_trunc), // ack from the next module
        .clk(clk),
        .rst(rst),
        .output_z(output_z_mul_inv_log2), // output to next module
        .output_z_stb(output_z_stb_mul_inv_log2), // stb to next module
        .input_a_ack(x_ack), // ack to previous module
        .input_b_ack(input_b_ack_mul_inv_log2)); // ack to previous module

// fpr_trunc(fpr_mul(x, fpr_inv_log2))
double_to_long double_to_long_inst(
        .input_a(output_z_mul_inv_log2),
        .input_a_stb(output_z_stb_mul_inv_log2), // stb to this module
        .output_z_ack(input_a_ack_of_s), // ack from the next module
        .clk(clk),
        .rst(rst),
        .output_z(output_z_trunc), // output to next module
        .output_z_stb(output_z_stb_trunc), // stb to next module
        .input_a_ack(input_a_ack_trunc)); // ack to previous module

wire [63:0] output_z_of_s, output_z_mul_log2;
wire output_z_stb_of_s, output_z_stb_mul_log2, input_a_ack_of_s, input_a_ack_mul_log2;

// fpr_of(s)
long_to_double long_to_double_inst(
        .input_a(output_z_trunc), // input from previous module
        .input_a_stb(output_z_stb_trunc), // stb to this module
        .output_z_ack(input_a_ack_mul_log2), // ack from the next module
        .clk(clk),
        .rst(rst),
        .output_z(output_z_of_s), // output to next module
        .output_z_stb(output_z_stb_of_s), // stb to next module
        .input_a_ack(input_a_ack_of_s)); // ack to previous module

wire [63:0] output_z_sub;
wire output_z_stb_sub, input_a_ack_sub, input_b_ack_sub, input_b_ack_mul_log2;
// fpr_mul(fpr_of(s), fpr_log2) 
double_multiplier  double_multiplier_inst2(
        .input_a(output_z_of_s),
        .input_b(fpr_log2),
        .input_a_stb(output_z_stb_of_s), // stb to this multiplier
        .input_b_stb(1'b1), // stb to this multiplier
        .output_z_ack(input_b_ack_sub), // ack from the next module
        .clk(clk),
        .rst(rst),
        .output_z(output_z_mul_log2), // output to next module
        .output_z_stb(output_z_stb_mul_log2), // stb to next module
        .input_a_ack(input_a_ack_mul_log2), // ack to previous module
        .input_b_ack(input_b_ack_mul_log2)); // ack to previous module

// fpr_sub(x, fpr_mul(fpr_of(s), fpr_log2))
reg x_stb_reg;
always@(posedge clk) begin
    if (rst) begin
        x_stb_reg <= 0;
    end else begin
        x_stb_reg <= x_stb;
    end
end
double_adder double_adder_inst(
        .input_a(x),
        .input_b(output_z_mul_log2),
        .input_a_stb(x_stb), // stb to this adder
        .input_b_stb(output_z_stb_mul_log2), // stb to this adder
        .sub(1'b1), // sub to this adder
        .output_z_ack(r_ack & s_ack), // TODO NOT SURE => FIX to !x_stb?
        .clk(clk),
        .rst(rst),
        .output_z(output_z_sub), // output to next module
        .output_z_stb(output_z_stb_sub), // stb to next module
        .input_a_ack(input_a_ack_sub), // ack to previous module
        .input_b_ack(input_b_ack_sub)); // ack to previous module

assign r = output_z_sub;

always@(*) begin
    s_stb = output_z_stb_sub;
end
// Calculate sw -> s
reg [31:0] sw;
reg [31:0] temp;
always@(*) begin
    sw = output_z_trunc[31:0];
    temp = 63 - sw;
    sw = (sw ^ temp) & (temp[31] ? 32'hffffffff : 32'h00000000);
    s = sw ^ output_z_trunc[31:0];
end


endmodule
