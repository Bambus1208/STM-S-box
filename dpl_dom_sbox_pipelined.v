module dpl_noEE_and ( //dual_rail_precharge_logic_noEE_and
    input   a_t,
    input   a_f,
    input   b_t,
    input   b_f,
    output  c_t,
    output  c_f
);
    //true case
    and a0 (c_t, a_t, b_t);
    //false case
    wire c_0, o_0, o_1, o_2;
    and a1 (o_0, a_f, b_f);
    and a2 (o_1, a_t, b_f);
    and a3 (o_2, a_f, b_t);

    or o0 (c_0, o_0, o_1);
    or o1 (c_f, c_0, o_2);
endmodule

module dpl_noEE_xor ( //dual_rail_precharge_logic_noEE_xor
    input   a_t,
    input   a_f,
    input   b_t,
    input   b_f,
    output  c_t,
    output  c_f
);
    //true case
    wire o_0, o_1;
    and a0 (o_0, a_t, b_f);
    and a1 (o_1, a_f, b_t);

    or o0 (c_t, o_0, o_1);
    //false case
    wire o_2, o_3;
    and a2 (o_2, a_t, b_t);
    and a3 (o_3, a_f, b_f);

    or o1 (c_f, o_2, o_3);
endmodule

module gen_dpl_noEE_xor #(
      parameter BITS = 4
    ) 
    (
      input  [((BITS*2)-1):0] A,
      input  [((BITS*2)-1):0] B,
      output [((BITS*2)-1):0] C
);
    genvar index;
    generate
        for (index = 0; index < BITS; index = index + 1) begin
            dpl_noEE_xor x (.a_t(A[(index*2)+1]), .a_f(A[index*2]), .b_t(B[(index*2)+1]), .b_f(B[index*2]), .c_t(C[(index*2)+1]), .c_f(C[index*2]));
        end
    endgenerate

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

//Sbox
module MUL_2 (
    input  [3:0] A,
    input  [3:0] B,
    output [3:0] C
);
    wire [1:0] a_01, b_01, ab_01;

    dpl_noEE_xor x0 (.a_t(A[3]), .a_f(A[2]), .b_t(A[1]), .b_f(A[0]), .c_t(a_01[1]), .c_f(a_01[0]));
    dpl_noEE_xor x1 (.a_t(B[3]), .a_f(B[2]), .b_t(B[1]), .b_f(B[0]), .c_t(b_01[1]), .c_f(b_01[0]));

    dpl_noEE_and a0 (.a_t(a_01[1]), .a_f(a_01[0]), .b_t(b_01[1]), .b_f(b_01[0]), .c_t(ab_01[1]), .c_f(ab_01[0]));

    wire [1:0] ab_0, ab_1;

    dpl_noEE_and a1 (.a_t(A[1]), .a_f(A[0]), .b_t(B[1]), .b_f(B[0]), .c_t(ab_0[1]), .c_f(ab_0[0]));
    dpl_noEE_and a2 (.a_t(A[3]), .a_f(A[2]), .b_t(B[3]), .b_f(B[2]), .c_t(ab_1[1]), .c_f(ab_1[0]));

    dpl_noEE_xor x2 (.a_t(ab_01[1]), .a_f(ab_01[0]), .b_t(ab_0[1]), .b_f(ab_0[0]), .c_t(C[1]), .c_f(C[0]));
    dpl_noEE_xor x3 (.a_t(ab_01[1]), .a_f(ab_01[0]), .b_t(ab_1[1]), .b_f(ab_1[0]), .c_t(C[3]), .c_f(C[2]));

endmodule

module DOM_GF_MULS_2 (
    input  [3:0] A_1,
    input  [3:0] A_2,
    input  [3:0] B_1,
    input  [3:0] B_2,
    input  [3:0] rand,
    output [3:0] D,
    output [3:0] E,
    output [3:0] F,
    output [3:0] G
);
    wire [3:0] c_0, c_1;

    // first domain
    MUL_2 m0 (.A(A_1), .B(B_1), .C(D));
    MUL_2 m1 (.A(A_1), .B(B_2), .C(c_0));

    //second domain
    MUL_2 m2 (.A(A_2), .B(B_1), .C(c_1));
    MUL_2 m3 (.A(A_2), .B(B_2), .C(G));

    gen_dpl_noEE_xor #(2) x0 (.A(c_0), .B(rand), .C(E));
    gen_dpl_noEE_xor #(2) x1 (.A(c_1), .B(rand), .C(F));

endmodule

