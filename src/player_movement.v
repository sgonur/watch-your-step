`timescale 1ns / 1ps

module player_movement(
    input  wire        clk,          // 25 MHz pixel clock
    input  wire        rst,         // active-high synchronous reset (btnR)
    input  wire        btnU,        // raw up-button
    input  wire        frame_tick,  // one-cycle pulse per frame (~60 Hz)
    input  wire [9:0]  hole_x,      // hole left-edge
    input  wire [6:0]  hole_w,      // hole width
    input  wire        ignore_hole,
    input  wire lives,
    output wire [9:0]  player_y,    // top-edge Y of 16×16 player sprite
    output wire [9:0]  player_x,
    output wire [6:0]  power_count,  // 0…64 jump charge level
    output wire player_died,
    output wire player_vis,
    output wire over_hole_math,
    output wire  [6:0] test_led
);


  wire btnU_s1, btnU_s2;
  FDRE #(.INIT(1'b0)) sync0 (.C(clk), .CE(frame_tick), .R(rst), .D(btnU),    .Q(btnU_s1));
  FDRE #(.INIT(1'b0)) sync1 (.C(clk), .CE(frame_tick), .R(rst), .D(btnU_s1), .Q(btnU_s2));
  wire btnU_rise =  btnU_s1 & ~btnU_s2;  // press detected
  wire btnU_fall = ~btnU_s1 &  btnU_s2;  // release detected
  wire btnU_hold =  btnU_s1 &  btnU_s2;  // held high

  wire on_ground = (player_y == 10'd344);
  wire [9:0] player_r = player_x + 10'd16;
  
  // CORRECTED HOLE BOUNDARIES: Left edge = hole_x, Right edge = hole_x + hole_w
  wire [9:0] hole_r = hole_x + {3'b000, hole_w}; 
  
  // CORRECTED: Player falls only if entirely within hole
  wire over_hole = on_ground && ~ignore_hole &&
                  (player_x >= hole_x - 10'd100) && 
                  (player_r <= hole_r - 10'd100);
  
  wire is_vulnerable = s_idle | s_chg | s_asc;  // Only die in these states

  assign over_hole_math = on_ground && ~ignore_hole && is_vulnerable
                     && (player_x >= hole_x - 10'd100)
                     && (player_r <= hole_r - 10'd100);



  // 3) One-hot state registers
  //    s_idle  = initial state
  //    s_chg   = charging jump
  //    s_asc   = ascending
  //    s_desc  = descending back to platform
  //    s_fall  = falling through hole
  //    s_dead  = game over (fallen)

  wire s_idle, s_chg, s_asc, s_desc, s_fall, s_dead, s_relive;
  wire n_idle, n_chg, n_asc, n_desc, n_fall, n_dead, n_relive;


      // 3) One-hot FSM next-state logic
    assign n_idle  = (s_idle  & ~btnU_rise & ~over_hole)
                   | (s_desc  & (player_y == 10'd344))
                   | (s_relive & (player_y > 10'd344));
    
    assign n_chg   = (s_chg   &  btnU_hold & ~over_hole)
                   | (s_idle  &  btnU_rise & ~over_hole)
                   | (s_desc  & btnU_hold);
    
    assign n_asc   = (s_asc   & (power_count != 7'd0))
                   | (s_chg   &  btnU_fall & ~  over_hole & on_ground);
    
    assign n_desc  = (s_desc  & (player_y != 10'd344))
                   | (s_asc   & (power_count == 7'd0));
    
    assign n_fall  = (s_fall  & (player_y < 10'd456))
                   | ((s_idle | s_chg) & over_hole);
    
    assign n_relive = (s_fall & (player_y >= 10'd456) & lives) | (s_relive & (player_y > 10'd344));
    
    // only die if you finish a fall and you have no lives
    assign n_dead  =  s_dead
                   | (s_fall  & (player_y >= 10'd456) & ~lives);


  FDRE #(.INIT(1'b1)) st_idle (.C(clk), .CE(frame_tick), .R(rst), .D(n_idle), .Q(s_idle));
  FDRE #(.INIT(1'b0)) st_chg  (.C(clk), .CE(frame_tick), .R(rst), .D(n_chg),  .Q(s_chg));
  FDRE #(.INIT(1'b0)) st_asc  (.C(clk), .CE(frame_tick), .R(rst), .D(n_asc),  .Q(s_asc));
  FDRE #(.INIT(1'b0)) st_desc (.C(clk), .CE(frame_tick), .R(rst), .D(n_desc), .Q(s_desc));
  FDRE #(.INIT(1'b0)) st_fall (.C(clk), .CE(frame_tick), .R(rst), .D(n_fall), .Q(s_fall));
  FDRE #(.INIT(1'b0)) st_dead (.C(clk), .CE(frame_tick), .R(rst), .D(n_dead), .Q(s_dead));
  FDRE #(.INIT(1'b0)) st_relive (.C(clk), .CE(frame_tick), .R(rst), .D(n_relive), .Q(s_relive));
  
  assign player_died = s_fall | s_dead;
  wire [3:0] flash_counter;
  wire flash_tick = (flash_counter == 4'd14);  // Divide by 15 (60Hz/15=4Hz)
  wire [3:0] flash_counter_next = flash_tick ? 4'd0 : flash_counter + 1;
  
  FDRE #(.INIT(1'b0)) fc0 (.C(clk), .CE(frame_tick), .R(rst), .D(flash_counter_next[0]), .Q(flash_counter[0]));
  FDRE #(.INIT(1'b0)) fc1 (.C(clk), .CE(frame_tick), .R(rst), .D(flash_counter_next[1]), .Q(flash_counter[1]));
  FDRE #(.INIT(1'b0)) fc2 (.C(clk), .CE(frame_tick), .R(rst), .D(flash_counter_next[2]), .Q(flash_counter[2]));
  FDRE #(.INIT(1'b0)) fc3 (.C(clk), .CE(frame_tick), .R(rst), .D(flash_counter_next[3]), .Q(flash_counter[3]));
  
  
  wire flash_toggle;
  FDRE #(.INIT(1'b0)) flash_toggle_ff (
      .C(clk),
      .CE(frame_tick && flash_tick & (s_fall | s_dead)),  // Toggle only in death states
      .R(rst),
      .D(~flash_toggle),                   // Invert current value
      .Q(flash_toggle)
  );

  // Death event detection (rising edge of player_died)
  wire prev_died;
  FDRE #(.INIT(1'b0)) died_ff (.C(clk), .CE(1'b1), .R(rst), .D(player_died), .Q(prev_died));
  wire death_event = player_died & ~prev_died;

  // 6-bit flash counter (0-63 frames)
  wire [5:0] flash_cnt;
  wire [5:0] flash_cnt_next = (death_event) ? 6'd0 : 
                             ((flash_cnt < 6'd63) ? flash_cnt + 1 : flash_cnt);
  
  FDRE #(.INIT(1'b0)) f0 (.C(clk), .CE(frame_tick), .R(rst), .D(flash_cnt_next[0]), .Q(flash_cnt[0]));
  FDRE #(.INIT(1'b0)) f1 (.C(clk), .CE(frame_tick), .R(rst), .D(flash_cnt_next[1]), .Q(flash_cnt[1]));
  FDRE #(.INIT(1'b0)) f2 (.C(clk), .CE(frame_tick), .R(rst), .D(flash_cnt_next[2]), .Q(flash_cnt[2]));
  FDRE #(.INIT(1'b0)) f3 (.C(clk), .CE(frame_tick), .R(rst), .D(flash_cnt_next[3]), .Q(flash_cnt[3]));
  FDRE #(.INIT(1'b0)) f4 (.C(clk), .CE(frame_tick), .R(rst), .D(flash_cnt_next[4]), .Q(flash_cnt[4]));
  FDRE #(.INIT(1'b0)) f5 (.C(clk), .CE(frame_tick), .R(rst), .D(flash_cnt_next[5]), .Q(flash_cnt[5]));

  // Power counter logic
  wire [6:0] p_inc = (power_count < 7'd64) ? power_count + 1 : 7'd64;
  wire [6:0] p_dec = power_count - 1;
  wire [6:0] pwr_next = s_chg ? p_inc : s_asc ? p_dec : 7'd0;

  FDRE #(.INIT(1'b0)) p0(.C(clk), .CE(frame_tick), .R(rst), .D(pwr_next[0]), .Q(power_count[0]));
  FDRE #(.INIT(1'b0)) p1(.C(clk), .CE(frame_tick), .R(rst), .D(pwr_next[1]), .Q(power_count[1]));
  FDRE #(.INIT(1'b0)) p2(.C(clk), .CE(frame_tick), .R(rst), .D(pwr_next[2]), .Q(power_count[2]));
  FDRE #(.INIT(1'b0)) p3(.C(clk), .CE(frame_tick), .R(rst), .D(pwr_next[3]), .Q(power_count[3]));
  FDRE #(.INIT(1'b0)) p4(.C(clk), .CE(frame_tick), .R(rst), .D(pwr_next[4]), .Q(power_count[4]));
  FDRE #(.INIT(1'b0)) p5(.C(clk), .CE(frame_tick), .R(rst), .D(pwr_next[5]), .Q(power_count[5]));
  FDRE #(.INIT(1'b0)) p6(.C(clk), .CE(frame_tick), .R(rst), .D(pwr_next[6]), .Q(power_count[6]));

  // Position logic
  wire [9:0] y_up   = player_y - 10'd2;
  wire [9:0] y_down = player_y + 10'd2;
  wire [9:0] y_fall = (player_y < 10'd456) ? y_down : 10'd456;
//  wire [9:0] y_recover = (player_y > 10'd344) ? 10'd344 : player_y;
  wire [9:0] y_next = s_asc    ? y_up     :
                    s_desc   ? y_down   :
                    s_fall   ? y_fall   :
                    s_relive ? 10'd344 :
                    s_dead   ? 10'd456   :
                               10'd344;
 
  wire [9:0] hole_end = hole_x + {3'b000, hole_w};
  wire [9:0] x_recover = (hole_end > 10'd16) ? (hole_end - 10'd16) : 10'd0;
  wire [9:0] x_next = s_relive ? x_recover : player_x;
  // Visibility logic - flash continuously in death states
  assign player_vis = (s_idle | s_chg | s_asc | s_desc | s_relive) | 
                      ((s_fall | s_dead) & flash_toggle);

  // Y-position register bits
  FDRE #(.INIT(1'b0)) y0(.C(clk), .CE(frame_tick), .R(rst), .D(y_next[0]), .Q(player_y[0]));
  FDRE #(.INIT(1'b0)) y1(.C(clk), .CE(frame_tick), .R(rst), .D(y_next[1]), .Q(player_y[1]));
  FDRE #(.INIT(1'b0)) y2(.C(clk), .CE(frame_tick), .R(rst), .D(y_next[2]), .Q(player_y[2]));
  FDRE #(.INIT(1'b0)) y3(.C(clk), .CE(frame_tick), .R(rst), .D(y_next[3]), .Q(player_y[3]));
  FDRE #(.INIT(1'b0)) y4(.C(clk), .CE(frame_tick), .R(rst), .D(y_next[4]), .Q(player_y[4]));
  FDRE #(.INIT(1'b0)) y5(.C(clk), .CE(frame_tick), .R(rst), .D(y_next[5]), .Q(player_y[5]));
  FDRE #(.INIT(1'b0)) y6(.C(clk), .CE(frame_tick), .R(rst), .D(y_next[6]), .Q(player_y[6]));
  FDRE #(.INIT(1'b0)) y7(.C(clk), .CE(frame_tick), .R(rst), .D(y_next[7]), .Q(player_y[7]));
  FDRE #(.INIT(1'b0)) y8(.C(clk), .CE(frame_tick), .R(rst), .D(y_next[8]), .Q(player_y[8]));
  FDRE #(.INIT(1'b0)) y9(.C(clk), .CE(frame_tick), .R(rst), .D(y_next[9]), .Q(player_y[9]));
  
  FDRE #(.INIT(1'b0)) x0(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[0]), .Q(player_x[0]));
  FDRE #(.INIT(1'b0)) x1(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[1]), .Q(player_x[1]));
  FDRE #(.INIT(1'b0)) x2(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[2]), .Q(player_x[2]));
  FDRE #(.INIT(1'b0)) x3(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[3]), .Q(player_x[3]));
  FDRE #(.INIT(1'b0)) x4(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[4]), .Q(player_x[4]));
  FDRE #(.INIT(1'b0)) x5(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[5]), .Q(player_x[5]));
  FDRE #(.INIT(1'b0)) x6(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[6]), .Q(player_x[6]));
  FDRE #(.INIT(1'b0)) x7(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[7]), .Q(player_x[7]));
  FDRE #(.INIT(1'b0)) x8(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[8]), .Q(player_x[8]));
  FDRE #(.INIT(1'b0)) x9(.C(clk), .CE(frame_tick), .R(rst), .D(x_next[9]), .Q(player_x[9]));
  
  assign test_led = {s_idle, s_chg,  s_asc, s_desc, s_relive, s_fall, s_dead};
endmodule
