`timescale 1ns / 1ps
    
module ball_controller(
    input  wire        clk,          // 25 MHz pixel clock
    input  wire        rst,          // synchronous reset
    input  wire        frame_tick,   // one-cycle pulse per frame
    input  wire [9:0]  player_x,     // fixed player X (e.g. 100)
    input  wire [9:0]  player_y,     // dynamic player Y
    input  wire [9:0]  ball_x,       // dynamic ball X
    input  wire [9:0]  ball_y,       // dynamic ball Y
    output wire        ball_vis,     // draw-ball flag
    output wire        ball_flash,   // in-flash-state flag
    output wire [3:0]  score,        // hit count (0-15)
    output wire ball_pause,
    output wire tagged
    );

    wire [9:0] PL = player_x;
    wire [9:0] PR = player_x + 10'd16;
    wire [9:0] PT = player_y;
    wire [9:0] PB = player_y + 10'd16;
    wire [9:0] BL = ball_x;
    wire [9:0] BR = ball_x + 10'd8;
    wire [9:0] BT = ball_y;
    wire [9:0] BB = ball_y + 10'd8;
    
    wire overlap_h = (PL < BR) && (PR > BL);
    wire overlap_v = (PT < BB) && (PB > BT);
    wire collided  = overlap_h && overlap_v;
    
    wire collision_frame;
    FDRE #(.INIT(1'b0)) coll_mem (.C(clk), .CE(1'b1), .R(frame_tick), .D(collided), .Q(collision_frame));
    
    wire prev_coll;
    FDRE #(.INIT(1'b0)) prev_ff (.C(clk), .CE(frame_tick),. R(rst), .D(collision_frame), .Q(prev_coll));
    wire coll_pulse = (collision_frame & ~prev_coll) & s_move;
    assign tagged = coll_pulse;
    

    wire s_move, s_flash, s_wait;   
    wire n_move, n_flash, n_wait;
    wire off_left = (ball_x < 10'd4);
    
    // 7-bit counter for 120 frames (2 seconds at 60Hz)
    wire [6:0] blink_cnt;
    wire [6:0] blink_cnt_next = s_flash ? blink_cnt + 7'd1 : 7'd0;
    // Count to 119 (0-119 = 120 frames)
    wire cnt_max = (blink_cnt == 7'd119);
    
    FDRE #(.INIT(1'b0)) b0 (.C(clk), .CE(frame_tick), .R(1'b0), .D(blink_cnt_next[0]), .Q(blink_cnt[0]));
    FDRE #(.INIT(1'b0)) b1 (.C(clk), .CE(frame_tick), .R(1'b0), .D(blink_cnt_next[1]), .Q(blink_cnt[1]));
    FDRE #(.INIT(1'b0)) b2 (.C(clk), .CE(frame_tick), .R(1'b0), .D(blink_cnt_next[2]), .Q(blink_cnt[2]));
    FDRE #(.INIT(1'b0)) b3 (.C(clk), .CE(frame_tick), .R(1'b0), .D(blink_cnt_next[3]), .Q(blink_cnt[3]));
    FDRE #(.INIT(1'b0)) b4 (.C(clk), .CE(frame_tick), .R(1'b0), .D(blink_cnt_next[4]), .Q(blink_cnt[4]));
    FDRE #(.INIT(1'b0)) b5 (.C(clk), .CE(frame_tick), .R(1'b0), .D(blink_cnt_next[5]), .Q(blink_cnt[5]));
    FDRE #(.INIT(1'b0)) b6 (.C(clk), .CE(frame_tick), .R(1'b0), .D(blink_cnt_next[6]), .Q(blink_cnt[6]));

    assign n_move  = (s_move  & ~collision_frame) | (s_wait  & off_left);
    assign n_flash = (s_move  &  collision_frame) | (s_flash & ~cnt_max);
    assign n_wait  = (s_flash &  cnt_max) | (s_wait  & ~off_left);
        
    FDRE #(.INIT(1'b1)) st_move  (.C(clk), .CE(frame_tick), .R(rst), .D(n_move),  .Q(s_move));
    FDRE #(.INIT(1'b0)) st_flash (.C(clk), .CE(frame_tick), .R(rst), .D(n_flash), .Q(s_flash));
    FDRE #(.INIT(1'b0)) st_wait  (.C(clk), .CE(frame_tick), .R(rst), .D(n_wait),  .Q(s_wait));
    
    wire [3:0] score_reg;
    wire [3:0] sc_inc  = score_reg + 4'd1;
    wire       sc_max  = &score_reg;
    wire [3:0] sc_next = (coll_pulse & ~sc_max) ? sc_inc : score_reg;

    FDRE s0 (.C(clk), .CE(frame_tick), .R(rst), .D(sc_next[0]), .Q(score_reg[0]));
    FDRE s1 (.C(clk), .CE(frame_tick), .R(rst), .D(sc_next[1]), .Q(score_reg[1]));
    FDRE s2 (.C(clk), .CE(frame_tick), .R(rst), .D(sc_next[2]), .Q(score_reg[2]));
    FDRE s3 (.C(clk), .CE(frame_tick), .R(rst), .D(sc_next[3]), .Q(score_reg[3]));

    // Flash at 4Hz using bit 3 of counter (divides by 8)
    assign ball_vis   = s_move || (s_flash && blink_cnt[3]); 
    assign ball_flash = s_flash;
    assign score      = score_reg;
    assign ball_pause = s_flash;
    
endmodule