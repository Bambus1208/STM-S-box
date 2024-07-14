module dpl_noEE_and ( //dual_rail_precharge_logic_noEE_and
    input   a_t,
    input   a_f,
    input   b_t,
    input   b_f,
    output  c_t,
    output  c_f
);
    //true case
    (* keep = "true" *) and a0 (c_t, a_t, b_t);
    //false case
    (* keep = "true" *) wire c_0, o_0, o_1, o_2;
    (* keep = "true" *) and a1 (o_0, a_f, b_f);
    (* keep = "true" *) and a2 (o_1, a_t, b_f);
    (* keep = "true" *) and a3 (o_2, a_f, b_t);

    (* keep = "true" *) or o0 (c_0, o_0, o_1);
    (* keep = "true" *) or o1 (c_f, c_0, o_2);
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
    (* keep = "true" *) wire o_0, o_1;
    (* keep = "true" *) and a0 (o_0, a_t, b_f);
    (* keep = "true" *) and a1 (o_1, a_f, b_t);

    (* keep = "true" *) or o0 (c_t, o_0, o_1);
    //false case
    (* keep = "true" *) wire o_2, o_3;
    (* keep = "true" *) and a2 (o_2, a_t, b_t);
    (* keep = "true" *) and a3 (o_3, a_f, b_f);

    (* keep = "true" *) or o1 (c_f, o_2, o_3);
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

module dpl_dff_v (
    input trigger,
    input enable,
    input [15:0] d,
    output reg [15:0] q
);
    always @(posedge trigger) begin
        if ( enable) begin
            q <= d;//{d[13:0], 2'b0};
        end else begin
            q <= 16'hffff;
        end
    end
endmodule

module dpl_dff_n (
    input trigger,
    input enable,
    input [15:0] d,
    output reg [15:0] q
);
    always @(posedge trigger) begin
        if (enable) begin
            q <= {d[13:0], 2'b0};
        end else begin
            q <= 16'b0;
        end
    end
endmodule
 
module asyn_counter (
    input trigger,
    input enable,
    output [15:0] s_out,
    output [15:0] out
);

(* keep = "true" *) wire [15:0] in_0, in_1;


(* keep = "true" *) dpl_dff_v dff0 (
    .d(in_0),
    .trigger(trigger),
    .enable(enable),
    .q(in_1)
);

(* keep = "true" *) dpl_dff_n dff1 (
    .d(in_1),
    .trigger(trigger),
    .enable(enable),
    .q(in_0)
);

assign out = in_1;
assign s_out = in_0 | in_1;

endmodule

module sub_muller_c_elem (
  input   a,
  input   b,
  input   rst,
  input   c_prev_in,
  output  c_prev_out,
  output  c
);
 (* keep = "true" *) wire c_0, o_0, o_1, o_2;
  assign c_prev_out = rst ? 1'b0 : c;

  (* keep = "true" *) and a0 (o_0, a, c_prev_in);
  (* keep = "true" *) and a1 (o_1, a, b);
  (* keep = "true" *) and a2 (o_2, b, c_prev_in);

  (* keep = "true" *) or o0 (c_0, o_0, o_1);
  (* keep = "true" *) or o1 (c, c_0, o_2);
endmodule

module muller_c_elem (
  input   a,
  input   b,
  input   rst,
  output  c
);
 (* keep = "true" *) wire temp_c_prev;
 (* keep = "true" *) sub_muller_c_elem m0 (.a(a), .b(b), .rst(rst), .c_prev_in(temp_c_prev), .c_prev_out(temp_c_prev), .c(c));
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
           (* keep = "true" *) dpl_noEE_xor x (.a_t(A[(index*2)+1]), .a_f(A[index*2]), .b_t(B[(index*2)+1]), .b_f(B[index*2]), .c_t(C[(index*2)+1]), .c_f(C[index*2]));
        end
    endgenerate

endmodule

module v_weak_indicating_latch #(
      parameter BITS = 8
    )
    (
      input                 req_i,
      input                 rst,
      input [(BITS*2)-1:0]  in,
      output                ack_o,
      output [(BITS*2)-1:0] out
);
    genvar i;
   (* keep = "true" *) wire [(BITS*2)-1:0] t;
    assign t = rst ? {BITS{2'b01}} : in;
    generate
        for (i=0; i<(BITS*2); i=i+1) begin            
             (* keep = "true" *) muller_c_elem c_elem (.a(req_i), .b(t[i]), .rst(rst), .c(out[i]));
        end
    endgenerate

    (* keep = "true" *) nor (ack_o, out[0], out[1]);

endmodule

module n_weak_indicating_latch #(
      parameter BITS = 8
    )
    (
      input                 req_i,
      input                 rst,
      input [(BITS*2)-1:0]  in,
      output                ack_o,
      output [(BITS*2)-1:0] out
);
    genvar i;
   (* keep = "true" *) wire [(BITS*2)-1:0] t;
    assign t = rst ? BITS*2'b0 : in;
    generate
        for (i=0; i<(BITS*2); i=i+1) begin            
             (* keep = "true" *) muller_c_elem c_elem (.a(req_i), .b(t[i]), .rst(rst), .c(out[i]));
        end
    endgenerate

    (* keep = "true" *) nor (ack_o, out[0], out[1]);

endmodule

module n_strong_indicating_latch_0 (
      input                 req_i,
      input                 rst,
      input [67:0]          in,
      output                ack_o,
      output [67:0]         out
);
    genvar i;
    (* keep = "true" *) wire [67:0] t;
    assign t = rst ? 68'b0 : in;

    // Instantiate muller_c_elem for each bit in 't'
    generate
        for (i=0; i<68; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(req_i), 
                .b(t[i]), 
                .rst(rst), 
                .c(out[i])
            );
        end
    endgenerate

    // First level reduction: 68 inputs to 34 outputs using NOR gates
    (* keep = "true" *) wire [33:0] nor_out;
    generate
        for (i=0; i<34; i=i+1) begin            
            (* keep = "true" *) nor (nor_out[i], out[2*i], out[2*i+1]);
        end
    endgenerate

    // Second level reduction: 34 inputs to 17 outputs  
    (* keep = "true" *) wire [16:0] s0_out;
    generate
        for (i=0; i<17; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(nor_out[2*i]), 
                .b(nor_out[2*i+1]), 
                .rst(rst), 
                .c(s0_out[i])
            );
        end
    endgenerate

    // Third level reduction: 17 inputs to 9 outputs  
    (* keep = "true" *) wire [8:0] s1_out;
    generate
        for (i=0; i<8; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s0_out[2*i]), 
                .b(s0_out[2*i+1]), 
                .rst(rst), 
                .c(s1_out[i])
            );
        end
    endgenerate
    assign s1_out[8] = s0_out[16];

    // Fourth level reduction: 9 inputs to 5 outputs  
    (* keep = "true" *) wire [4:0] s2_out;
    generate
        for (i=0; i<4; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s1_out[2*i]), 
                .b(s1_out[2*i+1]), 
                .rst(rst), 
                .c(s2_out[i])
            );
        end
    endgenerate
    assign s2_out[4] = s1_out[8];

    // Fifth level reduction: 5 inputs to 3 outputs  
    (* keep = "true" *) wire [2:0] s3_out;
    generate
        for (i=0; i<2; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s2_out[2*i]), 
                .b(s2_out[2*i+1]), 
                .rst(rst), 
                .c(s3_out[i])
            );
        end
    endgenerate
    assign s3_out[2] = s2_out[4];

    // Sixth level reduction: 3 inputs to 1 output  
    (* keep = "true" *) wire s4_out;
    (* keep = "true" *) muller_c_elem c_elem1 (.a(s3_out[0]), .b(s3_out[1]), .rst(rst), .c(s4_out));
    (* keep = "true" *) muller_c_elem c_elem2 (.a(s4_out), .b(s3_out[2]), .rst(rst), .c(ack_o));