module MUL_4 (
    input [7:0] A,
    input [7:0] B,
    output [7:0] C
);
   wire [3:0] ph, pl, p;

   wire [1:0] a_23, b_23, ab_2, ab_3, ab_23;

   dpl_noEE_xor x0 (.a_t(A[7]), .a_f(A[6]), .b_t(A[5]), .b_f(A[4]), .c_t(a_23[1]), .c_f(a_23[0]));
   dpl_noEE_xor x1 (.a_t(B[7]), .a_f(B[6]), .b_t(B[5]), .b_f(B[4]), .c_t(b_23[1]), .c_f(b_23[0]));

   dpl_noEE_and a0 (.a_t(a_23[1]), .a_f(a_23[0]), .b_t(b_23[1]), .b_f(b_23[0]), .c_t(ab_23[1]), .c_f(ab_23[0]));

   dpl_noEE_and a1 (.a_t(A[5]), .a_f(A[4]), .b_t(B[5]), .b_f(B[4]), .c_t(ab_2[1]), .c_f(ab_2[0]));
   dpl_noEE_and a2 (.a_t(A[7]), .a_f(A[6]), .b_t(B[7]), .b_f(B[6]), .c_t(ab_3[1]), .c_f(ab_3[0]));

   dpl_noEE_xor x2 (.a_t(ab_23[1]), .a_f(ab_23[0]), .b_t(ab_2[1]), .b_f(ab_2[0]), .c_t(ph[1]), .c_f(ph[0]));
   dpl_noEE_xor x3 (.a_t(ab_23[1]), .a_f(ab_23[0]), .b_t(ab_3[1]), .b_f(ab_3[0]), .c_t(ph[3]), .c_f(ph[2]));

   wire [1:0] a_01, b_01, ab_0, ab_1, ab_01;

   dpl_noEE_xor x4 (.a_t(A[3]), .a_f(A[2]), .b_t(A[1]), .b_f(A[0]), .c_t(a_01[1]), .c_f(a_01[0]));
   dpl_noEE_xor x5 (.a_t(B[3]), .a_f(B[2]), .b_t(B[1]), .b_f(B[0]), .c_t(b_01[1]), .c_f(b_01[0]));

   dpl_noEE_and a3 (.a_t(a_01[1]), .a_f(a_01[0]), .b_t(b_01[1]), .b_f(b_01[0]), .c_t(ab_01[1]), .c_f(ab_01[0]));

   dpl_noEE_and a4 (.a_t(A[1]), .a_f(A[0]), .b_t(B[1]), .b_f(B[0]), .c_t(ab_0[1]), .c_f(ab_0[0]));
   dpl_noEE_and a5 (.a_t(A[3]), .a_f(A[2]), .b_t(B[3]), .b_f(B[2]), .c_t(ab_1[1]), .c_f(ab_1[0]));

   dpl_noEE_xor x6 (.a_t(ab_01[1]), .a_f(ab_01[0]), .b_t(ab_0[1]), .b_f(ab_0[0]), .c_t(pl[1]), .c_f(pl[0]));
   dpl_noEE_xor x7 (.a_t(ab_01[1]), .a_f(ab_01[0]), .b_t(ab_1[1]), .b_f(ab_1[0]), .c_t(pl[3]), .c_f(pl[2]));

   wire [3:0] aa, bb;

   dpl_noEE_xor x8 (.a_t(A[1]), .a_f(A[0]), .b_t(A[5]), .b_f(A[4]), .c_t(aa[1]), .c_f(aa[0]));
   dpl_noEE_xor x9 (.a_t(A[3]), .a_f(A[2]), .b_t(A[7]), .b_f(A[6]), .c_t(aa[3]), .c_f(aa[2]));

   dpl_noEE_xor x10 (.a_t(B[1]), .a_f(B[0]), .b_t(B[5]), .b_f(B[4]), .c_t(bb[1]), .c_f(bb[0]));
   dpl_noEE_xor x11 (.a_t(B[3]), .a_f(B[2]), .b_t(B[7]), .b_f(B[6]), .c_t(bb[3]), .c_f(bb[2]));

   wire [1:0] aa_01, bb_01, aabb_0, aabb_1, aabb_01, aabb_011;

   dpl_noEE_xor x12 (.a_t(aa[3]), .a_f(aa[2]), .b_t(aa[1]), .b_f(aa[0]), .c_t(aa_01[1]), .c_f(aa_01[0]));
   dpl_noEE_xor x13 (.a_t(bb[3]), .a_f(bb[2]), .b_t(bb[1]), .b_f(bb[0]), .c_t(bb_01[1]), .c_f(bb_01[0]));

   dpl_noEE_and a6 (.a_t(aa_01[1]), .a_f(aa_01[0]), .b_t(bb_01[1]), .b_f(bb_01[0]), .c_t(aabb_01[1]), .c_f(aabb_01[0]));

   dpl_noEE_and a14 (.a_t(aa[1]), .a_f(aa[0]), .b_t(bb[1]), .b_f(bb[0]), .c_t(aabb_0[1]), .c_f(aabb_0[0]));
   dpl_noEE_and a15 (.a_t(aa[3]), .a_f(aa[2]), .b_t(bb[3]), .b_f(bb[2]), .c_t(aabb_1[1]), .c_f(aabb_1[0]));

   dpl_noEE_xor x16 (.a_t(aabb_01[1]), .a_f(aabb_01[0]), .b_t(aabb_0[1]), .b_f(aabb_0[0]), .c_t(p[3]),        .c_f(p[2]));
   dpl_noEE_xor x17 (.a_t(aabb_01[1]), .a_f(aabb_01[0]), .b_t(aabb_1[1]), .b_f(aabb_1[0]), .c_t(aabb_011[1]), .c_f(aabb_011[0]));

   dpl_noEE_xor x18 (.a_t(aabb_011[1]), .a_f(aabb_011[0]), .b_t(p[3]), .b_f(p[2]), .c_t(p[1]), .c_f(p[0]));

   dpl_noEE_xor x19 (.a_t(ph[3]), .a_f(ph[2]), .b_t(p[3]), .b_f(p[2]), .c_t(C[7]), .c_f(C[6]));
   dpl_noEE_xor x20 (.a_t(ph[1]), .a_f(ph[0]), .b_t(p[1]), .b_f(p[0]), .c_t(C[5]), .c_f(C[4]));

   dpl_noEE_xor x21 (.a_t(pl[3]), .a_f(pl[2]), .b_t(p[3]), .b_f(p[2]), .c_t(C[3]), .c_f(C[2]));
   dpl_noEE_xor x22 (.a_t(pl[1]), .a_f(pl[0]), .b_t(p[1]), .b_f(p[0]), .c_t(C[1]), .c_f(C[0]));
 
