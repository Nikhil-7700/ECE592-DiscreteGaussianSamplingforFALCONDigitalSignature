module ChaCha20withBuffer (
    input wire clk,
    input wire reset,
    input wire get_u8,
    input wire set,
    input wire [255:0] key,
    input wire [63:0] nonce_in,
    input wire [63:0] counter_in,
    output wire [7:0] u8,
    output wire u8_stb,
    input wire get_u64,
    output wire [63:0] u64,
    output wire u64_stb,
    input wire u8_ack,
    input wire u64_ack
);

wire [511:0] output_data;
wire done;
wire get;
wire buffer_ack_to_chacha20;

ChaCha20 chacha20(
    .clk(clk),
    .reset(reset),
    .set(set),
    .key(key),
    .get(get),
    .nonce_in(nonce_in),
    .counter_in(counter_in),
    .output_data(output_data),
    .done(done)
);

Buffer buffer(
    .clk(clk),
    .reset(reset),
    .input_data(output_data), // input data from ChaCha20
    .input_stb(done),  // stb from ChaCha20
    .input_ack(buffer_ack_to_chacha20), // ack to ChaCha20
    .get_u8(get_u8),
    .u8_ack(u8_ack),
    .output_u8(u8), // output 8-bit data
    .output_u8_stb(u8_stb), // stb for 8-bit data
    .get_u64(get_u64),
    .u64_ack(u64_ack),
    .output_u64(u64), // output 64-bit data
    .output_u64_stb(u64_stb), // stb for 64-bit data
    .get(get)
);


endmodule

module Buffer (
    input wire clk,
    input wire reset,
    input wire [511:0] input_data, // input data from ChaCha20
    input wire input_stb,  // stb from ChaCha20
    output reg input_ack, // ack to ChaCha20
    input wire get_u8,
    input wire u8_ack, 
    output wire [7:0] output_u8, // output 8-bit data
    output reg output_u8_stb, // stb for 8-bit data
    input wire get_u64,
    input wire u64_ack,
    output wire [63:0] output_u64, // output 64-bit data
    output reg output_u64_stb, // stb for 64-bit data
    output reg get // get the next 512-bit block from ChaCha20
);

reg [2:0] current_state, next_state;

always @(posedge clk) begin
    if (reset) begin
        current_state <= 0;
    end else begin
        current_state <= next_state;
    end
end
parameter IDLE = 0, FILL = 1, RESPONSE = 2;

reg [511:0] buffer_0;
reg [63:0] buffer_0_valid; // each bit represents a byte
reg [511:0] buffer_1;
reg [63:0] buffer_1_valid; // each bit represents a byte
reg buffer_fill_chooser; // 0 for buffer 0, 1 for buffer 1
reg buffer_response_chooser; // 0 for buffer 0, 1 for buffer 1