endmodule

module v_strong_indicating_latch_1 (
      input                 req_i,
      input                 rst,
      input [107:0]         in,
      output                ack_o,
      output [107:0]        out
);
    genvar i;
    (* keep = "true" *) wire [107:0] t;
    assign t = rst ? {54{2'b01}} : in;

    // Instantiate muller_c_elem for each bit in 't'
    generate
        for (i=0; i<108; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(req_i), 
                .b(t[i]), 
                .rst(rst), 
                .c(out[i])
            );
        end
    endgenerate

    // First level reduction: 108 inputs to 54 outputs using NOR gates
    (* keep = "true" *) wire [53:0] nor_out;
    generate
        for (i=0; i<54; i=i+1) begin            
            (* keep = "true" *) nor (nor_out[i], out[2*i], out[2*i+1]);
        end
    endgenerate

    // Second level reduction: 54 inputs to 27 outputs  
    (* keep = "true" *) wire [26:0] s0_out;
    generate
        for (i=0; i<27; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(nor_out[2*i]), 
                .b(nor_out[2*i+1]), 
                .rst(rst), 
                .c(s0_out[i])
            );
        end
    endgenerate

    // Third level reduction: 27 inputs to 14 outputs  
    (* keep = "true" *) wire [13:0] s1_out;
    generate
        for (i=0; i<13; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s0_out[2*i]), 
                .b(s0_out[2*i+1]), 
                .rst(rst), 
                .c(s1_out[i])
            );
        end
    endgenerate
    assign s1_out[13] = s0_out[26];

    // Fourth level reduction: 14 inputs to 7 outputs  
    (* keep = "true" *) wire [6:0] s2_out;
    generate
        for (i=0; i<7; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s1_out[2*i]), 
                .b(s1_out[2*i+1]), 
                .rst(rst), 
                .c(s2_out[i])
            );
        end
    endgenerate

    // Fifth level reduction: 7 inputs to 4 outputs  
    (* keep = "true" *) wire [3:0] s3_out;
    generate
        for (i=0; i<3; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s2_out[2*i]), 
                .b(s2_out[2*i+1]), 
                .rst(rst), 
                .c(s3_out[i])
            );
        end
    endgenerate
    assign s3_out[3] = s2_out[6];

    // Final reduction: 4 inputs to 1 output  
    (* keep = "true" *) wire s4_out, s5_out;
    (* keep = "true" *) muller_c_elem c_elem1 (.a(s3_out[0]), .b(s3_out[1]), .rst(rst), .c(s4_out));
    (* keep = "true" *) muller_c_elem c_elem2 (.a(s3_out[2]), .b(s3_out[3]), .rst(rst), .c(s5_out));
    (* keep = "true" *) muller_c_elem c_elem3 (.a(s4_out), .b(s5_out), .rst(rst), .c(ack_o));

endmodule

module n_strong_indicating_latch_2 (
      input                 req_i,
      input                 rst,
      input [75:0]          in,
      output                ack_o,
      output [75:0]         out
);
    genvar i;
    (* keep = "true" *) wire [75:0] t;
    assign t = rst ? 76'b0 : in;

    // Instantiate muller_c_elem for each bit in 't'
    generate
        for (i=0; i<76; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(req_i), 
                .b(t[i]), 
                .rst(rst), 
                .c(out[i])
            );
        end
    endgenerate

    // First level reduction: 76 inputs to 38 outputs using NOR gates
    (* keep = "true" *) wire [37:0] nor_out;
    generate
        for (i=0; i<38; i=i+1) begin            
            (* keep = "true" *) nor (nor_out[i], out[2*i], out[2*i+1]);
        end
    endgenerate

    // Second level reduction: 38 inputs to 19 outputs  
    (* keep = "true" *) wire [18:0] s0_out;
    generate
        for (i=0; i<19; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(nor_out[2*i]), 
                .b(nor_out[2*i+1]), 
                .rst(rst), 
                .c(s0_out[i])
            );
        end
    endgenerate

    // Third level reduction: 19 inputs to 10 outputs  
    (* keep = "true" *) wire [9:0] s1_out;
    generate
        for (i=0; i<9; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s0_out[2*i]), 
                .b(s0_out[2*i+1]), 
                .rst(rst), 
                .c(s1_out[i])
            );
        end
    endgenerate
    assign s1_out[9] = s0_out[18];

    // Fourth level reduction: 10 inputs to 5 outputs  
    (* keep = "true" *) wire [4:0] s2_out;
    generate
        for (i=0; i<5; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s1_out[2*i]), 
                .b(s1_out[2*i+1]), 
                .rst(rst), 
                .c(s2_out[i])
            );
        end
    endgenerate

    // Fifth level reduction: 5 inputs to 3 outputs  
    (* keep = "true" *) wire [2:0] s3_out;
    generate
        for (i=0; i<2; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s2_out[2*i]), 
                .b(s2_out[2*i+1]), 
                .rst(rst), 
                .c(s3_out[i])
            );
        end
    endgenerate
    assign s3_out[2] = s2_out[4];

    // Final reduction: 3 inputs to 1 output  
    (* keep = "true" *) wire s4_out;
    (* keep = "true" *) muller_c_elem c_elem1 (.a(s3_out[0]), .b(s3_out[1]), .rst(rst), .c(s4_out));
    (* keep = "true" *) muller_c_elem c_elem2 (.a(s4_out), .b(s3_out[2]), .rst(rst), .c(ack_o));

endmodule

module v_strong_indicating_latch_3 (
      input                 req_i,
      input                 rst,
      input [95:0]          in,
      output                ack_o,
      output [95:0]         out
);
    genvar i;
    (* keep = "true" *) wire [95:0] t;
    assign t = rst ? {48{2'b01}} : in;

    // Instantiate muller_c_elem for each bit in 't'
    generate
        for (i=0; i<96; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(req_i), 
                .b(t[i]), 
                .rst(rst), 
                .c(out[i])
            );
        end
    endgenerate

    // First level reduction: 96 inputs to 48 outputs using NOR gates
    (* keep = "true" *) wire [47:0] nor_out;
    generate
        for (i=0; i<48; i=i+1) begin            
            (* keep = "true" *) nor (nor_out[i], out[2*i], out[2*i+1]);
        end
    endgenerate

    // Second level reduction: 48 inputs to 24 outputs  
    (* keep = "true" *) wire [23:0] s0_out;
    generate
        for (i=0; i<24; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(nor_out[2*i]), 
                .b(nor_out[2*i+1]), 
                .rst(rst), 
                .c(s0_out[i])
            );
        end
    endgenerate

    // Third level reduction: 24 inputs to 12 outputs  
    (* keep = "true" *) wire [11:0] s1_out;
    generate
        for (i=0; i<12; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s0_out[2*i]), 
                .b(s0_out[2*i+1]), 
                .rst(rst), 
                .c(s1_out[i])
            );
        end
    endgenerate

    // Fourth level reduction: 12 inputs to 6 outputs  
    (* keep = "true" *) wire [5:0] s2_out;
    generate
        for (i=0; i<6; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s1_out[2*i]), 
                .b(s1_out[2*i+1]), 
                .rst(rst), 
                .c(s2_out[i])
            );
        end
    endgenerate

    // Fifth level reduction: 6 inputs to 3 outputs  
    (* keep = "true" *) wire [2:0] s3_out;
    generate
        for (i=0; i<3; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s2_out[2*i]), 
                .b(s2_out[2*i+1]), 
                .rst(rst), 
                .c(s3_out[i])
            );
        end
    endgenerate

    // Final reduction: 3 inputs to 1 output  
    (* keep = "true" *) wire s4_out;
    (* keep = "true" *) muller_c_elem c_elem1 (.a(s3_out[0]), .b(s3_out[1]), .rst(rst), .c(s4_out));
    (* keep = "true" *) muller_c_elem c_elem2 (.a(s4_out), .b(s3_out[2]), .rst(rst), .c(ack_o));