endmodule

module DOM_GF_MULS_4 (
    input  [7:0] A_1,
    input  [7:0] A_2,
    input  [7:0] B_1,
    input  [7:0] B_2,
    input  [7:0] rand,
    output [7:0] D,
    output [7:0] E,
    output [7:0] F,
    output [7:0] G
);
    wire [7:0] c_0, c_1;

    // first domain
    MUL_4 m0 (.A(A_1), .B(B_1), .C(D));
    MUL_4 m1 (.A(A_1), .B(B_2), .C(c_0));

    //second domain
    MUL_4 m2 (.A(A_2), .B(B_1), .C(c_1));
    MUL_4 m3 (.A(A_2), .B(B_2), .C(G));

    gen_dpl_noEE_xor #(4) x0 (.A(c_0), .B(rand), .C(E));
    gen_dpl_noEE_xor #(4) x1 (.A(c_1), .B(rand), .C(F));
    
endmodule

module stage_one_DOM_GF_INV_4 (
    input  [7:0] A,
    output [3:0] a,
    output [3:0] b,
    output [3:0] D
);
    wire [3:0] c;

    assign a = A[7:4];
    assign b = A[3:0];
    // xor and square
    dpl_noEE_xor x0 (.a_t(a[1]), .a_f(a[0]), .b_t(b[1]), .b_f(b[0]), .c_t(c[3]), .c_f(c[2]));
    dpl_noEE_xor x1 (.a_t(a[3]), .a_f(a[2]), .b_t(b[3]), .b_f(b[2]), .c_t(c[1]), .c_f(c[0]));
    // scale
    assign D[3:2] = c[1:0];
    dpl_noEE_xor x2 (.a_t(c[1]), .a_f(c[0]), .b_t(c[3]), .b_f(c[2]), .c_t(D[1]), .c_f(D[0]));

endmodule

module stage_two_DOM_GF_INV_4 (
    input  [3:0] A,
    input  [3:0] B,
    output [3:0] D
);

    // xor and inversion
    dpl_noEE_xor x0 (.a_t(A[1]), .a_f(A[0]), .b_t(B[1]), .b_f(B[0]), .c_t(D[3]), .c_f(D[2]));
    dpl_noEE_xor x1 (.a_t(A[3]), .a_f(A[2]), .b_t(B[3]), .b_f(B[2]), .c_t(D[1]), .c_f(D[0]));
endmodule

