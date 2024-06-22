module MUL_2 (
    input  [1:0] A,
    input  [1:0] B,
    output [1:0] C
);
    wire aandb;
    assign aandb = ((A[1] ^ A[0]) & (B[1] ^ B[0]));
    assign C[0] = aandb ^ (A[0] & B[0]);
    assign C[1] = aandb ^ (A[1] & B[1]);
endmodule

module DOM_GF_MULS_2 (
    input  [1:0] A_1,
    input  [1:0] A_2,
    input  [1:0] B_1,
    input  [1:0] B_2,
    input  [1:0] rand,
    output [1:0] E,
    output [1:0] F
);

    wire [1:0] c_0, c_1, c_2, c_3;

    MUL_2 m0 (A_2, B_2, c_0);
    MUL_2 m1 (A_2, B_1, c_1);
    MUL_2 m2 (A_1, B_2, c_2);
    MUL_2 m3 (A_1, B_1, c_3);

    assign F = {c_0 ^ c_1 ^ rand};
    assign E = {c_2 ^ c_3 ^ rand};
endmodule

module square_scaler_4 (
    input  [3:0] A,
    output [3:0] B
);
    assign B[0] = A[0];
    assign B[1] = A[0] ^ A[1];
    assign B[2] = A[1] ^ A[3];
    assign B[3] = A[0] ^ A[2];
endmodule

module MUL_4 (
    input [3:0] A,
    input [3:0] B,
    output [3:0] C
);
    wire [1:0] ph, pl, p;
    assign ph[0] = ((A[3] ^ A[2]) & (B[3] ^ B[2])) ^ (A[2] & B[2]);
    assign ph[1] = ((A[3] ^ A[2]) & (B[3] ^ B[2])) ^ (A[3] & B[3]);

    assign pl[0] = ((A[1] ^ A[0]) & (B[1] ^ B[0])) ^ (A[0] & B[0]);
    assign pl[1] = ((A[1] ^ A[0]) & (B[1] ^ B[0])) ^ (A[1] & B[1]);

    wire [1:0] aa, bb;
    assign aa = (A[3:2] ^ A[1:0]);
    assign bb = (B[3:2] ^ B[1:0]);

    assign p[1] = ((aa[1] ^ aa[0]) & (bb[1] ^ bb[0])) ^ (aa[0] & bb[0]);
    assign p[0] = ((aa[1] ^ aa[0]) & (bb[1] ^ bb[0])) ^ (aa[1] & bb[1]) ^ p[1];

    assign C = {(ph ^ p), (pl ^ p)};
    
endmodule

module DOM_GF_MULS_4 (
    input  [3:0] A_1,
    input  [3:0] A_2,
    input  [3:0] B_1,
    input  [3:0] B_2,
    input  [3:0] rand,
    output [3:0] E,
    output [3:0] F
);
    wire [3:0] c_0, c_1, c_2, c_3;

    MUL_4 m0 (A_1, B_2, c_0);
    MUL_4 m1 (A_1, B_1, c_1);
    MUL_4 m2 (A_2, B_2, c_2);
    MUL_4 m3 (A_2, B_1, c_3);

    assign E = {c_0 ^ c_1 ^ rand};
    assign F = {c_2 ^ c_3 ^ rand};
endmodule

module stage_one_DOM_GF_INV_4 (
    input  [3:0] A,
    output [1:0] a,
    output [1:0] b,
    output [1:0] D
);
    wire [1:0] c;

    assign a = A[3:2];
    assign b = A[1:0];
    // xor and square
    assign c = {a[0] ^ b[0], a[1] ^ b[1]};
    // scale
    assign D = {c[0], c[0] ^ c[1]};

endmodule

module stage_two_DOM_GF_INV_4 (
    input  [1:0] A,
    input  [1:0] B,
    output [1:0] D
);
    wire [1:0] c;
    assign c = A ^ B;
    // equal to inversion
    assign D = {c[0], c[1]};
endmodule

