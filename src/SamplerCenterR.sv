`include "../src/ChaCha20.sv"
`include "../src/Calx.sv"
`include "../src/BerExp.sv"
`include "../src/BaseSampler.sv"

module SamplerCenterR (
    input wire clk,
    input wire reset,
    input wire start,
    input wire set,
    input wire [255:0] key,
    input wire [63:0] nonce,
    input wire [63:0] counter,
    input wire r_stb, // stb from the r module
    input wire [63:0] r,
    output wire r_ack, // ack to the r module
    input wire s_stb, // stb from the s module
    input wire [31:0] s,
    output wire s_ack, // ack to the s module
    input wire dss_stb, // stb from the dss module
    input wire [63:0] dss,
    output wire dss_ack, // ack to the dss module
    input wire ccs_stb, // stb from the ccs module
    input wire [63:0] ccs, 
    output wire ccs_ack, // ack to the ccs module
    input wire sample_ack, // ack from the next stage
    output wire [31:0] sample,
    output wire sample_stb // stb to the next stage
);

wire calz_get_u8; // fsm
wire calz_get_u64; // fsm
wire [7:0] u8;
wire u8_stb;
wire [63:0] u64;
wire u64_stb;
wire get_u8; // fsm
wire get_u64; //fsm
wire u8_stb_calz, u64_stb_calz;
wire calz_u8_ack, calz_u64_ack; // ack to Chacha20withBuffer module from fsm
wire start_fsm;
wire chacha20withBuffer_u8_stb, chacha20withBuffer_u64_stb;
wire chacha20withBuffer_u8_ack, chacha20withBuffer_u64_ack;
wire [63:0] z;
wire z_stb, z_ack;

ChaCha20withBuffer chacha20withBuffer (
    .clk(clk),
    .reset(reset),
    .get_u8(get_u8),
    .set(set),
    .key(key),
    .nonce_in(nonce),
    .counter_in(counter),
    .u8(u8),
    .u8_stb(chacha20withBuffer_u8_stb), // stb from the chacha20withBuffer module
    .get_u64(get_u64),
    .u64(u64),
    .u64_stb(chacha20withBuffer_u64_stb), // stb from the chacha20withBuffer module
    .u8_ack(chacha20withBuffer_u8_ack), // ack to the chacha20withBuffer module
    .u64_ack(chacha20withBuffer_u64_ack) // ack to the chacha20withBuffer module
);

Calz calz(
    .clk(clk),
    .rst(reset),
    .start(start_fsm),
    .u_64(u64),
    .u_64_stb(u64_stb_calz), // stb to the calz module
    .u_64_ack(calz_u64_ack), // ack from the calz module
    .get_u64(calz_get_u64), // fsm
    .u_8(u8),
    .u_8_stb(u8_stb_calz), // stb to the calz module
    .u_8_ack(calz_u8_ack), // ack from the calz module
    .get_u8(calz_get_u8), // fsm
    .z(z),
    .z_stb(z_stb),
    .z_ack(z_ack)
);
wire x_stb, x_ack;
wire [63:0] x, z0square;
assign z0square = z * z;
Calx calx(
    .clk(clk),
    .rst(reset),
    .stb(z_stb), // Receive stb from previous stage
    .ack(z_ack), // Send ack to previous stage
    .z(z), // integer z
    .r(r), // double r
    .dss(dss), // double dss
    .z0square(z0square), // integer z0square
    .x(x), // double x
    .x_stb(x_stb), // Send stb to next stage
    .x_ack(x_ack) // Receive ack from next stage
);