always @(posedge clk) begin
    if (reset) begin
        buffer_0 <= 0;
        buffer_0_valid <= 0;
    end else if (input_stb & (current_state == FILL) & (buffer_fill_chooser == 0)) begin
        buffer_0 <= input_data;
        buffer_0_valid <= 64'hFFFFFFFFFFFFFFFF;
    end else if (get_u8 & (current_state == RESPONSE) & (buffer_response_chooser == 0)) begin
        buffer_0 <= {8'd0, buffer_0[511:8]};
        buffer_0_valid <= {buffer_0_valid[62:0], 1'b0};
    end else if (get_u64 & (current_state == RESPONSE) & (buffer_response_chooser == 0)) begin
        buffer_0 <= {64'd0, buffer_0[511:64]};
        buffer_0_valid <= {buffer_0_valid[55:0], 1'b0};
    end
end

always @(posedge clk) begin
    if (reset) begin
        buffer_1 <= 0;
        buffer_1_valid <= 0;
    end else if (input_stb & (current_state == FILL) & (buffer_fill_chooser == 1)) begin
        buffer_1 <= input_data;
        buffer_1_valid <= 64'hFFFFFFFFFFFFFFFF;
    end else if (get_u8 & (current_state == RESPONSE) & (buffer_response_chooser == 1)) begin
        buffer_1 <= {8'd0, buffer_1[511:8]};
        buffer_1_valid <= {buffer_1_valid[62:0], 1'b0};
    end else if (get_u64 & (current_state == RESPONSE) & (buffer_response_chooser == 1)) begin
        buffer_1 <= {64'd0, buffer_1[511:64]};
        buffer_1_valid <= {buffer_1_valid[55:0], 1'b0};
    end
end

reg buffer_fill_chooser_reg;
always @(posedge clk) begin
    buffer_fill_chooser_reg <= (current_state == FILL && (buffer_0_valid == 0 || buffer_1_valid == 0)) ? buffer_fill_chooser : buffer_fill_chooser_reg;
end

always @(*) begin
    next_state = IDLE;
    output_u8_stb = 0;
    output_u64_stb = 0;
    get = 0;
    input_ack = 0;
    buffer_fill_chooser = 0;
    buffer_response_chooser = 0;
    case (current_state)
        IDLE: begin
            buffer_fill_chooser = 0;
            buffer_response_chooser = !buffer_fill_chooser_reg;
            next_state = IDLE;
            input_ack = 0;
            output_u8_stb = 0;
            output_u64_stb = 0;
            get = 0;
            if (input_stb & (buffer_0_valid == 0 || buffer_1_valid == 0)) begin
                next_state = FILL;
            end else if ((get_u8 || get_u64) && (buffer_0_valid != 0 || buffer_1_valid != 0)) begin
                next_state = RESPONSE;
            end else begin
                next_state = IDLE;
            end
        end
        FILL: begin
            next_state = FILL;
            buffer_fill_chooser = 0;
            buffer_response_chooser = 0;
            input_ack = input_stb;
            output_u8_stb = 0;
            output_u64_stb = 0;
            get = 1;
            if (buffer_0_valid == 0) begin
                buffer_fill_chooser = 0;
            end else if (buffer_1_valid == 0) begin
                buffer_fill_chooser = 1;
            end else begin
                next_state = IDLE;
            end
        end
        RESPONSE: begin
            next_state = RESPONSE;
            if (u8_ack) begin
                next_state = IDLE;
            end else if (u64_ack) begin
                next_state = IDLE;
            end
            buffer_response_chooser = !buffer_fill_chooser_reg;
            buffer_fill_chooser = 0;
            input_ack = 0;
            get = 0;
            if (get_u8) begin
                output_u8_stb = 1;
            end else if (get_u64) begin
                output_u64_stb = 1;
            end
        end
        default: begin
            next_state = IDLE;
            buffer_fill_chooser = 0;
            buffer_response_chooser = 0;
            input_ack = 0;
            output_u8_stb = 0;
            output_u64_stb = 0;
            get = 0;
        end
    endcase
end

assign output_u8 = (buffer_response_chooser == 0) ? buffer_0[7:0] : buffer_1[7:0];
assign output_u64 = (buffer_response_chooser == 0) ? buffer_0[63:0] : buffer_1[63:0];


endmodule

module ChaCha20 (    
    input wire clk,
    input wire reset,
    input wire set,
    input wire get,
    input wire [255:0] key,
    input wire [63:0] nonce_in,
    input wire [63:0] counter_in,
    output wire [511:0] output_data,
    output wire done
);

reg [31:0] constant1, constant2, constant3, constant4;
reg [31:0] key1, key2, key3, key4, key5, key6, key7, key8;
reg [63:0] nonce;
reg [63:0] counter;
reg [511:0] original_state;

reg [31:0] a1, b1, c1, d1;
wire [31:0] a1_out, b1_out, c1_out, d1_out;
reg [31:0] a2, b2, c2, d2;
wire [31:0] a2_out, b2_out, c2_out, d2_out;
reg [31:0] a3, b3, c3, d3;
wire [31:0] a3_out, b3_out, c3_out, d3_out;
reg [31:0] a4, b4, c4, d4;
wire [31:0] a4_out, b4_out, c4_out, d4_out;

QuarterRound qr1(a1, b1, c1, d1, a1_out, b1_out, c1_out, d1_out);
QuarterRound qr2(a2, b2, c2, d2, a2_out, b2_out, c2_out, d2_out);
QuarterRound qr3(a3, b3, c3, d3, a3_out, b3_out, c3_out, d3_out);
QuarterRound qr4(a4, b4, c4, d4, a4_out, b4_out, c4_out, d4_out);


// We need logic to chose the correct input for each quarter round based
// on either this is an odd or even round.
// We also need to keep track of the round number. A counter is used
// to keep track of the number of rounds completed. (20 rounds)
// Odd rounds:
// QROUND( 0,  4,  8, 12);
// QROUND( 1,  5,  9, 13);
// QROUND( 2,  6, 10, 14);
// QROUND( 3,  7, 11, 15);
// Even rounds:
// QROUND( 0,  5, 10, 15);
// QROUND( 1,  6, 11, 12);
// QROUND( 2,  7,  8, 13);
// QROUND( 3,  4,  9, 14);

always @(*) begin
    if (round_counter[0]) begin
        // Odd round
        a1 = constant1;
        b1 = key1;
        c1 = key5;
        d1 = nonce[63:32];

        a2 = constant2;
        b2 = key2;
        c2 = key6;
        d2 = nonce[31:0];

        a3 = constant3;
        b3 = key3;
        c3 = key7;
        d3 = counter[31:0];

        a4 = constant4;
        b4 = key4;
        c4 = key8;
        d4 = counter[63:32];
    end else begin
        // Even round
        a1 = constant1;
        b1 = key2;
        c1 = key7;
        d1 = counter[63:32];

        a2 = constant2;
        b2 = key3;
        c2 = key8;
        d2 = nonce[63:32];

        a3 = constant3;
        b3 = key4;
        c3 = key5;
        d3 = nonce[31:0];

        a4 = constant4;
        b4 = key1;
        c4 = key6;
        d4 = counter[31:0];
    end
end

reg [5:0] round_counter;
always @(posedge clk) begin
    if (reset) begin
        round_counter <= 0;
    end else if (set) begin
        round_counter <= 0;
    end else if (round_counter == 21 && !get) begin
        round_counter <= round_counter;
    end else if (round_counter == 21) begin
        round_counter <= 0;
    end else begin
        round_counter <= round_counter + 1;
    end
end

reg [63:0] counter_0;
reg [63:0] nonce_0;

always @(posedge clk) begin
    if (reset) begin
        counter_0 <= 0;
        nonce_0 <= 0;
    end else if (set) begin
        counter_0 <= counter_in;
        nonce_0 <= nonce_in;
    end else if (round_counter == 21 && !get) begin
        counter_0 <= counter_0;
        nonce_0 <= nonce_0;
    end else if (round_counter == 21) begin
        counter_0 <= counter_0 + 1;
        nonce_0 <= nonce_0 + 1;
    end
end
reg set_delayed;
always @(posedge clk) begin
    set_delayed <= set;
end
// Constants [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574]

always @(posedge clk) begin
    if (reset) begin
        constant1 <= 32'h61707865;
        constant2 <= 32'h3320646e;
        constant3 <= 32'h79622d32;
        constant4 <= 32'h6b206574;
        key1 <= 0;
        key2 <= 0;
        key3 <= 0;
        key4 <= 0;
        key5 <= 0;
        key6 <= 0;
        key7 <= 0;
        key8 <= 0;
        nonce <= 0;
        counter <= 0;
        original_state <= {32'h61707865, 32'h3320646e, 32'h79622d32, 32'h6b206574, 256'd0, 128'd0};
    end else if (set) begin
        constant1 <= 32'h61707865;
        constant2 <= 32'h3320646e;
        constant3 <= 32'h79622d32;
        constant4 <= 32'h6b206574;
        key1 <= key[255:224];
        key2 <= key[223:192];
        key3 <= key[191:160];
        key4 <= key[159:128];
        key5 <= key[127:96];
        key6 <= key[95:64];
        key7 <= key[63:32];
        key8 <= key[31:0];
        nonce <= nonce_in;
        counter <= counter_in;
        original_state <= {32'h61707865, 32'h3320646e, 32'h79622d32, 32'h6b206574, key, nonce_in, counter_in[31:0], counter_in[63:32]};
    end else if (round_counter != 0 && round_counter != 21) begin
        // Update the state
        if (round_counter[0]) begin
            constant1 <= a1_out;
            constant2 <= a2_out;
            constant3 <= a3_out;
            constant4 <= a4_out;
            key1 <= b1_out;
            key2 <= b2_out;
            key3 <= b3_out;
            key4 <= b4_out;
            key5 <= c1_out;
            key6 <= c2_out;
            key7 <= c3_out;
            key8 <= c4_out;
            nonce[63:32] <= d1_out;
            nonce[31:0] <= d2_out;
            counter[31:0] <= d3_out;
            counter[63:32] <= d4_out;
        end else begin
            constant1 <= a1_out;
            constant2 <= a2_out;
            constant3 <= a3_out;
            constant4 <= a4_out;
            key2 <= b1_out;
            key3 <= b2_out;
            key4 <= b3_out;
            key1 <= b4_out;
            key7 <= c1_out;
            key8 <= c2_out;
            key5 <= c3_out;
            key6 <= c4_out;
            counter[63:32] <= d1_out;
            nonce[31:0] <= d3_out;
            counter[31:0] <= d4_out;
            nonce[63:32] <= d2_out;
        end
        original_state <= original_state;
    end else if (round_counter == 0 && !set_delayed) begin
        constant1 <= 32'h61707865;
        constant2 <= 32'h3320646e;
        constant3 <= 32'h79622d32;
        constant4 <= 32'h6b206574;
        key1 <= original_state[383:352];
        key2 <= original_state[351:320];
        key3 <= original_state[319:288];
        key4 <= original_state[287:256];
        key5 <= original_state[255:224];
        key6 <= original_state[223:192];
        key7 <= original_state[191:160];
        key8 <= original_state[159:128];
        nonce <= nonce_0;
        counter <= counter_0;
        original_state <= {original_state[511:128], nonce_0, counter_0[31:0], counter_0[63:32]};
    end else if (set_delayed) begin
        constant1 <= constant1;
        constant2 <= constant2;
        constant3 <= constant3;
        constant4 <= constant4;
        key1 <= key1;
        key2 <= key2;
        key3 <= key3;
        key4 <= key4;
        key5 <= key5;
        key6 <= key6;
        key7 <= key7;
        key8 <= key8;
        nonce <= nonce;
        counter <= counter;
        original_state <= original_state;
    end
end

// Add each 32-bit word with its corresponding original state word
assign output_data[511:480] = original_state[511:480] + constant1;
assign output_data[479:448] = original_state[479:448] + constant2;
assign output_data[447:416] = original_state[447:416] + constant3;
assign output_data[415:384] = original_state[415:384] + constant4;

assign output_data[383:352] = original_state[383:352] + key1;
assign output_data[351:320] = original_state[351:320] + key2;
assign output_data[319:288] = original_state[319:288] + key3;
assign output_data[287:256] = original_state[287:256] + key4;

assign output_data[255:224] = original_state[255:224] + key5;
assign output_data[223:192] = original_state[223:192] + key6;
assign output_data[191:160] = original_state[191:160] + key7;
assign output_data[159:128] = original_state[159:128] + key8;

assign output_data[127:96] = original_state[127:96] + nonce[63:32];
assign output_data[95:64] = original_state[95:64] + nonce[31:0];
assign output_data[63:32] = original_state[63:32] + counter[31:0];
assign output_data[31:0] = original_state[31:0] + counter[63:32];

assign done = (round_counter == 21);

endmodule

module QuarterRound (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [31:0] c,
    input wire [31:0] d,
    output wire [31:0] a_out,
    output wire [31:0] b_out,
    output wire [31:0] c_out,
    output wire [31:0] d_out
);

reg [31:0] a1, a2;
reg [31:0] d1, d2, d3, d4;
reg [31:0] b1, b2, b3, b4;
reg [31:0] c1, c2;

always @(*) begin
    // First round
    a1 = a + b;                          // state[a] += state[b]
    d1 = a1 ^ d;                         // state[d] ^= state[a]
    d2 = {d1[15:0], d1[31:16]};         // ROL 16
    
    // Second round
    c1 = c + d2;                         // state[c] += state[d]
    b1 = b ^ c1;                         // state[b] ^= state[c]
    b2 = {b1[19:0], b1[31:20]};         // ROL 12
    
    // Third round
    a2 = a1 + b2;                        // state[a] += state[b]  (using a1 as previous state[a])
    d3 = a2 ^ d2;                        // state[d] ^= state[a]  (using d2 as previous state[d])
    d4 = {d3[23:0], d3[31:24]};         // ROL 8
    
    // Fourth round
    c2 = c1 + d4;                        // state[c] += state[d]  (using c1 as previous state[c])
    b3 = b2 ^ c2;                        // state[b] ^= state[c]  (using b2 as previous state[b])
    b4 = {b3[24:0], b3[31:25]};         // ROL 7
end

assign a_out = a2;  // Final a value
assign b_out = b4;  // Final b value
assign c_out = c2;  // Final c value
assign d_out = d4;  // Final d value

endmodule