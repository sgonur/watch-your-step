`timescale 1ns / 1ps

// Phase 6: Ball generation and movement (structural, no loops)
module ball_gen(
    input  wire        clk,         // 25 MHz pixel clock
    input  wire        rst,         // active-high synchronous reset
    input  wire        frame_tick,  // one-cycle pulse per frame
    output wire [9:0]  ball_x,      // left-edge X of 8×8 ball
    output wire [9:0]  ball_y       // top-edge Y of 8×8 ball
);

  // 1) Random vertical position source: reuse 8-bit LFSR
  wire [7:0] rnd;
  lfsr rng (
    .clk_i(clk),
    .ce_i (frame_tick),
    .q_o  (rnd)
  );

  // 2) Map rnd[5:0] (0..63) into 0..60, then add 192 ? 192..252
  wire [5:0] r6   = rnd[5:0];
  wire [5:0] m61  = (r6 >= 6'd61) ? r6 - 6'd61 : r6;
  wire [9:0] y_next = 10'd192 + m61;

  // 3) Horizontal motion: 4 px/frame left, respawn at right after off-screen
  wire off_left_x = (ball_x < 10'd4);  // <4 ensures fully off-screen
  wire [9:0] x_shift = ball_x - 10'd4;
  wire [9:0] x_next  = rst        ? 10'd640 :  // reset to right
                       off_left_x ? 10'd640 :  // respawn
                                    x_shift;    // shift left

  // 4) Vertical update: on reset or respawn use y_next, else hold
  wire [9:0] y_d = (rst || off_left_x) ? y_next : ball_y;

  // 5) Register horizontal position (10 bits)
  FDRE #(.INIT(1'b0)) bx0 (.C(clk), .CE(frame_tick), .R(rst), .D(x_next[0]), .Q(ball_x[0]));
  FDRE #(.INIT(1'b0)) bx1 (.C(clk), .CE(frame_tick), .R(rst), .D(x_next[1]), .Q(ball_x[1]));
  FDRE #(.INIT(1'b0)) bx2 (.C(clk), .CE(frame_tick), .R(rst), .D(x_next[2]), .Q(ball_x[2]));
  FDRE #(.INIT(1'b0)) bx3 (.C(clk), .CE(frame_tick), .R(rst), .D(x_next[3]), .Q(ball_x[3]));
  FDRE #(.INIT(1'b0)) bx4 (.C(clk), .CE(frame_tick), .R(rst), .D(x_next[4]), .Q(ball_x[4]));
  FDRE #(.INIT(1'b0)) bx5 (.C(clk), .CE(frame_tick), .R(rst), .D(x_next[5]), .Q(ball_x[5]));
  FDRE #(.INIT(1'b0)) bx6 (.C(clk), .CE(frame_tick), .R(rst), .D(x_next[6]), .Q(ball_x[6]));
  FDRE #(.INIT(1'b0)) bx7 (.C(clk), .CE(frame_tick), .R(rst), .D(x_next[7]), .Q(ball_x[7]));
  FDRE #(.INIT(1'b0)) bx8 (.C(clk), .CE(frame_tick), .R(rst), .D(x_next[8]), .Q(ball_x[8]));
  FDRE #(.INIT(1'b0)) bx9 (.C(clk), .CE(frame_tick), .R(rst), .D(x_next[9]), .Q(ball_x[9]));

  // 6) Register vertical position (10 bits)
  FDRE #(.INIT(1'b0)) by0 (.C(clk), .CE(frame_tick), .R(rst), .D(y_d[0]), .Q(ball_y[0]));
  FDRE #(.INIT(1'b0)) by1 (.C(clk), .CE(frame_tick), .R(rst), .D(y_d[1]), .Q(ball_y[1]));
  FDRE #(.INIT(1'b0)) by2 (.C(clk), .CE(frame_tick), .R(rst), .D(y_d[2]), .Q(ball_y[2]));
  FDRE #(.INIT(1'b0)) by3 (.C(clk), .CE(frame_tick), .R(rst), .D(y_d[3]), .Q(ball_y[3]));
  FDRE #(.INIT(1'b0)) by4 (.C(clk), .CE(frame_tick), .R(rst), .D(y_d[4]), .Q(ball_y[4]));
  FDRE #(.INIT(1'b0)) by5 (.C(clk), .CE(frame_tick), .R(rst), .D(y_d[5]), .Q(ball_y[5]));
  FDRE #(.INIT(1'b0)) by6 (.C(clk), .CE(frame_tick), .R(rst), .D(y_d[6]), .Q(ball_y[6]));
  FDRE #(.INIT(1'b0)) by7 (.C(clk), .CE(frame_tick), .R(rst), .D(y_d[7]), .Q(ball_y[7]));
  FDRE #(.INIT(1'b0)) by8 (.C(clk), .CE(frame_tick), .R(rst), .D(y_d[8]), .Q(ball_y[8]));
  FDRE #(.INIT(1'b0)) by9 (.C(clk), .CE(frame_tick), .R(rst), .D(y_d[9]), .Q(ball_y[9]));

endmodule