wire berExp_get_u8_ack;
wire berExp_get_u8_stb;
wire berExp_get_u8; // fsm
wire b, b_stb, b_ack; // fsm
BerExp berExp (
    .prng_get_u8(u8),
    .prng_get_u8_ack(berExp_get_u8_ack), // ack from the berExp module
    .prng_get_u8_stb(berExp_get_u8_stb), // stb to the berExp module
    .get_u8(berExp_get_u8), // output of the berExp module
	.clk(clk),
	.rst(reset),
	.x_stb(x_stb),
    .ccs_stb(ccs_stb),
	.x(x),
	.ccs(ccs),
    .x_ack(x_ack),
    .ccs_ack(ccs_ack),
    .b(b),
    .b_stb(b_stb),
    .b_ack(b_ack)
);


// fsm

fsm_samplerCenterR fsm_samplerCenterR(
    .clk(clk),
    .rst(reset),
    .calz_get_u8(calz_get_u8), // fsm
    .calz_get_u64(calz_get_u64), // fsm
    .berExp_get_u8(berExp_get_u8), // fsm
    .get_u8(get_u8), // fsm
    .get_u64(get_u64), // fsm
    .b(b),
    .b_stb(b_stb), // stb from the berExp module
    .b_ack(b_ack), // ack to the berExp module
    .start_fsm(start_fsm), // fsm
    .start(start), // start signal
    .u8_stb_calz(u8_stb_calz), // stb to the calz module
    .u64_stb_calz(u64_stb_calz), // stb to the calz module
    .berExp_get_u8_stb(berExp_get_u8_stb), // stb to the berExp module
    .chacha20withBuffer_u8_stb(chacha20withBuffer_u8_stb), // stb from the chacha20withBuffer module
    .chacha20withBuffer_u64_stb(chacha20withBuffer_u64_stb), // stb from the chacha20withBuffer module
    .chacha20withBuffer_u8_ack(chacha20withBuffer_u8_ack), // ack to the chacha20withBuffer module
    .chacha20withBuffer_u64_ack(chacha20withBuffer_u64_ack), // ack to the chacha20withBuffer module
    .calz_u8_ack(calz_u8_ack), // ack from the calz module
    .calz_u64_ack(calz_u64_ack), // ack from the calz module
    .berExp_get_u8_ack(berExp_get_u8_ack), // ack from the berExp module
    .ccs_ack(ccs_ack), // ack to the previous stage
    .ccs_stb(ccs_stb), // stb from the previous stage
    .dss_ack(dss_ack), // ack from the previous stage
    .dss_stb(dss_stb), // stb from the previous stage
    .s_ack(s_ack), // ack to the previous stage
    .s_stb(s_stb), // stb from the previous stage
    .r_ack(r_ack), // ack to the previous stage
    .r_stb(r_stb), // stb from the previous stage
    .sample_ack(sample_ack), // ack from the next stage
    .sample_stb() // stb to the next stage
);
assign sample = z[31:0] + s;
assign sample_stb = b;

endmodule

module fsm_samplerCenterR (
    input wire clk,
    input wire rst,
    input wire calz_get_u8,
    input wire calz_get_u64,
    input wire berExp_get_u8,
    output reg get_u8,
    output reg get_u64,
    input wire b,
    input wire b_stb,
    output reg b_ack, //
    output reg start_fsm, //
    input wire start,
    output reg u8_stb_calz, //
    output reg u64_stb_calz, //
    output reg berExp_get_u8_stb, //
    input wire chacha20withBuffer_u8_stb,
    input wire chacha20withBuffer_u64_stb,
    output reg chacha20withBuffer_u8_ack, //
    output reg chacha20withBuffer_u64_ack, //
    input wire calz_u8_ack,
    input wire calz_u64_ack,
    input wire berExp_get_u8_ack,
    output reg ccs_ack, //
    input wire ccs_stb, //
    output reg dss_ack, //
    input wire dss_stb, //
    output reg s_ack, //
    input wire s_stb, //
    output reg r_ack, //
    input wire r_stb, //
    input wire sample_ack, //
    output reg sample_stb //

);
reg [3:0] current_state, next_state;

parameter IDLE = 0;
parameter START = 1;
parameter CALZ_GET_U8 = 2;
parameter CALZ_GET_U64 = 3;
parameter BEREXP_GET_U8 = 4;
parameter DONE = 5;