endmodule

module n_strong_indicating_latch_4 (
      input                 req_i,
      input                 rst,
      input [79:0]          in,
      output                ack_o,
      output [79:0]         out
);
    genvar i;
    (* keep = "true" *) wire [79:0] t;
    assign t = rst ? 80'b0 : in;

    // Instantiate muller_c_elem for each bit in 't'
    generate
        for (i=0; i<80; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(req_i), 
                .b(t[i]), 
                .rst(rst), 
                .c(out[i])
            );
        end
    endgenerate

    // First level reduction: 80 inputs to 40 outputs using NOR gates
    (* keep = "true" *) wire [39:0] nor_out;
    generate
        for (i=0; i<40; i=i+1) begin            
            (* keep = "true" *) nor (nor_out[i], out[2*i], out[2*i+1]);
        end
    endgenerate

    // Second level reduction: 40 inputs to 20 outputs  
    (* keep = "true" *) wire [19:0] s0_out;
    generate
        for (i=0; i<20; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(nor_out[2*i]), 
                .b(nor_out[2*i+1]), 
                .rst(rst), 
                .c(s0_out[i])
            );
        end
    endgenerate

    // Third level reduction: 20 inputs to 10 outputs  
    (* keep = "true" *) wire [9:0] s1_out;
    generate
        for (i=0; i<10; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s0_out[2*i]), 
                .b(s0_out[2*i+1]), 
                .rst(rst), 
                .c(s1_out[i])
            );
        end
    endgenerate

    // Fourth level reduction: 10 inputs to 5 outputs  
    (* keep = "true" *) wire [4:0] s2_out;
    generate
        for (i=0; i<5; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s1_out[2*i]), 
                .b(s1_out[2*i+1]), 
                .rst(rst), 
                .c(s2_out[i])
            );
        end
    endgenerate

    // Fifth level reduction: 5 inputs to 3 outputs  
    (* keep = "true" *) wire [2:0] s3_out;
    generate
        for (i=0; i<2; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s2_out[2*i]), 
                .b(s2_out[2*i+1]), 
                .rst(rst), 
                .c(s3_out[i])
            );
        end
    endgenerate
    assign s3_out[2] = s2_out[4];

    // Final reduction: 3 inputs to 1 output  
    (* keep = "true" *) wire s4_out;
    (* keep = "true" *) muller_c_elem c_elem1 (.a(s3_out[0]), .b(s3_out[1]), .rst(rst), .c(s4_out));
    (* keep = "true" *) muller_c_elem c_elem2 (.a(s4_out), .b(s3_out[2]), .rst(rst), .c(ack_o));

endmodule


module v_strong_indicating_latch_5 (
      input                 req_i,
      input                 rst,
      input [39:0]          in,
      output                ack_o,
      output [39:0]         out
);
    genvar i;
    (* keep = "true" *) wire [39:0] t;
    assign t = rst ? {20{2'b01}} : in;

    // Instantiate muller_c_elem for each bit
    generate
        for (i=0; i<40; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(req_i), 
                .b(t[i]), 
                .rst(rst), 
                .c(out[i])
            );
        end
    endgenerate

    // First level reduction: 40 inputs to 20 outputs using NOR gates
    (* keep = "true" *) wire [19:0] nor_out;
    generate
        for (i=0; i<20; i=i+1) begin            
            (* keep = "true" *) nor (nor_out[i], out[2*i], out[2*i+1]);
        end
    endgenerate

    // Second level reduction: 20 inputs to 10 outputs  
    (* keep = "true" *) wire [9:0] s0_out;
    generate
        for (i=0; i<10; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(nor_out[2*i]), 
                .b(nor_out[2*i+1]), 
                .rst(rst), 
                .c(s0_out[i])
            );
        end
    endgenerate

    // Third level reduction: 10 inputs to 5 outputs  
    (* keep = "true" *) wire [4:0] s1_out;
    generate
        for (i=0; i<5; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s0_out[2*i]), 
                .b(s0_out[2*i+1]), 
                .rst(rst), 
                .c(s1_out[i])
            );
        end
    endgenerate

    // Fourth level reduction: 5 inputs to 3 outputs  
    (* keep = "true" *) wire [2:0] s2_out;
    generate
        for (i=0; i<2; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s1_out[2*i]), 
                .b(s1_out[2*i+1]), 
                .rst(rst), 
                .c(s2_out[i])
            );
        end
    endgenerate
    assign s2_out[2] = s1_out[4];

    // Final reduction: 3 inputs to 1 output  
    (* keep = "true" *) wire s3_out;
    (* keep = "true" *) muller_c_elem c_elem1 (.a(s2_out[0]), .b(s2_out[1]), .rst(rst), .c(s3_out));
    (* keep = "true" *) muller_c_elem c_elem2 (.a(s3_out), .b(s2_out[2]), .rst(rst), .c(ack_o));

endmodule

module n_strong_indicating_latch_6 (
      input                 req_i,
      input                 rst,
      input [31:0]          in,
      output                ack_o,
      output [31:0]         out
);
    genvar i;
    (* keep = "true" *) wire [31:0] t;
    assign t = rst ? 32'b0 : in;

    // Instantiate muller_c_elem for each bit in 't'
    generate
        for (i=0; i<32; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(req_i), 
                .b(t[i]), 
                .rst(rst), 
                .c(out[i])
            );
        end
    endgenerate

    // First level reduction: 32 inputs to 16 outputs using NOR gates
    (* keep = "true" *) wire [15:0] nor_out;
    generate
        for (i=0; i<16; i=i+1) begin            
            (* keep = "true" *) nor (nor_out[i], out[2*i], out[2*i+1]);
        end
    endgenerate

    // Second level reduction: 16 inputs to 8 outputs  
    (* keep = "true" *) wire [7:0] s0_out;
    generate
        for (i=0; i<8; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(nor_out[2*i]), 
                .b(nor_out[2*i+1]), 
                .rst(rst), 
                .c(s0_out[i])
            );
        end
    endgenerate

    // Third level reduction: 8 inputs to 4 outputs  
    (* keep = "true" *) wire [3:0] s1_out;
    generate
        for (i=0; i<4; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s0_out[2*i]), 
                .b(s0_out[2*i+1]), 
                .rst(rst), 
                .c(s1_out[i])
            );
        end
    endgenerate

    // Fourth level reduction: 4 inputs to 2 outputs  
    (* keep = "true" *) wire [1:0] s2_out;
    generate
        for (i=0; i<2; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s1_out[2*i]), 
                .b(s1_out[2*i+1]), 
                .rst(rst), 
                .c(s2_out[i])
            );
        end
    endgenerate

    // Final reduction: 2 inputs to 1 output  
    (* keep = "true" *) muller_c_elem c_elem_final (
        .a(s2_out[0]), 
        .b(s2_out[1]), 
        .rst(rst), 
        .c(ack_o)
    );

endmodule

