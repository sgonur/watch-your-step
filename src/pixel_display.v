`timescale 1ns / 1ps

// Phase 4: VGA pixel rendering with border, platform, player, and power bar
module pixel_display (
    input  wire clk,
    input  wire frame_tick,
    input  wire        video_on,     // active 640×480 region
    input  wire [9:0]  hcount,       // horizontal pixel coordinate (0..799)
    input  wire [9:0]  vcount,       // vertical pixel coordinate (0..524)
    input  wire [9:0]  player_y,     // top-edge of 16×16 player sprite
    input  wire [9:0]  player_x,
    input  wire        player_vis,
    input  wire        dead,
    input  wire        tagged,
    input  wire [6:0]  power_count,  // 0..64 charge level for power bar
    input  wire [9:0]  hole_x,
    input  wire [6:0]  hole_w,
    input  wire [9:0]  ball_x,
    input  wire [9:0]  ball_y,
    input  wire        ball_vis,    // ball visible flag
    input  wire        ball_flash,  // ball flashing flag
    output wire [3:0]  vgaRed,       // VGA red channel (4 bits)
    output wire [3:0]  vgaGreen,     // VGA green channel (4 bits)
    output wire [3:0]  vgaBlue       // VGA blue channel (4 bits)
);
    
    wire [7:0] rnd;
    lfsr rng (
        .clk_i (clk),
        .ce_i  (frame_tick),
        .q_o   (rnd)
    );
    
  // 1) 8-pixel-wide red border on all sides
  wire border_on = video_on &&
      (hcount <  10'd8   || hcount >= 10'd632 ||
       vcount <  10'd8   || vcount >= 10'd472);

  // 2) 20-pixel-thick green platform at y = 360..379, x = 8..631
    wire platform_band = video_on &&
        (hcount >= 10'd8   && hcount <  10'd632 &&
         vcount >= 10'd360 && vcount <  10'd380);

  // 2) compute 10-bit right edge so it never wraps
    wire [9:0] hole_r = hole_x + hole_w;
    
    // 3) carve out the hole    
    wire in_hole = platform_band &&
                   ((hcount >= hole_x) && (hcount <  hole_r) || ((hcount < hole_r) && (10'd640 < hole_x)));



  // final platform is band minus hole
  wire platform_on = platform_band && !in_hole;
  
  wire pit_on = video_on &&
              (hcount >= 10'd8   && hcount <  10'd632) &&
              (vcount >= 10'd380 && vcount <  10'd472) &&
              !((hcount >= hole_x) && (hcount <  hole_r) || ((hcount < hole_r) && (10'd640 < hole_x)));
  
  // 3) 16×16 player sprite at fixed X=100, variable Y = player_y
  wire player_on = video_on && player_vis &&
      ((hcount >= player_x + 10'd100)  && (hcount <  player_x + 10'd116)) &&
      (vcount >= player_y           && vcount <  player_y + 10'd16);

  // 4) 16-pixel wide vertical power bar at x=32..47, height = power_count
  wire bar_on = video_on &&
      (hcount >= 10'd32 && hcount < 10'd48) &&
      (vcount >= 10'd96 - power_count && vcount < 10'd96);
  
  wire ball_on = video_on && ball_vis && ~dead &&
      (hcount >= ball_x && hcount < ball_x + 10'd8) &&
      (vcount >= ball_y && vcount < ball_y + 10'd8);
      
  wire [3:0] rand_red   = {rnd[7:5], 1'b1};   // Values: 8-15 (bright)
  wire [3:0] rand_green = {rnd[4:2], 1'b1};   // Values: 8-15 (bright)
  wire [3:0] rand_blue  = {rnd[1:0], 2'b11};  // Values: 3,7,11,15
  // RED channel
  assign vgaRed =
      border_on    ? 4'hF :
      player_on    ? (ball_flash ? rand_red : 4'hF) :
      //player_on && tagged ? rand_red :
      bar_on       ? 4'h0 :
      ball_on      ? 4'hF :
      platform_on  ? 4'h0 :
      pit_on       ? 4'h8 :  // grey: red=0.5
                     4'h0;   // black background

  // GREEN channel
  assign vgaGreen =
      border_on    ? 4'h0 :
      player_on    ? (ball_flash ? rand_green : 4'h8) :  // orange player
//      player_on && tagged ? rand_green :
      bar_on       ? 4'hF :
      ball_on      ? 4'hF :
      platform_on  ? 4'hF :
      pit_on       ? 4'h8 :  // grey: green=0.5
                     4'h0;

  // BLUE channel
  assign vgaBlue =
      border_on    ? 4'h0 :
      player_on    ? (ball_flash ? rand_blue : 4'h0):
//      player_on && tagged ? rand_blue :
      bar_on       ? 4'h0 :
      platform_on  ? 4'h0 :
      pit_on       ? 4'h8 :  // grey: blue=0.5
                     4'h0;

endmodule
