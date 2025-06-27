`timescale 1ns / 1ps

module top (
    input  wire        clkin,    // 100 MHz board clock
    input  wire        btnR,     // global reset, active high
    input  wire        btnU,
    input  wire        btnC,
    input  wire        btnL,
    input  wire [15:0] sw, 
    output wire        Hsync,
    output wire        Vsync,
    output wire [3:0]  vgaRed,
    output wire [3:0]  vgaGreen,
    output wire [3:0]  vgaBlue,
    output wire [3:0]  an,
    output wire [6:0]  seg,
    output wire [15:0] led
);

    // 1) Generate 25 MHz pixel clock + digit-select (digsel) for 7-seg
    wire clk, digsel;
    labVGA_clks clkgen (
        .clkin  (clkin),
        .greset (btnR),
        .clk    (clk),
        .digsel (digsel)    
    );
    
    wire [3:0] lives;
    wire load_lives = btnL;  // Load lives when btnL pressed
    
    
    wire coin_pause;
    // 2) VGA timing: Hsync, Vsync, active-video flag, pixel coords
    wire video_on;
    wire [9:0]  hcount, vcount;
    vga_sync sync0 (
        .clk      (clk),
        .reset    (btnR),
        .Hsync    (Hsync),
        .Vsync    (Vsync),
        .video_on (video_on),
        .hcount   (hcount),
        .vcount   (vcount)
    );
    wire c_pressed;
    wire c_pressed_next = c_pressed | btnC;
    FDRE #(.INIT(1'b0)) ff_c_press (.C(clk), .CE(1'b1), .D(c_pressed_next), .Q(c_pressed), .R(btnR));
    
    wire frame_tick = (video_on && hcount==0 && vcount==0);
    wire [9:0] player_y;
    wire [9:0] player_x;
    wire [6:0] power_count;
    wire [9:0] x;
    wire [6:0] w; 
    wire [9:0] ballx;
    wire [9:0] bally;
    wire dead;
    wire vis;
    wire active_game = c_pressed & ~dead;
    wire player_reset = btnR | (dead & (|lives));
    wire fake_death;
      // --- 1) Register the previous fake_death to detect a rising edge ---
  wire prev_fake_death, fake_death_event;
  FDRE #(.INIT(1'b0)) fake_death_ff (
    .C   (clk),
    .CE  (1'b1),
    .D   (fake_death),
    .Q   (prev_fake_death),
    .R   (btnR)
  );
  assign fake_death_event = fake_death & ~prev_fake_death;

    wire have_life = lives[0] | lives[1] | lives[2] | lives[3];
    wire       life_ce     = load_lives | (fake_death_event & have_life);
    wire [3:0] lives_dec   = lives - 4'd1;
   
    wire [3:0] lives_next  = load_lives ? sw[3:0] 
                              : (fake_death_event & have_life)  ? lives_dec : lives;
    

      FDRE #(.INIT(1'b0)) life0 (.C(clk), .CE(life_ce), .D(lives_next[0]), .Q(lives[0]), .R(btnR));
      FDRE #(.INIT(1'b0)) life1 (.C(clk), .CE(life_ce), .D(lives_next[1]), .Q(lives[1]), .R(btnR));
      FDRE #(.INIT(1'b0)) life2 (.C(clk), .CE(life_ce), .D(lives_next[2]), .Q(lives[2]), .R(btnR));
      FDRE #(.INIT(1'b0)) life3 (.C(clk), .CE(life_ce), .D(lives_next[3]), .Q(lives[3]), .R(btnR));
      player_movement pcm (
        .clk         (clk),
        .rst         (btnR),
        .btnU        (btnU),
        .frame_tick  (frame_tick),
        .hole_x      (x),
        .hole_w      (w),
        .ignore_hole (sw[15]),
        .lives (lives != 4'b0),
        .player_y    (player_y),
        .player_x    (player_x),
        .power_count (power_count),
        .player_died (dead),
        .player_vis (vis),
        .over_hole_math(fake_death),
        .test_led(led)
    );

    hole_gen hg (
        .clk         (clk),
        .rst         (btnR),
        .frame_tick  (frame_tick & c_pressed & ~dead),
        .hole_x      (x),
        .hole_w      (w)
    );
    
    wire ball_vis, ball_flash;
    ball_gen bg (
        .clk         (clk),
        .rst         (btnR),
        .frame_tick  (frame_tick & c_pressed & ~dead & ~coin_pause),
        .ball_x      (ballx),
        .ball_y      (bally)
    );
    
    
    wire [3:0]  score;
    wire tag;
    ball_controller bc (
        .clk         (clk),
        .rst         (btnR),
        .frame_tick  (frame_tick),
        .player_x    (10'd100),
        .player_y    (player_y),
        .ball_x      (ballx),
        .ball_y      (bally),
        .ball_vis    (ball_vis),
        .ball_flash  (ball_flash),
        .score       (score),
        .ball_pause (coin_pause),
        .tagged (tag)
    );
    // 3) Pixel generator: border + platform only for Phase 2
    pixel_display display (
        .clk         (clk),
        .frame_tick  (frame_tick),
        .video_on    (video_on),
        .hcount      (hcount),
        .vcount      (vcount),
        .player_y    (player_y),
        .player_x    (player_x),
        .player_vis  (vis),
        .dead (dead),
        .tagged (tag),
        .power_count (power_count),
        .hole_x(x),
        .hole_w(w),
        .ball_x(ballx),
        .ball_y(bally),
        .ball_vis    (ball_vis),
        .ball_flash  (ball_flash),
        .vgaRed      (vgaRed),
        .vgaGreen    (vgaGreen),
        .vgaBlue     (vgaBlue)
    );
    
      // 9) Build a 16-bit BCD vector: [blank][blank][tens][ones]
    wire [3:0] score_tens = (score >= 4'd10) ? 4'd1 : 4'd0;
    wire [3:0] score_ones = (score >= 4'd10) ? (score - 4'd10) : score;
    wire [3:0] lives_tens = (lives >= 4'd10) ? 4'd1 : 4'd0;
    wire [3:0] lives_ones = (lives >= 4'd10) ? (lives - 4'd10) : lives;
    wire [15:0] disp_in = {lives_tens, lives_ones, score_tens, score_ones};        
    // 9a) Ring counter: rotate a 4-bit one-hot at clk_i ? digsel_4bit
    wire [3:0] digsel_4bit;
    ring_counter rc (
      .clk_i    (clk),
      .advance_i(digsel),    // step every clk_i cycle (fast scan)
      .reset_i  (btnR),
      .data_o   (digsel_4bit)
    );
    
    // 9b) Selector picks the nibble for the active digit
    wire [3:0] digit;
    selector sel (
      .sel_i(digsel_4bit),
      .n_i  (disp_in),
      .h_o  (digit)
    );
    
    // 9c) Hex ? segments  
    wire [6:0] seg_out;
    hex7seg h7 (
      .n  (digit),
      .seg(seg_out)
    );
    
    assign seg = seg_out;
    assign an  = ~(digsel_4bit & 4'b1111);
    

endmodule