module DOM_GF_INV_4 (
    input  [3:0] A,
    input  [3:0] B,
    input  [5:0] rand,
    output [3:0] G,
    output [3:0] H
);
    wire [3:0] in, out;
    assign in = A ^ B;
    // first share
    wire [1:0] A_a, A_b, A_c; 
    stage_one_DOM_GF_INV_4 stage10 (.A(A), .a(A_a), .b(A_b), .D(A_c));

    // second share
    wire [1:0] B_a, B_b, B_c; 
    stage_one_DOM_GF_INV_4 stage11 (.A(B), .a(B_a), .b(B_b), .D(B_c));

    wire [1:0] A_d, B_d;
    DOM_GF_MULS_2 m0 (.A_1(A_a), .A_2(B_a), .B_1(A_b), .B_2(B_b), .rand(rand[1:0]), .E(A_d), .F(B_d));

    // TODO REG/LATCH

    // first share
    wire [1:0] A_e; 
    stage_two_DOM_GF_INV_4 stage20 (.A(A_c), .B(A_d), .D(A_e));

    // second share
    wire [1:0] B_e; 
    stage_two_DOM_GF_INV_4 stage21 (.A(B_c), .B(B_d), .D(B_e));

    // TODO REG/LATCH

    wire [1:0] A_f0, A_f1, B_f0, B_f1;
    DOM_GF_MULS_2 m1 (.A_1(A_a), .A_2(B_a), .B_1(A_e), .B_2(B_e), .rand(rand[3:2]), .E(A_f0), .F(B_f0));

    DOM_GF_MULS_2 m2 (.A_1(A_b), .A_2(B_b), .B_1(A_e), .B_2(B_e), .rand(rand[5:4]), .E(A_f1), .F(B_f1));

    // TODO REG/LATCH

    assign G = {A_f1, A_f0};
    assign H = {B_f1, B_f0};
endmodule

module stage_one_DOM_GF_INV_8 (
    input  [7:0] A,
    output [3:0] a,
    output [3:0] b,
    output [3:0] D
);
    wire [3:0] c;

    assign a = A[7:4];
    assign b = A[3:0];
    assign c = a ^ b;
    square_scaler_4 s0 (.A(c), .B(D));
endmodule

module stage_two_DOM_GF_INV_8 (
    input  [3:0] A,
    input  [3:0] B,
    output [3:0] C
);
    assign C = A ^ B;
endmodule

module DOM_GF_INV_8 (
    input  [7:0]  A,
    input  [7:0]  B,
    input  [17:0] rand,
    output [7:0]  G,
    output [7:0]  H
);
    // first share
    wire [3:0] A_a, A_b, A_c; 
    stage_one_DOM_GF_INV_8 stage10 (.A(A), .a(A_a), .b(A_b), .D(A_c));

    // second share
    wire [3:0] B_a, B_b, B_c; 
    stage_one_DOM_GF_INV_8 stage11 (.A(B), .a(B_a), .b(B_b), .D(B_c));

    wire [3:0] A_d, B_d;
    DOM_GF_MULS_4 m0 (.A_1(A_a), .A_2(B_a), .B_1(A_b), .B_2(B_b), .rand(rand[3:0]), .E(A_d), .F(B_d));
    
    // TODO REG/LATCH

    // first share
    wire [3:0] A_e; 
    stage_two_DOM_GF_INV_8 stage20 (.A(A_c), .B(A_d), .C(A_e));

    // second share
    wire [3:0] B_e; 
    stage_two_DOM_GF_INV_8 stage21 (.A(B_c), .B(B_d), .C(B_e));

    // TODO REG/LATCH

    wire [3:0] A_f, B_f;
    DOM_GF_INV_4 inv4 (.A(A_e), .B(B_e), .rand(rand[9:4]), .G(A_f), .H(B_f));
    // DOM_GF_INV_4 inv42 (.A(4'hd), .B(4'h7), .rand(rand[9:4]), .G(A_f), .H(B_f));


    wire [3:0] A_f0, A_f1, B_f0, B_f1;
    DOM_GF_MULS_4 m1 (.A_1(A_f), .A_2(B_f), .B_1(A_a), .B_2(B_a), .rand(rand[13:10]), .E(A_f0), .F(B_f0));

    DOM_GF_MULS_4 m2 (.A_1(A_f), .A_2(B_f), .B_1(A_b), .B_2(B_b), .rand(rand[17:14]), .E(A_f1), .F(B_f1));

    // TODO REG/LATCH

    assign G = {A_f1, A_f0};
    assign H = {B_f1, B_f0};

endmodule