module DOM_GF_INV_4 (
    input  [7:0]  A,
    input  [7:0]  B,
    input  [11:0] rand,
    input  [47:0] r2,
    input         clk,
    input         rst,
    output [7:0]  G,
    output [7:0]  H,
    output [47:0] r5
);
    // first share
    wire [3:0] A_a, A_b, A_c; 
    stage_one_DOM_GF_INV_4 stage10 (.A(A), .a(A_a), .b(A_b), .D(A_c));

    // second share
    wire [3:0] B_a, B_b, B_c; 
    stage_one_DOM_GF_INV_4 stage11 (.A(B), .a(B_a), .b(B_b), .D(B_c));

    wire [3:0] A_d0, A_d1, B_d0, B_d1;
    DOM_GF_MULS_2 m0 (.A_1(A_a), .A_2(B_a), .B_1(A_b), .B_2(B_b), .rand(rand[3:0]), .D(A_d0), .E(A_d1), .F(B_d0), .G(B_d1));

    reg [95:0] reg_3;

    always @(posedge clk) begin
        reg_3 <= {rand[11:4], r2, A_a, A_b, B_a, B_b, A_c, B_c, A_d0, A_d1, B_d0, B_d1};
    end  

    wire [3:0] A_d, B_d;
    gen_dpl_noEE_xor #(2) x0 (.A(reg_3[15:12]), .B(reg_3[11:8]), .C(A_d));
    gen_dpl_noEE_xor #(2) x1 (.A(reg_3[7:4]), .B(reg_3[3:0]), .C(B_d));

    // first share
    wire [3:0] A_e; 
    stage_two_DOM_GF_INV_4 stage20 (.A(reg_3[23:20]), .B(A_d), .D(A_e));

    // second share
    wire [3:0] B_e; 
    stage_two_DOM_GF_INV_4 stage21 (.A(reg_3[19:16]), .B(B_d), .D(B_e));

    reg [79:0] reg_4;
    always @(posedge clk) begin
        reg_4 <= {reg_3[95:24], A_e, B_e};
    end  

    wire [3:0] A_f00, A_f01, A_f10, A_f11, B_f00, B_f01, B_f10, B_f11;
    DOM_GF_MULS_2 m1 (.A_1(reg_4[23:20]), .A_2(reg_4[15:12]), .B_1(reg_4[7:4]), .B_2(reg_4[3:0]), .rand(reg_4[75:72]), .D(A_f00), .E(A_f01), .F(B_f00), .G(B_f01));
    DOM_GF_MULS_2 m2 (.A_1(reg_4[19:16]), .A_2(reg_4[11:8]),  .B_1(reg_4[7:4]), .B_2(reg_4[3:0]), .rand(reg_4[79:76]), .D(A_f10), .E(A_f11), .F(B_f10), .G(B_f11));

    reg [79:0] reg_5;

    always @(posedge clk) begin
        reg_5 <= {reg_4[71:24], A_f00, A_f01, A_f10, A_f11, B_f00, B_f01, B_f10, B_f11};
    end  
    assign r5 = reg_5[79:32];

    wire [3:0] A_f0, A_f1, B_f0, B_f1;

    gen_dpl_noEE_xor #(2) x2 (.A(reg_5[31:28]), .B(reg_5[27:24]), .C(A_f0));
    gen_dpl_noEE_xor #(2) x3 (.A(reg_5[23:20]), .B(reg_5[19:16]), .C(A_f1));
    gen_dpl_noEE_xor #(2) x4 (.A(reg_5[15:12]), .B(reg_5[11:8]),  .C(B_f0));
    gen_dpl_noEE_xor #(2) x5 (.A(reg_5[7:4]),   .B(reg_5[3:0]),   .C(B_f1));

    assign G = {A_f1, A_f0};
    assign H = {B_f1, B_f0};

endmodule

module square_scaler_4 (
    input  [7:0] A,
    output [7:0] B
);
    assign B[1:0] = A[1:0];
    dpl_noEE_xor x0 (.a_t(A[1]), .a_f(A[0]), .b_t(A[3]), .b_f(A[2]), .c_t(B[3]), .c_f(B[2]));
    dpl_noEE_xor x1 (.a_t(A[3]), .a_f(A[2]), .b_t(A[7]), .b_f(A[6]), .c_t(B[5]), .c_f(B[4]));
    dpl_noEE_xor x2 (.a_t(A[1]), .a_f(A[0]), .b_t(A[5]), .b_f(A[4]), .c_t(B[7]), .c_f(B[6]));

endmodule

module stage_one_DOM_GF_INV_8 (
    input  [15:0] A,
    output [7:0]  a,
    output [7:0]  b,
    output [7:0]  D
);
    wire [7:0] c;

    assign a = A[15:8];
    assign b = A[7:0];
    gen_dpl_noEE_xor #(4) x0 (.A(a), .B(b), .C(c));
    square_scaler_4 s0 (.A(c), .B(D));
endmodule

module stage_two_DOM_GF_INV_8 (
    input  [7:0] A,
    input  [7:0] B,
    output [7:0] C
);
    gen_dpl_noEE_xor #(4) x0 (.A(A), .B(B), .C(C));
endmodule

