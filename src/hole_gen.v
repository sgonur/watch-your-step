`timescale 1ns / 1ps

module hole_gen(
    input  wire        clk,
    input  wire        rst,
    input  wire        frame_tick,
    output wire [9:0]  hole_x,
    output wire [6:0]  hole_w
);

    // LFSR
    wire [7:0] rnd;
    lfsr rng (
        .clk_i (clk),
        .ce_i  (frame_tick),
        .q_o   (rnd)
    );

    // take 5 bits and add 31
    wire [4:0] rnd5 = rnd[4:0];           // 0-31
    wire [4:0] m31  = (rnd5 == 5'd31) ? 5'd0 : rnd5;
    wire [6:0] w_next = 7'd41 + m31;      // 41-71  
    

    // 3) Detect when hole needs reset (reaches left edge) WRONG
    wire hole_off = ((hole_x + hole_w) <= 10'd8);
    
    // 4) Compute next hole_x:
    wire [9:0] x_next = hole_off ? 10'd640 : hole_x - 10'd1;
    

    wire [6:0] w_update = (hole_off)? w_next : hole_w;

    FDRE #(.INIT(1'b0)) hx0(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[0]), .Q(hole_x[0]));
    FDRE #(.INIT(1'b0)) hx1(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[1]), .Q(hole_x[1]));
    FDRE #(.INIT(1'b0)) hx2(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[2]), .Q(hole_x[2]));
    FDRE #(.INIT(1'b0)) hx3(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[3]), .Q(hole_x[3]));
    FDRE #(.INIT(1'b0)) hx4(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[4]), .Q(hole_x[4]));
    FDRE #(.INIT(1'b0)) hx5(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[5]), .Q(hole_x[5]));
    FDRE #(.INIT(1'b0)) hx6(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[6]), .Q(hole_x[6]));
    FDRE #(.INIT(1'b0)) hx7(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[7]), .Q(hole_x[7]));
    FDRE #(.INIT(1'b0)) hx8(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[8]), .Q(hole_x[8]));
    FDRE #(.INIT(1'b0)) hx9(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[9]), .Q(hole_x[9]));

    FDRE #(.INIT(1'b0)) hw0(.C(clk), .CE(frame_tick), .R(rst), .D(w_update[0]), .Q(hole_w[0]));
    FDRE #(.INIT(1'b0)) hw1(.C(clk), .CE(frame_tick), .R(rst), .D(w_update[1]), .Q(hole_w[1]));
    FDRE #(.INIT(1'b0)) hw2(.C(clk), .CE(frame_tick), .R(rst), .D(w_update[2]), .Q(hole_w[2]));
    FDRE #(.INIT(1'b0)) hw3(.C(clk), .CE(frame_tick), .R(rst), .D(w_update[3]), .Q(hole_w[3]));
    FDRE #(.INIT(1'b0)) hw4(.C(clk), .CE(frame_tick), .R(rst), .D(w_update[4]), .Q(hole_w[4]));
    FDRE #(.INIT(1'b0)) hw5(.C(clk), .CE(frame_tick), .R(rst), .D(w_update[5]), .Q(hole_w[5]));
    FDRE #(.INIT(1'b0)) hw6(.C(clk), .CE(frame_tick), .R(rst), .D(w_update[6]), .Q(hole_w[6]));

endmodule