module Mapping(
    input  [7:0] A,
    output [7:0] B
);
    assign B[0] = A[6] ^ A[3] ^ A[2] ^ A[1] ^ A[0];
    assign B[1] = A[6] ^ A[5] ^ A[0];
    assign B[2] = A[0];
    assign B[3] = A[7] ^ A[4] ^ A[3] ^ A[1] ^ A[0];
    assign B[4] = A[7] ^ A[6] ^ A[5] ^ A[0];
    assign B[5] = A[6] ^ A[5] ^ A[1] ^ A[0];
    assign B[6] = A[6] ^ A[5] ^ A[4] ^ A[0];
    assign B[7] = A[7] ^ A[6] ^ A[5] ^ A[2] ^ A[1] ^ A[0];
endmodule

module inv_Mapping(
    input  [7:0] A,
    output [7:0] B
);
    assign B[0] = A[6] ^ A[4] ^ A[1];
    assign B[1] = A[5] ^ A[4] ^ A[1];
    assign B[2] = A[6] ^ A[5] ^ A[3] ^ A[2] ^ A[0];
    assign B[3] = A[7] ^ A[6] ^ A[5] ^ A[4] ^ A[3];
    assign B[4] = A[7] ^ A[5] ^ A[3];
    assign B[5] = A[6] ^ A[0];
    assign B[6] = A[7] ^ A[3];
    assign B[7] = A[5] ^ A[3];
endmodule

module Sbox (
    input  [7:0] A,
    input  [7:0] B,
    input  [17:0] rand,
    output [7:0] E,
    output [7:0] F
);
    /* linear mapping & change basis to GF(2^8)/GF(2^4)/GF(2^2)
    combine with bit inverse matrix multiply of Sbox */
    // first share
    wire [7:0] A_C, A_D;
    Mapping m0 (.A(A), .B(A_C));

    // second share
    wire [7:0] B_C, B_D;
    Mapping m1 (.A(B), .B(B_C));

    // TODO  REG/LATCH
    // inversion
    DOM_GF_INV_8 inv8 (A_C, B_C, rand, A_D, B_D);

    /* linear iverse mapping & change basis back to GF(2^8) */
    // first share 
    wire [7:0] e_t;
    inv_Mapping im0 (.A(A_D), .B(e_t)); 
    assign E = e_t ^ 8'b01100011;

    // second share
    inv_Mapping im1 (.A(B_D), .B(F));
    // TODO  REG/LATCH
endmodule

module PRNG  #(
    parameter output_bits = 64
    )
    (
    input                           clk,
    input                           rst,
    input   [79:0]                  key,
    input   [79:0]                  iv,
    output  [(output_bits-1):0]     stream_out
);
    reg [287:0] state [0:output_bits];
    wire [output_bits-1:0] t1, t2, t3;

    always @(posedge clk) begin
        if (rst) begin            
            state[0] = {3'b111, 112'b0, iv, 13'b0, key};
        end else begin
            state[0] = state[output_bits];
        end
    end
    genvar i;
    generate
        for (i = 0; i < output_bits; i = i + 1) begin
            assign t1[i] = state[i][161] ^ state[i][176];
            assign t2[i] = state[i][65]  ^ state[i][92];
            assign t3[i] = state[i][242] ^ state[i][287];

            always @(*) begin
                state[i+1] = {state[i][286:177], t1[i] ^ (state[i][174] & state[i][175]) ^ state[i][263], state[i][175:93], (t2[i] ^ (state[i][90] & state[i][91]) ^ state[i][170]), state[i][91:0], (t3[i] ^ (state[i][285] & state[i][286]) ^ state[i][68])};
            end
            
            assign stream_out[i] = t1[output_bits - (i + 1) ] ^ t2[output_bits - (i + 1)] ^ t3[output_bits - (i + 1)];
        end
    endgenerate

endmodule


`timescale 1ns / 1ns
module tb_sbox;
    reg clk, rst;
    reg [7:0] a = 8'h7;
    reg [7:0] b = 8'h5;
    wire [63:0] out;
    wire [7:0] e, f, res;
    assign res = e ^ f;
    parameter stop_time=20;
    initial #stop_time $finish;
    always #2 clk=~clk;  
    Sbox u1 (.A(a),.B(b), .rand(out[17:0]), .E(e), .F(f));
    PRNG u2 (.rst(rst), .clk(clk), .key(80'h00010203040506070809), .iv(80'h00010203040506070809), .stream_out(out));
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_sbox);
        clk=1'b1; rst=1'b1;
        #2
        rst=1'b0; 
        end    
endmodule