module DOM_GF_INV_8 (
    input  [15:0] A,
    input  [15:0] B,
    input  [35:0] rand,
    input         clk,
    input         rst,
    output [15:0] G,
    output [15:0] H
);
    // first share
    wire [7:0] A_a, A_b, A_c; 
    stage_one_DOM_GF_INV_8 stage10 (.A(A), .a(A_a), .b(A_b), .D(A_c));

    // second share
    wire [7:0] B_a, B_b, B_c; 
    stage_one_DOM_GF_INV_8 stage11 (.A(B), .a(B_a), .b(B_b), .D(B_c));

    wire [7:0] A_d0, A_d1, B_d0, B_d1;
    DOM_GF_MULS_4 m0 (.A_1(A_a), .A_2(B_a), .B_1(A_b), .B_2(B_b), .rand(rand[7:0]), .D(A_d0), .E(A_d1), .F(B_d0), .G(B_d1));

    reg [107:0] reg_1;
    always @(posedge clk) begin
        reg_1 <= {rand[35:8], A_a, A_b, B_a, B_b, A_c, B_c, A_d0, A_d1, B_d0, B_d1};
    end

    wire [7:0] A_d, B_d;
    gen_dpl_noEE_xor #(4) x0 (.A(reg_1[31:24]), .B(reg_1[23:16]), .C(A_d));
    gen_dpl_noEE_xor #(4) x1 (.A(reg_1[15:8]),  .B(reg_1[7:0]),   .C(B_d));

    // first share
    wire [7:0] A_e; 
    stage_two_DOM_GF_INV_8 stage20 (.A(reg_1[47:40]), .B(A_d), .C(A_e));

    // second share
    wire [7:0] B_e; 
    stage_two_DOM_GF_INV_8 stage21 (.A(reg_1[39:32]), .B(B_d), .C(B_e));

    reg [75:0] reg_2;
    always @(posedge clk) begin
        reg_2 <= {reg_1[107:48], A_e, B_e};
    end

    wire [31:0] AB_ab_r2;
    wire [15:0] rand_r2;
    assign AB_ab_r2 = reg_2[47:16]; 
    assign rand_r2 = reg_2[75:60];

    wire [7:0] A_f, B_f;
    wire [47:0] rand_AB_ab_r5;

    DOM_GF_INV_4 inv4 (.A(reg_2[15:8]), .B(reg_2[7:0]), .rand(reg_2[59:48]), .r2({rand_r2, AB_ab_r2}), .clk(clk), .rst(rst), .G(A_f), .H(B_f), .r5(rand_AB_ab_r5));

    wire [7:0] A_f00, A_f01, A_f10, A_f11, B_f00, B_f01, B_f10, B_f11;
    DOM_GF_MULS_4 m1 (.A_1(A_f), .A_2(B_f), .B_1(rand_AB_ab_r5[31:24]), .B_2(rand_AB_ab_r5[15:8]), .rand(rand_AB_ab_r5[39:32]), .D(A_f00), .E(A_f01), .F(B_f00), .G(B_f01));

    DOM_GF_MULS_4 m2 (.A_1(A_f), .A_2(B_f), .B_1(rand_AB_ab_r5[23:16]), .B_2(rand_AB_ab_r5[7:0]),  .rand(rand_AB_ab_r5[47:40]), .D(A_f10), .E(A_f11), .F(B_f10), .G(B_f11));

    reg [63:0] reg_6;

    always @(posedge clk) begin
        reg_6 <= {A_f00, A_f01, A_f10, A_f11, B_f00, B_f01, B_f10, B_f11};
    end

    wire [7:0] A_f0, A_f1, B_f0, B_f1;

    gen_dpl_noEE_xor #(4) x2 (.A(reg_6[63:56]), .B(reg_6[55:48]), .C(A_f0));
    gen_dpl_noEE_xor #(4) x3 (.A(reg_6[47:40]), .B(reg_6[39:32]), .C(A_f1));
    gen_dpl_noEE_xor #(4) x4 (.A(reg_6[31:24]), .B(reg_6[23:16]), .C(B_f0));
    gen_dpl_noEE_xor #(4) x5 (.A(reg_6[15:8]),  .B(reg_6[7:0]),   .C(B_f1));

    assign G = {A_f1, A_f0};
    assign H = {B_f1, B_f0};

endmodule