module v_strong_indicating_latch_7 (
      input                 req_i,
      input                 rst,
      input [31:0]          in,
      output                ack_o,
      output [31:0]         out
);
    genvar i;
    (* keep = "true" *) wire [31:0] t;
    assign t = rst ? {16{2'b01}} : in;

    // Instantiate muller_c_elem for each bit in 't'
    generate
        for (i=0; i<32; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(req_i), 
                .b(t[i]), 
                .rst(rst), 
                .c(out[i])
            );
        end
    endgenerate

    // First level reduction: 32 inputs to 16 outputs using NOR gates
    (* keep = "true" *) wire [15:0] nor_out;
    generate
        for (i=0; i<16; i=i+1) begin            
            (* keep = "true" *) nor (nor_out[i], out[2*i], out[2*i+1]);
        end
    endgenerate

    // Second level reduction: 16 inputs to 8 outputs  
    (* keep = "true" *) wire [7:0] s0_out;
    generate
        for (i=0; i<8; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(nor_out[2*i]), 
                .b(nor_out[2*i+1]), 
                .rst(rst), 
                .c(s0_out[i])
            );
        end
    endgenerate

    // Third level reduction: 8 inputs to 4 outputs  
    (* keep = "true" *) wire [3:0] s1_out;
    generate
        for (i=0; i<4; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s0_out[2*i]), 
                .b(s0_out[2*i+1]), 
                .rst(rst), 
                .c(s1_out[i])
            );
        end
    endgenerate

    // Fourth level reduction: 4 inputs to 2 outputs  
    (* keep = "true" *) wire [1:0] s2_out;
    generate
        for (i=0; i<2; i=i+1) begin            
            (* keep = "true" *) muller_c_elem c_elem (
                .a(s1_out[2*i]), 
                .b(s1_out[2*i+1]), 
                .rst(rst), 
                .c(s2_out[i])
            );
        end
    endgenerate

    // Final reduction: 2 inputs to 1 output  
    (* keep = "true" *) muller_c_elem c_elem_final (
        .a(s2_out[0]), 
        .b(s2_out[1]), 
        .rst(rst), 
        .c(ack_o)
    );

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
   (* keep = "true" *) reg [287:0] state [0:output_bits];
   (* keep = "true" *) wire [output_bits-1:0] t1, t2, t3;

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
   (* keep = "true" *) wire [1:0] a_01, b_01, ab_01;

   (* keep = "true" *) dpl_noEE_xor x0 (.a_t(A[3]), .a_f(A[2]), .b_t(A[1]), .b_f(A[0]), .c_t(a_01[1]), .c_f(a_01[0]));
   (* keep = "true" *) dpl_noEE_xor x1 (.a_t(B[3]), .a_f(B[2]), .b_t(B[1]), .b_f(B[0]), .c_t(b_01[1]), .c_f(b_01[0]));

   (* keep = "true" *) dpl_noEE_and a0 (.a_t(a_01[1]), .a_f(a_01[0]), .b_t(b_01[1]), .b_f(b_01[0]), .c_t(ab_01[1]), .c_f(ab_01[0]));

   (* keep = "true" *) wire [1:0] ab_0, ab_1;

   (* keep = "true" *) dpl_noEE_and a1 (.a_t(A[1]), .a_f(A[0]), .b_t(B[1]), .b_f(B[0]), .c_t(ab_0[1]), .c_f(ab_0[0]));
   (* keep = "true" *) dpl_noEE_and a2 (.a_t(A[3]), .a_f(A[2]), .b_t(B[3]), .b_f(B[2]), .c_t(ab_1[1]), .c_f(ab_1[0]));

   (* keep = "true" *) dpl_noEE_xor x2 (.a_t(ab_01[1]), .a_f(ab_01[0]), .b_t(ab_0[1]), .b_f(ab_0[0]), .c_t(C[1]), .c_f(C[0]));
   (* keep = "true" *) dpl_noEE_xor x3 (.a_t(ab_01[1]), .a_f(ab_01[0]), .b_t(ab_1[1]), .b_f(ab_1[0]), .c_t(C[3]), .c_f(C[2]));

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
   (* keep = "true" *) wire [3:0] c_0, c_1;

    // first domain
    (* keep = "true" *) MUL_2 m0 (.A(A_1), .B(B_1), .C(D));
    (* keep = "true" *) MUL_2 m1 (.A(A_1), .B(B_2), .C(c_0));

    //second domain
    (* keep = "true" *) MUL_2 m2 (.A(A_2), .B(B_1), .C(c_1));
    (* keep = "true" *) MUL_2 m3 (.A(A_2), .B(B_2), .C(G));

   (* keep = "true" *) gen_dpl_noEE_xor #(2) x0 (.A(c_0), .B(rand), .C(E));
   (* keep = "true" *) gen_dpl_noEE_xor #(2) x1 (.A(c_1), .B(rand), .C(F));

endmodule

module MUL_4 (
    input  [7:0] A,
    input  [7:0] B,
    output [7:0] C
);
   (* keep = "true" *) wire [3:0] ph, pl, p;

   (* keep = "true" *) wire [1:0] a_23, b_23, ab_2, ab_3, ab_23;

   (* keep = "true" *) dpl_noEE_xor x0 (.a_t(A[7]), .a_f(A[6]), .b_t(A[5]), .b_f(A[4]), .c_t(a_23[1]), .c_f(a_23[0]));
   (* keep = "true" *) dpl_noEE_xor x1 (.a_t(B[7]), .a_f(B[6]), .b_t(B[5]), .b_f(B[4]), .c_t(b_23[1]), .c_f(b_23[0]));

   (* keep = "true" *) dpl_noEE_and a0 (.a_t(a_23[1]), .a_f(a_23[0]), .b_t(b_23[1]), .b_f(b_23[0]), .c_t(ab_23[1]), .c_f(ab_23[0]));

   (* keep = "true" *) dpl_noEE_and a1 (.a_t(A[5]), .a_f(A[4]), .b_t(B[5]), .b_f(B[4]), .c_t(ab_2[1]), .c_f(ab_2[0]));
   (* keep = "true" *) dpl_noEE_and a2 (.a_t(A[7]), .a_f(A[6]), .b_t(B[7]), .b_f(B[6]), .c_t(ab_3[1]), .c_f(ab_3[0]));

   (* keep = "true" *) dpl_noEE_xor x2 (.a_t(ab_23[1]), .a_f(ab_23[0]), .b_t(ab_2[1]), .b_f(ab_2[0]), .c_t(ph[1]), .c_f(ph[0]));
   (* keep = "true" *) dpl_noEE_xor x3 (.a_t(ab_23[1]), .a_f(ab_23[0]), .b_t(ab_3[1]), .b_f(ab_3[0]), .c_t(ph[3]), .c_f(ph[2]));

   (* keep = "true" *) wire [1:0] a_01, b_01, ab_0, ab_1, ab_01;

   (* keep = "true" *) dpl_noEE_xor x4 (.a_t(A[3]), .a_f(A[2]), .b_t(A[1]), .b_f(A[0]), .c_t(a_01[1]), .c_f(a_01[0]));
   (* keep = "true" *) dpl_noEE_xor x5 (.a_t(B[3]), .a_f(B[2]), .b_t(B[1]), .b_f(B[0]), .c_t(b_01[1]), .c_f(b_01[0]));

   (* keep = "true" *) dpl_noEE_and a3 (.a_t(a_01[1]), .a_f(a_01[0]), .b_t(b_01[1]), .b_f(b_01[0]), .c_t(ab_01[1]), .c_f(ab_01[0]));

   (* keep = "true" *) dpl_noEE_and a4 (.a_t(A[1]), .a_f(A[0]), .b_t(B[1]), .b_f(B[0]), .c_t(ab_0[1]), .c_f(ab_0[0]));
   (* keep = "true" *) dpl_noEE_and a5 (.a_t(A[3]), .a_f(A[2]), .b_t(B[3]), .b_f(B[2]), .c_t(ab_1[1]), .c_f(ab_1[0]));

   (* keep = "true" *) dpl_noEE_xor x6 (.a_t(ab_01[1]), .a_f(ab_01[0]), .b_t(ab_0[1]), .b_f(ab_0[0]), .c_t(pl[1]), .c_f(pl[0]));
   (* keep = "true" *) dpl_noEE_xor x7 (.a_t(ab_01[1]), .a_f(ab_01[0]), .b_t(ab_1[1]), .b_f(ab_1[0]), .c_t(pl[3]), .c_f(pl[2]));

   (* keep = "true" *) wire [3:0] aa, bb;

   (* keep = "true" *) dpl_noEE_xor x8 (.a_t(A[1]), .a_f(A[0]), .b_t(A[5]), .b_f(A[4]), .c_t(aa[1]), .c_f(aa[0]));
   (* keep = "true" *) dpl_noEE_xor x9 (.a_t(A[3]), .a_f(A[2]), .b_t(A[7]), .b_f(A[6]), .c_t(aa[3]), .c_f(aa[2]));

   (* keep = "true" *) dpl_noEE_xor x10 (.a_t(B[1]), .a_f(B[0]), .b_t(B[5]), .b_f(B[4]), .c_t(bb[1]), .c_f(bb[0]));
   (* keep = "true" *) dpl_noEE_xor x11 (.a_t(B[3]), .a_f(B[2]), .b_t(B[7]), .b_f(B[6]), .c_t(bb[3]), .c_f(bb[2]));

   (* keep = "true" *) wire [1:0] aa_01, bb_01, aabb_0, aabb_1, aabb_01, aabb_011;

   (* keep = "true" *) dpl_noEE_xor x12 (.a_t(aa[3]), .a_f(aa[2]), .b_t(aa[1]), .b_f(aa[0]), .c_t(aa_01[1]), .c_f(aa_01[0]));
   (* keep = "true" *) dpl_noEE_xor x13 (.a_t(bb[3]), .a_f(bb[2]), .b_t(bb[1]), .b_f(bb[0]), .c_t(bb_01[1]), .c_f(bb_01[0]));

   (* keep = "true" *) dpl_noEE_and a6 (.a_t(aa_01[1]), .a_f(aa_01[0]), .b_t(bb_01[1]), .b_f(bb_01[0]), .c_t(aabb_01[1]), .c_f(aabb_01[0]));

   (* keep = "true" *) dpl_noEE_and a14 (.a_t(aa[1]), .a_f(aa[0]), .b_t(bb[1]), .b_f(bb[0]), .c_t(aabb_0[1]), .c_f(aabb_0[0]));
   (* keep = "true" *) dpl_noEE_and a15 (.a_t(aa[3]), .a_f(aa[2]), .b_t(bb[3]), .b_f(bb[2]), .c_t(aabb_1[1]), .c_f(aabb_1[0]));

   (* keep = "true" *) dpl_noEE_xor x16 (.a_t(aabb_01[1]), .a_f(aabb_01[0]), .b_t(aabb_0[1]), .b_f(aabb_0[0]), .c_t(p[3]),        .c_f(p[2]));
   (* keep = "true" *) dpl_noEE_xor x17 (.a_t(aabb_01[1]), .a_f(aabb_01[0]), .b_t(aabb_1[1]), .b_f(aabb_1[0]), .c_t(aabb_011[1]), .c_f(aabb_011[0]));

   (* keep = "true" *) dpl_noEE_xor x18 (.a_t(aabb_011[1]), .a_f(aabb_011[0]), .b_t(p[3]), .b_f(p[2]), .c_t(p[1]), .c_f(p[0]));

   (* keep = "true" *) dpl_noEE_xor x19 (.a_t(ph[3]), .a_f(ph[2]), .b_t(p[3]), .b_f(p[2]), .c_t(C[7]), .c_f(C[6]));
   (* keep = "true" *) dpl_noEE_xor x20 (.a_t(ph[1]), .a_f(ph[0]), .b_t(p[1]), .b_f(p[0]), .c_t(C[5]), .c_f(C[4]));

   (* keep = "true" *) dpl_noEE_xor x21 (.a_t(pl[3]), .a_f(pl[2]), .b_t(p[3]), .b_f(p[2]), .c_t(C[3]), .c_f(C[2]));
   (* keep = "true" *) dpl_noEE_xor x22 (.a_t(pl[1]), .a_f(pl[0]), .b_t(p[1]), .b_f(p[0]), .c_t(C[1]), .c_f(C[0]));
 
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
   (* keep = "true" *) wire [7:0] c_0, c_1;

    // first domain
    (* keep = "true" *) MUL_4 m0 (.A(A_1), .B(B_1), .C(D));
    (* keep = "true" *) MUL_4 m1 (.A(A_1), .B(B_2), .C(c_0));

    //second domain
    (* keep = "true" *) MUL_4 m2 (.A(A_2), .B(B_1), .C(c_1));
    (* keep = "true" *) MUL_4 m3 (.A(A_2), .B(B_2), .C(G));

   (* keep = "true" *) gen_dpl_noEE_xor #(4) x0 (.A(c_0), .B(rand), .C(E));
   (* keep = "true" *) gen_dpl_noEE_xor #(4) x1 (.A(c_1), .B(rand), .C(F));
    
endmodule

module stage_one_DOM_GF_INV_4 (
    input  [7:0] A,
    output [3:0] a,
    output [3:0] b,
    output [3:0] D
);
   (* keep = "true" *) wire [3:0] c;

    assign a = A[7:4];
    assign b = A[3:0];
    // xor and square
   (* keep = "true" *) dpl_noEE_xor x0 (.a_t(a[1]), .a_f(a[0]), .b_t(b[1]), .b_f(b[0]), .c_t(c[3]), .c_f(c[2]));
   (* keep = "true" *) dpl_noEE_xor x1 (.a_t(a[3]), .a_f(a[2]), .b_t(b[3]), .b_f(b[2]), .c_t(c[1]), .c_f(c[0]));
    // scale
    assign D[3:2] = c[1:0];
   (* keep = "true" *) dpl_noEE_xor x2 (.a_t(c[1]), .a_f(c[0]), .b_t(c[3]), .b_f(c[2]), .c_t(D[1]), .c_f(D[0]));

endmodule

module stage_two_DOM_GF_INV_4 (
    input  [3:0] A,
    input  [3:0] B,
    output [3:0] D
);

    // xor and inversion
   (* keep = "true" *) dpl_noEE_xor x0 (.a_t(A[1]), .a_f(A[0]), .b_t(B[1]), .b_f(B[0]), .c_t(D[3]), .c_f(D[2]));
   (* keep = "true" *) dpl_noEE_xor x1 (.a_t(A[3]), .a_f(A[2]), .b_t(B[3]), .b_f(B[2]), .c_t(D[1]), .c_f(D[0]));
endmodule

module DOM_GF_INV_4 (
    input  [7:0]  A,
    input  [7:0]  B,
    input  [11:0] rand,
    input  [47:0] r2,
    input         req_5,
    input         rst,
    output [7:0]  G,
    output [7:0]  H,
    output [47:0] r5,
    output        req_2
);
    // first share
   (* keep = "true" *) wire [3:0] A_a, A_b, A_c; 
   (* keep = "true" *) stage_one_DOM_GF_INV_4 stage10 (.A(A), .a(A_a), .b(A_b), .D(A_c));

    // second share
   (* keep = "true" *) wire [3:0] B_a, B_b, B_c; 
   (* keep = "true" *) stage_one_DOM_GF_INV_4 stage11 (.A(B), .a(B_a), .b(B_b), .D(B_c));

   (* keep = "true" *) wire [3:0] A_d0, A_d1, B_d0, B_d1;
   (* keep = "true" *) DOM_GF_MULS_2 m0 (.A_1(A_a), .A_2(B_a), .B_1(A_b), .B_2(B_b), .rand(rand[3:0]), .D(A_d0), .E(A_d1), .F(B_d0), .G(B_d1));

   (* keep = "true" *) wire req_3;
   (* keep = "true" *) wire [95:0] lat_3;

    (* keep = "true" *) v_strong_indicating_latch_3 lat3 (.req_i(req_3), .rst(rst), .in({rand[11:4], r2, A_a, A_b, B_a, B_b, A_c, B_c, A_d0, A_d1, B_d0, B_d1}), .ack_o(req_2), .out(lat_3));
    
   (* keep = "true" *) wire [3:0] A_d, B_d;
   (* keep = "true" *) gen_dpl_noEE_xor #(2) x0 (.A(lat_3[15:12]), .B(lat_3[11:8]), .C(A_d));
   (* keep = "true" *) gen_dpl_noEE_xor #(2) x1 (.A(lat_3[7:4]), .B(lat_3[3:0]), .C(B_d));

    // first share
   (* keep = "true" *) wire [3:0] A_e; 
   (* keep = "true" *) stage_two_DOM_GF_INV_4 stage20 (.A(lat_3[23:20]), .B(A_d), .D(A_e));

    // second share
   (* keep = "true" *) wire [3:0] B_e; 
   (* keep = "true" *) stage_two_DOM_GF_INV_4 stage21 (.A(lat_3[19:16]), .B(B_d), .D(B_e));

   (* keep = "true" *) wire req_4;
   (* keep = "true" *) wire [79:0] lat_4;

   (* keep = "true" *) n_strong_indicating_latch_4 lat4 (.req_i(req_4), .rst(rst), .in({lat_3[95:24], A_e, B_e}), .ack_o(req_3), .out(lat_4));

   (* keep = "true" *) wire [3:0] A_f00, A_f01, A_f10, A_f11, B_f00, B_f01, B_f10, B_f11;
   (* keep = "true" *) DOM_GF_MULS_2 m1 (.A_1(lat_4[23:20]), .A_2(lat_4[15:12]), .B_1(lat_4[7:4]), .B_2(lat_4[3:0]), .rand(lat_4[75:72]), .D(A_f00), .E(A_f01), .F(B_f00), .G(B_f01));
   (* keep = "true" *) DOM_GF_MULS_2 m2 (.A_1(lat_4[19:16]), .A_2(lat_4[11:8]),  .B_1(lat_4[7:4]), .B_2(lat_4[3:0]), .rand(lat_4[79:76]), .D(A_f10), .E(A_f11), .F(B_f10), .G(B_f11));

   (* keep = "true" *) wire req_4a, req_4b;
   (* keep = "true" *) wire [39:0] lat_5a, lat_5b;
   (* keep = "true" *) v_strong_indicating_latch_5 lat5a (.req_i(req_5), .rst(rst), .in({lat_4[71:64], lat_4[55:40], A_f00, A_f01, B_f00, B_f01}), .ack_o(req_4a), .out(lat_5a));
   (* keep = "true" *) v_strong_indicating_latch_5 lat5b (.req_i(req_5), .rst(rst), .in({lat_4[63:56], lat_4[39:24], A_f10, A_f11, B_f10, B_f11}), .ack_o(req_4b), .out(lat_5b));

   (* keep = "true" *) muller_c_elem c_1 (.a(req_4a), .b(req_4b), .rst(rst), .c(req_4));

    assign r5 = {lat_5a[39:32], lat_5b[39:32], lat_5a[31:16], lat_5b[31:16]};

   (* keep = "true" *) wire [3:0] A_f0, A_f1, B_f0, B_f1;

   (* keep = "true" *) gen_dpl_noEE_xor #(2) x2 (.A(lat_5a[15:12]), .B(lat_5a[11:8]), .C(A_f0));
   (* keep = "true" *) gen_dpl_noEE_xor #(2) x3 (.A(lat_5b[15:12]), .B(lat_5b[11:8]), .C(A_f1));

   (* keep = "true" *) gen_dpl_noEE_xor #(2) x4 (.A(lat_5a[7:4]), .B(lat_5a[3:0]), .C(B_f0));
   (* keep = "true" *) gen_dpl_noEE_xor #(2) x5 (.A(lat_5b[7:4]), .B(lat_5b[3:0]), .C(B_f1));

    assign G = {A_f1, A_f0};
    assign H = {B_f1, B_f0};

endmodule

module square_scaler_4 (
    input  [7:0] A,
    output [7:0] B
);
    assign B[1:0] = A[1:0];
   (* keep = "true" *) dpl_noEE_xor x0 (.a_t(A[1]), .a_f(A[0]), .b_t(A[3]), .b_f(A[2]), .c_t(B[3]), .c_f(B[2]));
   (* keep = "true" *) dpl_noEE_xor x1 (.a_t(A[3]), .a_f(A[2]), .b_t(A[7]), .b_f(A[6]), .c_t(B[5]), .c_f(B[4]));
   (* keep = "true" *) dpl_noEE_xor x2 (.a_t(A[1]), .a_f(A[0]), .b_t(A[5]), .b_f(A[4]), .c_t(B[7]), .c_f(B[6]));

endmodule

module stage_one_DOM_GF_INV_8 (
    input  [15:0] A,
    output [7:0]  a,
    output [7:0]  b,
    output [7:0]  D
);
   (* keep = "true" *) wire [7:0] c;

    assign a = A[15:8];
    assign b = A[7:0];
   (* keep = "true" *) gen_dpl_noEE_xor #(4) x0 (.A(a), .B(b), .C(c));
   (* keep = "true" *) square_scaler_4 s0 (.A(c), .B(D));
endmodule

module stage_two_DOM_GF_INV_8 (
    input  [7:0] A,
    input  [7:0] B,
    output [7:0] C
);
   (* keep = "true" *) gen_dpl_noEE_xor #(4) x0 (.A(A), .B(B), .C(C));
endmodule

module DOM_GF_INV_8 (
    input  [15:0] A,
    input  [15:0] B,
    input  [35:0] rand,
    input         req_6,
    input         rst,
    output [15:0] G,
    output [15:0] H,
    output        req_0
);
    // first share
   (* keep = "true" *) wire [7:0] A_a, A_b, A_c; 
   (* keep = "true" *) stage_one_DOM_GF_INV_8 stage10 (.A(A), .a(A_a), .b(A_b), .D(A_c));

    // second share
   (* keep = "true" *) wire [7:0] B_a, B_b, B_c; 
   (* keep = "true" *) stage_one_DOM_GF_INV_8 stage11 (.A(B), .a(B_a), .b(B_b), .D(B_c));

   (* keep = "true" *) wire [7:0] A_d0, A_d1, B_d0, B_d1;
   (* keep = "true" *) DOM_GF_MULS_4 m0 (.A_1(A_a), .A_2(B_a), .B_1(A_b), .B_2(B_b), .rand(rand[7:0]), .D(A_d0), .E(A_d1), .F(B_d0), .G(B_d1));
    
   (* keep = "true" *) wire req_1;
   (* keep = "true" *) wire [107:0] lat_1;
   (* keep = "true" *) v_strong_indicating_latch_1 lat1 (.req_i(req_1), .rst(rst), .in({rand[35:8], A_a, A_b, B_a, B_b, A_c, B_c, A_d0, A_d1, B_d0, B_d1}), .ack_o(req_0), .out(lat_1));

   (* keep = "true" *) wire [7:0] A_d, B_d;
   (* keep = "true" *) gen_dpl_noEE_xor #(4) x0 (.A(lat_1[31:24]), .B(lat_1[23:16]), .C(A_d));
   (* keep = "true" *) gen_dpl_noEE_xor #(4) x1 (.A(lat_1[15:8]),  .B(lat_1[7:0]),   .C(B_d));

    // first share
   (* keep = "true" *) wire [7:0] A_e; 
   (* keep = "true" *) stage_two_DOM_GF_INV_8 stage20 (.A(lat_1[47:40]), .B(A_d), .C(A_e));

    // second share
   (* keep = "true" *) wire [7:0] B_e; 
   (* keep = "true" *) stage_two_DOM_GF_INV_8 stage21 (.A(lat_1[39:32]), .B(B_d), .C(B_e));

   (* keep = "true" *) wire req_2;
   (* keep = "true" *) wire [75:0] lat_2;
   (* keep = "true" *) n_strong_indicating_latch_2 lat2 (.req_i(req_2), .rst(rst), .in({lat_1[107:48], A_e, B_e}), .ack_o(req_1), .out(lat_2));

   (* keep = "true" *) wire [31:0] AB_ab_r2;
   (* keep = "true" *) wire [15:0] rand_r2;
    assign AB_ab_r2 = lat_2[47:16]; 
    assign rand_r2 = lat_2[75:60];

   (* keep = "true" *) wire [7:0] A_f, B_f;
   (* keep = "true" *) wire [47:0] rand_AB_ab_r5;

   (* keep = "true" *) wire req_5;
   (* keep = "true" *) DOM_GF_INV_4 inv4 (.A(lat_2[15:8]), .B(lat_2[7:0]), .rand(lat_2[59:48]), .r2({rand_r2, AB_ab_r2}), .req_5(req_5), .rst(rst), .G(A_f), .H(B_f), .r5(rand_AB_ab_r5), .req_2(req_2));

   (* keep = "true" *) wire [7:0] A_f00, A_f01, A_f10, A_f11, B_f00, B_f01, B_f10, B_f11;
   (* keep = "true" *) DOM_GF_MULS_4 m1 (.A_1(A_f), .A_2(B_f), .B_1(rand_AB_ab_r5[31:24]), .B_2(rand_AB_ab_r5[15:8]), .rand(rand_AB_ab_r5[39:32]), .D(A_f00), .E(A_f01), .F(B_f00), .G(B_f01));

   (* keep = "true" *) DOM_GF_MULS_4 m2 (.A_1(A_f), .A_2(B_f), .B_1(rand_AB_ab_r5[23:16]), .B_2(rand_AB_ab_r5[7:0]),  .rand(rand_AB_ab_r5[47:40]), .D(A_f10), .E(A_f11), .F(B_f10), .G(B_f11));
    
   (* keep = "true" *) wire req_5a, req_5b;
   (* keep = "true" *) wire [31:0] lat_6a, lat_6b;
   (* keep = "true" *) n_strong_indicating_latch_6 lat6a (.req_i(req_6), .rst(rst), .in({A_f00, A_f01, B_f00, B_f01}), .ack_o(req_5a), .out(lat_6a));
   (* keep = "true" *) n_strong_indicating_latch_6 lat6b (.req_i(req_6), .rst(rst), .in({A_f10, A_f11, B_f10, B_f11}), .ack_o(req_5b), .out(lat_6b));

   (* keep = "true" *) muller_c_elem c_1 (.a(req_5a), .b(req_5b), .rst(rst), .c(req_5));

   (* keep = "true" *) wire [7:0] A_f0, A_f1, B_f0, B_f1;

   (* keep = "true" *) gen_dpl_noEE_xor #(4) x2 (.A(lat_6a[31:24]), .B(lat_6a[23:16]), .C(A_f0));
   (* keep = "true" *) gen_dpl_noEE_xor #(4) x3 (.A(lat_6b[31:24]), .B(lat_6b[23:16]), .C(A_f1));
   (* keep = "true" *) gen_dpl_noEE_xor #(4) x4 (.A(lat_6a[15:8]),  .B(lat_6a[7:0]),   .C(B_f0));
   (* keep = "true" *) gen_dpl_noEE_xor #(4) x5 (.A(lat_6b[15:8]),  .B(lat_6b[7:0]),   .C(B_f1));

    assign G = {A_f1, A_f0};
    assign H = {B_f1, B_f0};

endmodule


module Mapping(
    input  [15:0] A,
    output [15:0] B
);
   (* keep = "true" *) wire [1:0] a_00, a_01, a_02;

   (* keep = "true" *) dpl_noEE_xor r01 (.a_t(A[13]),   .a_f(A[12]),   .b_t(A[7]),   .b_f(A[6]),   .c_t(a_00[1]), .c_f(a_00[0]));
   (* keep = "true" *) dpl_noEE_xor r02 (.a_t(a_00[1]), .a_f(a_00[0]), .b_t(A[5]),   .b_f(A[4]),   .c_t(a_01[1]), .c_f(a_01[0]));
   (* keep = "true" *) dpl_noEE_xor r03 (.a_t(a_01[1]), .a_f(a_01[0]), .b_t(A[3]),   .b_f(A[2]),   .c_t(a_02[1]), .c_f(a_02[0]));
   (* keep = "true" *) dpl_noEE_xor r04 (.a_t(a_02[1]), .a_f(a_02[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[1]),    .c_f(B[0]));

   (* keep = "true" *) wire [1:0] a_10;

   (* keep = "true" *) dpl_noEE_xor r11 (.a_t(A[13]),   .a_f(A[12]),   .b_t(A[11]),  .b_f(A[10]),  .c_t(a_10[1]), .c_f(a_10[0]));
   (* keep = "true" *) dpl_noEE_xor r12 (.a_t(a_10[1]), .a_f(a_10[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[3]),    .c_f(B[2]));

    assign B[5:4] = A[1:0];

   (* keep = "true" *) wire [1:0] a_30, a_31, a_32;

   (* keep = "true" *) dpl_noEE_xor r31 (.a_t(A[15]),   .a_f(A[14]),   .b_t(A[9]),   .b_f(A[8]),   .c_t(a_30[1]), .c_f(a_30[0]));
   (* keep = "true" *) dpl_noEE_xor r32 (.a_t(a_30[1]), .a_f(a_30[0]), .b_t(A[7]),   .b_f(A[6]),   .c_t(a_31[1]), .c_f(a_31[0]));
   (* keep = "true" *) dpl_noEE_xor r33 (.a_t(a_31[1]), .a_f(a_31[0]), .b_t(A[3]),   .b_f(A[2]),   .c_t(a_32[1]), .c_f(a_32[0]));
   (* keep = "true" *) dpl_noEE_xor r34 (.a_t(a_32[1]), .a_f(a_32[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[7]),    .c_f(B[6]));

   (* keep = "true" *) wire [1:0] a_40, a_41;

   (* keep = "true" *) dpl_noEE_xor r41 (.a_t(A[15]),   .a_f(A[14]),   .b_t(A[13]),  .b_f(A[12]),  .c_t(a_40[1]), .c_f(a_40[0]));
   (* keep = "true" *) dpl_noEE_xor r42 (.a_t(a_40[1]), .a_f(a_40[0]), .b_t(A[11]),  .b_f(A[10]),  .c_t(a_41[1]), .c_f(a_41[0]));
   (* keep = "true" *) dpl_noEE_xor r43 (.a_t(a_41[1]), .a_f(a_41[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[9]),    .c_f(B[8]));

   (* keep = "true" *) wire [1:0] a_50, a_51;

   (* keep = "true" *) dpl_noEE_xor r51 (.a_t(A[13]),   .a_f(A[12]),   .b_t(A[11]),  .b_f(A[10]),  .c_t(a_50[1]), .c_f(a_50[0]));
   (* keep = "true" *) dpl_noEE_xor r52 (.a_t(a_50[1]), .a_f(a_50[0]), .b_t(A[3]),   .b_f(A[2]),   .c_t(a_51[1]), .c_f(a_51[0]));
   (* keep = "true" *) dpl_noEE_xor r53 (.a_t(a_51[1]), .a_f(a_51[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[11]),   .c_f(B[10]));

   (* keep = "true" *) wire [1:0] a_60, a_61;

    (* keep = "true" *) dpl_noEE_xor r61 (.a_t(A[13]),   .a_f(A[12]),   .b_t(A[11]),  .b_f(A[10]),  .c_t(a_60[1]), .c_f(a_60[0]));
    (* keep = "true" *) dpl_noEE_xor r62 (.a_t(a_60[1]), .a_f(a_60[0]), .b_t(A[9]),   .b_f(A[8]),   .c_t(a_61[1]), .c_f(a_61[0]));
    (* keep = "true" *) dpl_noEE_xor r63 (.a_t(a_61[1]), .a_f(a_61[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[13]),   .c_f(B[12]));

    (* keep = "true" *) wire [1:0] a_70, a_71, a_72, a_73;

   (* keep = "true" *) dpl_noEE_xor r71 (.a_t(A[15]),   .a_f(A[14]),   .b_t(A[13]),  .b_f(A[12]),  .c_t(a_70[1]), .c_f(a_70[0]));
   (* keep = "true" *) dpl_noEE_xor r72 (.a_t(a_70[1]), .a_f(a_70[0]), .b_t(A[11]),  .b_f(A[10]),  .c_t(a_71[1]), .c_f(a_71[0]));
   (* keep = "true" *) dpl_noEE_xor r73 (.a_t(a_71[1]), .a_f(a_71[0]), .b_t(A[5]),   .b_f(A[4]),   .c_t(a_72[1]), .c_f(a_72[0]));
   (* keep = "true" *) dpl_noEE_xor r74 (.a_t(a_72[1]), .a_f(a_72[0]), .b_t(A[3]),   .b_f(A[2]),   .c_t(a_73[1]), .c_f(a_73[0]));
   (* keep = "true" *) dpl_noEE_xor r75 (.a_t(a_73[1]), .a_f(a_73[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[15]),   .c_f(B[14]));
endmodule

module inv_Mapping(
    input  [15:0] A,
    output [15:0] B
);
    (* keep = "true" *) wire [1:0] a_00;

    (* keep = "true" *) dpl_noEE_xor r01 (.a_t(A[13]),   .a_f(A[12]),   .b_t(A[9]),   .b_f(A[8]),   .c_t(a_00[1]), .c_f(a_00[0]));
    (* keep = "true" *) dpl_noEE_xor r02 (.a_t(a_00[1]), .a_f(a_00[0]), .b_t(A[3]),   .b_f(A[2]),   .c_t(B[1]),    .c_f(B[0]));

    (* keep = "true" *) wire [1:0] a_10;

    (* keep = "true" *) dpl_noEE_xor r11 (.a_t(A[11]),   .a_f(A[10]),   .b_t(A[9]),   .b_f(A[8]),   .c_t(a_10[1]), .c_f(a_10[0]));
    (* keep = "true" *) dpl_noEE_xor r12 (.a_t(a_10[1]), .a_f(a_10[0]), .b_t(A[3]),   .b_f(A[2]),   .c_t(B[3]),    .c_f(B[2]));

    (* keep = "true" *) wire [1:0] a_20, a_21, a_22;

    (* keep = "true" *) dpl_noEE_xor r21 (.a_t(A[13]),   .a_f(A[12]),   .b_t(A[11]),  .b_f(A[10]),  .c_t(a_20[1]), .c_f(a_20[0]));
    (* keep = "true" *) dpl_noEE_xor r22 (.a_t(a_20[1]), .a_f(a_20[0]), .b_t(A[7]),   .b_f(A[6]),   .c_t(a_21[1]), .c_f(a_21[0]));
    (* keep = "true" *) dpl_noEE_xor r23 (.a_t(a_21[1]), .a_f(a_21[0]), .b_t(A[5]),   .b_f(A[4]),   .c_t(a_22[1]), .c_f(a_22[0]));
    (* keep = "true" *) dpl_noEE_xor r24 (.a_t(a_22[1]), .a_f(a_22[0]), .b_t(A[1]),   .b_f(A[0]),   .c_t(B[5]),    .c_f(B[4]));

    (* keep = "true" *) wire [1:0] a_30, a_31, a_32;

    (* keep = "true" *) dpl_noEE_xor r31 (.a_t(A[15]),   .a_f(A[14]),   .b_t(A[13]),  .b_f(A[12]),  .c_t(a_30[1]), .c_f(a_30[0]));
    (* keep = "true" *) dpl_noEE_xor r32 (.a_t(a_30[1]), .a_f(a_30[0]), .b_t(A[11]),  .b_f(A[10]),  .c_t(a_31[1]), .c_f(a_31[0]));
    (* keep = "true" *) dpl_noEE_xor r33 (.a_t(a_31[1]), .a_f(a_31[0]), .b_t(A[9]),   .b_f(A[8]),   .c_t(a_32[1]), .c_f(a_32[0]));
    (* keep = "true" *) dpl_noEE_xor r34 (.a_t(a_32[1]), .a_f(a_32[0]), .b_t(A[7]),   .b_f(A[6]),   .c_t(B[7]),    .c_f(B[6]));

    (* keep = "true" *) wire [1:0] a_40;

    (* keep = "true" *) dpl_noEE_xor r41 (.a_t(A[15]),   .a_f(A[14]),   .b_t(A[11]),  .b_f(A[10]),  .c_t(a_40[1]), .c_f(a_40[0]));
    (* keep = "true" *) dpl_noEE_xor r42 (.a_t(a_40[1]), .a_f(a_40[0]), .b_t(A[7]),   .b_f(A[6]),   .c_t(B[9]),    .c_f(B[8]));

    (* keep = "true" *) dpl_noEE_xor r51 (.a_t(A[13]),   .a_f(A[12]),   .b_t(A[1]),   .b_f(A[0]),   .c_t(B[11]), .c_f(B[10]));

    (* keep = "true" *) dpl_noEE_xor r61 (.a_t(A[15]),   .a_f(A[14]),   .b_t(A[7]),   .b_f(A[6]),   .c_t(B[13]), .c_f(B[12]));

    (* keep = "true" *) dpl_noEE_xor r71 (.a_t(A[11]),   .a_f(A[10]),   .b_t(A[7]),   .b_f(A[6]),   .c_t(B[15]), .c_f(B[14]));
endmodule

module Sbox (
    input  [15:0] A,
    input  [15:0] B,
    input  [35:0] rand,
    input         req_7,
    input         rst,
    output [15:0] E,
    output [15:0] F,
    output        ack_0
);
    /* linear mapping & change basis to GF(2^8)/GF(2^4)/GF(2^2) */
    // first share
    (* keep = "true" *) wire [15:0] A_C, A_D;
    (* keep = "true" *) Mapping m0 (.A(A), .B(A_C));

    // second share
    (* keep = "true" *) wire [15:0] B_C, B_D;
    (* keep = "true" *) Mapping m1 (.A(B), .B(B_C));

    (* keep = "true" *) wire req_0;
    (* keep = "true" *) wire [67:0] lat_0;
    (* keep = "true" *) n_strong_indicating_latch_0 lat0 (.req_i(req_0), .rst(rst), .in({rand, A_C, B_C}), .ack_o(ack_0), .out(lat_0));
    
    // inversion
    (* keep = "true" *) wire req_6;
    (* keep = "true" *) DOM_GF_INV_8 inv (.A(lat_0[31:16]), .B(lat_0[15:0]), .rand(lat_0[67:32]), .req_6(req_6), .rst(rst), .G(A_D), .H(B_D), .req_0(req_0));


    /* linear iverse mapping & change basis back to GF(2^8) */
    // first share 
    (* keep = "true" *) wire [15:0] e_t, e, f;
    (* keep = "true" *) inv_Mapping im0 (.A(A_D), .B(e_t));

    (* keep = "true" *) gen_dpl_noEE_xor #(8) x0 (.A(e_t), .B(16'b110100101011010), .C(e));

    // second share
    (* keep = "true" *) inv_Mapping im1 (.A(B_D), .B(f));

    (* keep = "true" *) wire [31:0] lat_7;
    (* keep = "true" *) v_strong_indicating_latch_7 lat7 (.req_i(req_7), .rst(rst), .in({e, f}), .ack_o(req_6), .out(lat_7));
    assign E = lat_7[31:16];
    assign F = lat_7[15:0];

endmodule


module dff(
    input trigger,
    input reset,
    input [15:0] d,
    output reg [15:0] q
);
    always @(posedge trigger) begin
        if (reset) begin
            q <= 16'b0;
        end else begin
            q <= d;
        end
    end
endmodule

module inverterchain  #(
    parameter delay = 200
) 
(
    input  inp,
    output ack
);
    (* keep = "true" *) wire [delay:0] inverterchain;
    assign inverterchain[0] = inp;
    assign ack = inverterchain[delay];
    genvar index;
    generate
        for (index = 0; index < delay; index = index + 1) begin
            assign inverterchain[index+1] = ~inverterchain[index];
        end
    endgenerate
endmodule