always @(posedge clk) begin
    if (rst) begin
        current_state <= 0;
    end else begin
        current_state <= next_state;
    end
end

reg b_reg;

always@(posedge clk) begin
    if (rst) begin
        b_reg <= 0;
    end else if (b_stb) begin
        b_reg <= b;
    end
end

reg chacha20withBuffer_u8_ack_temp, chacha20withBuffer_u64_ack_temp, berExp_get_u8_stb_temp;
reg u8_stb_calz_temp, u64_stb_calz_temp, sample_stb_temp;
reg ccs_ack_temp, dss_ack_temp, s_ack_temp, r_ack_temp;
reg get_u8_temp, get_u64_temp, b_ack_temp;

always@(posedge clk) begin
    chacha20withBuffer_u8_ack <= chacha20withBuffer_u8_ack_temp;
    chacha20withBuffer_u64_ack <= chacha20withBuffer_u64_ack_temp;
    berExp_get_u8_stb <= berExp_get_u8_stb_temp;
    u8_stb_calz <= u8_stb_calz_temp;
    u64_stb_calz <= u64_stb_calz_temp;
    sample_stb <= sample_stb_temp;
    ccs_ack <= ccs_ack_temp;
    dss_ack <= dss_ack_temp;
    s_ack <= s_ack_temp;
    r_ack <= r_ack_temp;
    get_u8 <= get_u8_temp;
    get_u64 <= get_u64_temp;
    b_ack <= b_ack_temp;
end

always@(*) begin
    chacha20withBuffer_u8_ack_temp  = 0;
    chacha20withBuffer_u64_ack_temp = 0;
    berExp_get_u8_stb_temp = 0;
    next_state = IDLE;
    start_fsm = 0;
    b_ack = 0;
    u8_stb_calz_temp = 0;
    u64_stb_calz_temp = 0;
    sample_stb_temp = 0;
    ccs_ack_temp = 0;
    dss_ack_temp = 0;
    s_ack_temp = 0;
    r_ack_temp = 0;
    get_u8_temp = 0;
    get_u64_temp = 0;
    if (ccs_stb) begin
        ccs_ack_temp = 1;
    end
    if (dss_stb) begin
        dss_ack_temp = 1;
    end
    if (s_stb) begin
        s_ack_temp = 1;
    end
    if (r_stb) begin
        r_ack_temp = 1;
    end
    case (current_state)
        IDLE: begin
            next_state = IDLE;
            if (start) begin
                next_state = START;
                start_fsm = 1;
            end
        end
        START: begin
            next_state = START;
            get_u8_temp = 0;
            get_u64_temp = 0;
            if (b_stb && b_reg) begin
                next_state = DONE;
                b_ack_temp = 1;
            end else if (b_stb && !b_reg) begin
                next_state = START;
                start_fsm = 1;
                b_ack_temp = 1;
            end else if (calz_get_u8) begin
                next_state = CALZ_GET_U8;
            end else if (berExp_get_u8) begin
                next_state = BEREXP_GET_U8;
            end else if (calz_get_u64) begin
                next_state = CALZ_GET_U64;
            end
        end
        CALZ_GET_U8: begin
            next_state = CALZ_GET_U8;
            get_u8_temp = 1;
            if (chacha20withBuffer_u8_stb) begin
                chacha20withBuffer_u8_ack_temp = 1;
                u8_stb_calz_temp = 1;
                get_u8_temp = 0;
            end
            if (calz_u8_ack) begin
                next_state = START;
                get_u8_temp = 0;
            end
        end
        CALZ_GET_U64: begin
            next_state = CALZ_GET_U64;
            get_u64_temp = 1;
            if (chacha20withBuffer_u64_stb) begin
                chacha20withBuffer_u64_ack_temp = 1;
                u64_stb_calz_temp = 1;
                get_u64_temp = 0;
            end
            if (calz_u64_ack) begin
                next_state = START;
                get_u64_temp = 0;
            end
        end
        BEREXP_GET_U8: begin
            next_state = BEREXP_GET_U8;
            get_u8_temp = 1;
            if (chacha20withBuffer_u8_stb) begin
                chacha20withBuffer_u8_ack_temp = 1;
                berExp_get_u8_stb_temp = 1;
                get_u8_temp = 0;
            end
            if (berExp_get_u8_ack) begin
                next_state = START;
                get_u8_temp = 0;
            end
        end
        DONE: begin
            next_state = DONE;
            sample_stb_temp = 1;
            if (sample_ack) begin
                next_state = IDLE;
            end
        end
    endcase