module Mapping(
    input  [15:0] A,
    output [15:0] B
);
    wire [1:0] a_00, a_01, a_02;

    dpl_noEE_xor r01 (.a_t(A[13]),   .a_f(A[12]),   .b_t(A[7]),   .b_f(A[6]),   .c_t(a_00[1]), .c_f(a_00[0]));
    dpl_noEE_xor r02 (.a_t(a_00[1]), .a_f(a_00[0]), .b_t(A[5]),   .b_f(A[4]),   .c_t(a_01[1]), .c_f(a_01[0]));
    dpl_noEE_xor r03 (.a_t(a_01[1]), .a_f(a_01[0]), .b_t(A[3]),   .b_f(A[2]),   .c_t(a_02[1]), .c_f(a_02[0]));
    dpl_noEE_xor r04 (.a_t(a_02[1]), .a_f(a_02[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[1]),    .c_f(B[0]));

    wire [1:0] a_10;

    dpl_noEE_xor r11 (.a_t(A[13]),   .a_f(A[12]),   .b_t(A[11]),  .b_f(A[10]),  .c_t(a_10[1]), .c_f(a_10[0]));
    dpl_noEE_xor r12 (.a_t(a_10[1]), .a_f(a_10[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[3]),    .c_f(B[2]));

    assign B[5:4] = A[1:0];

    wire [1:0] a_30, a_31, a_32;

    dpl_noEE_xor r31 (.a_t(A[15]),   .a_f(A[14]),   .b_t(A[9]),   .b_f(A[8]),   .c_t(a_30[1]), .c_f(a_30[0]));
    dpl_noEE_xor r32 (.a_t(a_30[1]), .a_f(a_30[0]), .b_t(A[7]),   .b_f(A[6]),   .c_t(a_31[1]), .c_f(a_31[0]));
    dpl_noEE_xor r33 (.a_t(a_31[1]), .a_f(a_31[0]), .b_t(A[3]),   .b_f(A[2]),   .c_t(a_32[1]), .c_f(a_32[0]));
    dpl_noEE_xor r34 (.a_t(a_32[1]), .a_f(a_32[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[7]),    .c_f(B[6]));

    wire [1:0] a_40, a_41;

    dpl_noEE_xor r41 (.a_t(A[15]),   .a_f(A[14]),   .b_t(A[13]),  .b_f(A[12]),  .c_t(a_40[1]), .c_f(a_40[0]));
    dpl_noEE_xor r42 (.a_t(a_40[1]), .a_f(a_40[0]), .b_t(A[11]),  .b_f(A[10]),  .c_t(a_41[1]), .c_f(a_41[0]));
    dpl_noEE_xor r43 (.a_t(a_41[1]), .a_f(a_41[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[9]),    .c_f(B[8]));

    wire [1:0] a_50, a_51;

    dpl_noEE_xor r51 (.a_t(A[13]),   .a_f(A[12]),   .b_t(A[11]),  .b_f(A[10]),  .c_t(a_50[1]), .c_f(a_50[0]));
    dpl_noEE_xor r52 (.a_t(a_50[1]), .a_f(a_50[0]), .b_t(A[3]),   .b_f(A[2]),   .c_t(a_51[1]), .c_f(a_51[0]));
    dpl_noEE_xor r53 (.a_t(a_51[1]), .a_f(a_51[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[11]),   .c_f(B[10]));

    wire [1:0] a_60, a_61;

    dpl_noEE_xor r61 (.a_t(A[13]),   .a_f(A[12]),   .b_t(A[11]),  .b_f(A[10]),  .c_t(a_60[1]), .c_f(a_60[0]));
    dpl_noEE_xor r62 (.a_t(a_60[1]), .a_f(a_60[0]), .b_t(A[9]),   .b_f(A[8]),   .c_t(a_61[1]), .c_f(a_61[0]));
    dpl_noEE_xor r63 (.a_t(a_61[1]), .a_f(a_61[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[13]),   .c_f(B[12]));

    wire [1:0] a_70, a_71, a_72, a_73;

    dpl_noEE_xor r71 (.a_t(A[15]),   .a_f(A[14]),   .b_t(A[13]),  .b_f(A[12]),  .c_t(a_70[1]), .c_f(a_70[0]));
    dpl_noEE_xor r72 (.a_t(a_70[1]), .a_f(a_70[0]), .b_t(A[11]),  .b_f(A[10]),  .c_t(a_71[1]), .c_f(a_71[0]));
    dpl_noEE_xor r73 (.a_t(a_71[1]), .a_f(a_71[0]), .b_t(A[5]),   .b_f(A[4]),   .c_t(a_72[1]), .c_f(a_72[0]));
    dpl_noEE_xor r74 (.a_t(a_72[1]), .a_f(a_72[0]), .b_t(A[3]),   .b_f(A[2]),   .c_t(a_73[1]), .c_f(a_73[0]));
    dpl_noEE_xor r75 (.a_t(a_73[1]), .a_f(a_73[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[15]),   .c_f(B[14]));
endmodule

module inv_Mapping(
    input  [15:0] A,
    output [15:0] B
);
    wire [1:0] a_00;

    dpl_noEE_xor r01 (.a_t(A[13]),   .a_f(A[12]),   .b_t(A[9]),   .b_f(A[8]),   .c_t(a_00[1]), .c_f(a_00[0]));
    dpl_noEE_xor r02 (.a_t(a_00[1]), .a_f(a_00[0]), .b_t(A[3]),   .b_f(A[2]),   .c_t(B[1]),    .c_f(B[0]));

    wire [1:0] a_10;

    dpl_noEE_xor r11 (.a_t(A[11]),   .a_f(A[10]),   .b_t(A[9]),   .b_f(A[8]),   .c_t(a_10[1]), .c_f(a_10[0]));
    dpl_noEE_xor r12 (.a_t(a_10[1]), .a_f(a_10[0]), .b_t(A[3]),   .b_f(A[2]),   .c_t(B[3]),    .c_f(B[2]));

    wire [1:0] a_20, a_21, a_22;

    dpl_noEE_xor r21 (.a_t(A[13]),   .a_f(A[12]),   .b_t(A[11]),  .b_f(A[10]),  .c_t(a_20[1]), .c_f(a_20[0]));
    dpl_noEE_xor r22 (.a_t(a_20[1]), .a_f(a_20[0]), .b_t(A[7]),   .b_f(A[6]),   .c_t(a_21[1]), .c_f(a_21[0]));
    dpl_noEE_xor r23 (.a_t(a_21[1]), .a_f(a_21[0]), .b_t(A[5]),   .b_f(A[4]),   .c_t(a_22[1]), .c_f(a_22[0]));
    dpl_noEE_xor r24 (.a_t(a_22[1]), .a_f(a_22[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[5]),    .c_f(B[4]));

    wire [1:0] a_30, a_31, a_32;

    dpl_noEE_xor r31 (.a_t(A[15]),   .a_f(A[14]),   .b_t(A[13]),  .b_f(A[12]),  .c_t(a_30[1]), .c_f(a_30[0]));
    dpl_noEE_xor r32 (.a_t(a_30[1]), .a_f(a_30[0]), .b_t(A[11]),  .b_f(A[10]),  .c_t(a_31[1]), .c_f(a_31[0]));
    dpl_noEE_xor r33 (.a_t(a_31[1]), .a_f(a_31[0]), .b_t(A[9]),   .b_f(A[8]),   .c_t(a_32[1]), .c_f(a_32[0]));
    dpl_noEE_xor r34 (.a_t(a_32[1]), .a_f(a_32[0]), .b_t(A[7]),   .b_f(A[6]),   .c_t(B[7]),    .c_f(B[6]));

    wire [1:0] a_40;

    dpl_noEE_xor r41 (.a_t(A[15]),   .a_f(A[14]),   .b_t(A[11]),  .b_f(A[10]),  .c_t(a_40[1]), .c_f(a_40[0]));
    dpl_noEE_xor r42 (.a_t(a_40[1]), .a_f(a_40[0]), .b_t(A[7]),   .b_f(A[6]),   .c_t(B[9]),    .c_f(B[8]));

    dpl_noEE_xor r51 (.a_t(A[13]),   .a_f(A[12]),   .b_t(A[1]),   .b_f(A[0]),   .c_t(B[11]), .c_f(B[10]));

    dpl_noEE_xor r61 (.a_t(A[15]),   .a_f(A[14]),   .b_t(A[7]),   .b_f(A[6]),   .c_t(B[13]), .c_f(B[12]));

    dpl_noEE_xor r71 (.a_t(A[11]),   .a_f(A[10]),   .b_t(A[7]),   .b_f(A[6]),   .c_t(B[15]), .c_f(B[14]));
endmodule

module Sbox (
    input  [15:0] A,
    input  [15:0] B,
    input  [35:0] rand,
    input         clk,
    output [15:0] E,
    output [15:0] F
);
    /* linear mapping & change basis to GF(2^8)/GF(2^4)/GF(2^2)*/
    // first share
    wire [15:0] A_C, A_D;
    Mapping m0 (.A(A), .B(A_C));

    // second share
    wire [15:0] B_C, B_D;
    Mapping m1 (.A(B), .B(B_C));


    reg [67:0] reg_0;
    always @(posedge clk) begin
        reg_0 <= {rand, A_C, B_C};
    end
   
    // inversion
    DOM_GF_INV_8 inv (.A(reg_0[31:16]), .B(reg_0[15:0]), .rand(reg_0[67:32]), .clk(clk), .rst(rst), .G(A_D), .H(B_D));


    /* linear iverse mapping & change basis back to GF(2^8) */
    // first share 
    wire [15:0] e_t, e, f;
    inv_Mapping im0 (.A(A_D), .B(e_t));

    gen_dpl_noEE_xor #(8) x0 (.A(e_t), .B(16'b110100101011010), .C(e));

    // second share
    inv_Mapping im1 (.A(B_D), .B(f));

    reg [31:0] reg_7;
    always @(posedge clk) begin
        reg_7 <= {e, f};
    end
    assign E = reg_7[31:16];
    assign F = reg_7[15:0];

endmodule


module DPLConverter #(
      parameter BITS = 8
    ) 
    (
    input [(BITS-1):0] a,
    output [((BITS*2)-1):0] converted
);
    genvar index;
    generate
        for (index = 0; index < BITS; index = index + 1) begin
            assign converted[index*2+1] = a[index];
            assign converted[index*2] = ~a[index];
        end
    endgenerate

endmodule

module DPLInverter#(
      parameter BITS = 8
    ) 
    (
    input  [((BITS*2)-1):0] a,
    output [(BITS-1):0] converted
);
    genvar index;
    generate
        for (index = 0; index < BITS; index = index + 1) begin
            assign converted[index] = a[index*2+1];
        end
    endgenerate
endmodule

module sbox_controller (
    input          rst,
    input          load,
    input          enable,
    input          clk,
    input  [7:0]   s_0_0,
    input  [7:0]   s_0_1,
    input  [7:0]   s_1_0,
    input  [7:0]   s_1_1,
    input  [7:0]   s_2_0,
    input  [7:0]   s_2_1,
    input  [7:0]   s_3_0,
    input  [7:0]   s_3_1,
    input  [127:0] key,
    output [7:0]   r_0_0,
    output [7:0]   r_0_1,
    output [7:0]   r_1_0,
    output [7:0]   r_1_1,
    output [7:0]   r_2_0,
    output [7:0]   r_2_1,
    output [7:0]   r_3_0,
    output [7:0]   r_3_1,
    output reg     done
);
    wire [63:0] rand;
    wire [35:0] dpl_r;
    PRNG prng (.rst(rst), .clk(clk), .key(key[79:0]), .iv({s_0_0, s_1_0, s_2_0, s_3_0, key[127:80]}), .stream_out(rand));

    DPLConverter #(18) c0 (rand[17:0], dpl_r);

    wire [15:0] dr_s_0_0, dr_s_0_1, dr_s_1_0, dr_s_1_1, dr_s_2_0, dr_s_2_1, dr_s_3_0, dr_s_3_1;

    DPLConverter #(8) c1 (s_0_0, dr_s_0_0);
    DPLConverter #(8) c2 (s_0_1, dr_s_0_1); 
    DPLConverter #(8) c3 (s_1_0, dr_s_1_0);
    DPLConverter #(8) c4 (s_1_1, dr_s_1_1); 
    DPLConverter #(8) c5 (s_2_0, dr_s_2_0);
    DPLConverter #(8) c6 (s_2_1, dr_s_2_1); 
    DPLConverter #(8) c7 (s_3_0, dr_s_3_0);
    DPLConverter #(8) c8 (s_3_1, dr_s_3_1); 

    reg [15:0] share_0_0;
    reg [15:0] share_0_1;
    reg [15:0] share_1_0;
    reg [15:0] share_1_1;
    reg [15:0] share_2_0;
    reg [15:0] share_2_1;
    reg [15:0] share_3_0;
    reg [15:0] share_3_1;

    reg [7:0] result_0_0;
    reg [7:0] result_0_1;
    reg [7:0] result_1_0;
    reg [7:0] result_1_1;
    reg [7:0] result_2_0;
    reg [7:0] result_2_1;
    reg [7:0] result_3_0;
    reg [7:0] result_3_1;

    reg [3:0] state;
    reg [35:0] sbox_rand;

    reg [15:0] A, B;
    wire [7:0] C, D;  
    wire [15:0] a, b, c, d;

    reg ack;

    always @(posedge clk) begin 
        if (rst) begin
            share_0_0 <= 16'b0;
            share_0_1 <= 16'b0;
            share_1_0 <= 16'b0;
            share_1_1 <= 16'b0;
            share_2_0 <= 16'b0;
            share_2_1 <= 16'b0;
            share_3_0 <= 16'b0;
            share_3_1 <= 16'b0;
            result_0_0 <= 8'b0;
            result_0_1 <= 8'b0;
            result_1_0 <= 8'b0;
            result_1_1 <= 8'b0;
            result_2_0 <= 8'b0;
            result_2_1 <= 8'b0;
            result_3_0 <= 8'b0;
            result_3_1 <= 8'b0;
            
            A <= 16'h0;
            B <= 16'h0;
            state <= 4'b0;
            // r <= 144'b0;
            sbox_rand <= 18'b0;
            done <= 1'b0;
            ack <= 1'b1;
        end
        if (load) begin
            share_0_0 <= dr_s_0_0;
            share_0_1 <= dr_s_0_1;
            share_1_0 <= dr_s_1_0;
            share_1_1 <= dr_s_1_1;
            share_2_0 <= dr_s_2_0;
            share_2_1 <= dr_s_2_1;
            share_3_0 <= dr_s_3_0;
            share_3_1 <= dr_s_3_1;
        end

        if (enable & (~done)) begin
            if (ack) begin
                A         <= 16'h5555;
                B         <= 16'h5555;
                sbox_rand <= dpl_r; 
                case (state)
                    4'd0: begin
                        A         <= share_0_0;
                        B         <= share_0_1;
                    end
                    4'd1: begin
                        A         <= share_1_0;
                        B         <= share_1_1;
                    end
                    4'd2: begin
                        A         <= share_2_0;
                        B         <= share_2_1;
                    end
                    4'd3: begin
                        A         <= share_3_0;
                        B         <= share_3_1;
                    end

                endcase
                state <= state + 1;
                ack <= ~ack;            
            end
            else begin
                A         <= 16'h0;
                B         <= 16'h0;
                sbox_rand <= 36'h0;
                case (state)
                    4'd5: begin
                        result_0_0 <= C;
                        result_0_1 <= D;
                    end
                    4'd6: begin
                        result_1_0 <= C;
                        result_1_1 <= D;
                    end
                    4'd7: begin
                        result_2_0 <= C;
                        result_2_1 <= D;
                    end
                    4'd8: begin
                        result_3_0 <= C;
                        result_3_1 <= D;
                        done <= 1'b1;
                    end
                endcase
                ack <= ~ack;            

            end            
        end
    end

    Sbox dut(
        .A(A), 
        .B(B), 
        .rand(sbox_rand), 
        .clk(clk), 
        .E(c), 
        .F(d)
    );

    DPLInverter #(8) i0 (c, C);
    DPLInverter #(8) i1 (d, D);

    assign r_0_0 = result_0_0;
    assign r_0_1 = result_0_1;
    assign r_1_0 = result_1_0;
    assign r_1_1 = result_1_1;
    assign r_2_0 = result_2_0;
    assign r_2_1 = result_2_1;
    assign r_3_0 = result_3_0;
    assign r_3_1 = result_3_1;
endmodule





`timescale 1ns / 1ps
module tb_sbox;
    reg clk, rst, enable, load;
    wire [63:0] out;
    parameter stop_time=80;
    initial #stop_time $finish;
    always #2 clk=~clk;  
    sbox_controller dut (.rst(rst), .load(load), .enable(enable), .clk(clk), .s_0_0(8'd2), .s_0_1(8'd1), .s_1_0(8'd1), .s_1_1(8'd0), .s_2_0(8'd2), .s_2_1(8'd0), .s_3_0(8'd3), .s_3_1(8'd0),.key(128'h986bde57d7cbb81dbd777925e057f4c4), .done(done));
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_sbox);
        clk=1'b0; rst=1'b0; load=1'b0; enable=1'b0;
        #2
        rst=1'b1;
        #2
        rst=1'b0;
        #2
        load=1'b1;
        #2
        load=1'b0;
        #2
        enable=1'b1;
    end    
endmodule