end

endmodule


module Calz (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [63:0] u_64,
    input wire u_64_stb,
    output reg u_64_ack,
    output reg get_u64,
    input wire [7:0] u_8,
    input wire u_8_stb,
    output reg u_8_ack,
    output reg get_u8,
    output wire [63:0] z,
    output reg z_stb,
    input wire z_ack
);


parameter IDLE = 0;
parameter SAMPLE_64 = 1;
parameter SAMPLE_8 = 2;
parameter GET_B = 3;
parameter DONE = 4;

reg [2:0] current_state, next_state;
reg [71:0] u;

always @(posedge clk) begin
    if (rst) begin
        current_state <= 0;
    end else begin
        current_state <= next_state;
    end
end

always@(posedge clk) begin
    if (rst) begin
        u <= 0;
    end else if (u_64_stb && current_state == SAMPLE_64) begin
        u <= {8'd0, u_64};
    end else if (u_8_stb && current_state == SAMPLE_8) begin
        u <= {u_8, u[63:0]};
    end
end
reg signed [7:0] b;
always@(posedge clk) begin
    if (rst) begin
        b <= 0;
    end else if (u_8_stb && current_state == GET_B) begin
        b <= u_8;
    end
end

always@(*) begin
    case (current_state)
        IDLE: begin
            u_64_ack = 0;
            u_8_ack = 0;
            z_stb = 0;
            get_u64 = 0;
            get_u8 = 0;
            next_state = IDLE;
            if (z_ack && start) begin
                next_state = SAMPLE_64;
            end
        end
        SAMPLE_64: begin
            u_64_ack = 0;
            u_8_ack = 0;
            z_stb = 0;
            get_u64 = 1;
            get_u8 = 0;
            next_state = SAMPLE_64;
            if (u_64_stb) begin
                next_state = SAMPLE_8;
                u_64_ack = 1;
            end
        end
        SAMPLE_8: begin
            u_64_ack = 0;
            u_8_ack = 0;
            z_stb = 0;
            get_u64 = 0;
            get_u8 = 1;
            next_state = SAMPLE_8;
            if (u_8_stb) begin
                next_state = GET_B;
                u_8_ack = 1;
            end
        end
        GET_B: begin
            u_64_ack = 0;
            u_8_ack = 0;
            z_stb = 0;
            get_u64 = 0;
            get_u8 = 1;
            next_state = GET_B;
            if (u_8_stb) begin
                next_state = DONE;
                u_8_ack = 1;
            end
        end
        DONE: begin
            u_64_ack = 0;
            u_8_ack = 0;
            z_stb = 1;
            get_u64 = 0;
            get_u8 = 0;
            next_state = DONE;
            if (z_ack) begin
                next_state = IDLE;
            end
        end
        default: begin
            u_64_ack = 0;
            u_8_ack = 0;
            z_stb = 0;
            get_u64 = 0;
            get_u8 = 0;
            next_state = IDLE;
        end
    endcase
end
wire signed [31:0] u_out;

BaseSampler baseSampler (
    .clk(clk),
    .rst(rst),
    .u(u),
    .data_out(u_out)
);

assign z = (b & 1) ? b + u_out : b - u_out;

endmodule