`timescale 1ns / 1ps

module vga_sync(
    input wire clk,
    input wire reset,
    output wire Hsync,
    output wire Vsync,
    output wire video_on,
    output wire [9:0] hcount,
    output wire [9:0] vcount
    );
    
        wire [9:0] H_Visible = 640;
        wire [9:0] H_Front = 16;
        wire [9:0] H_Sync = 96;
        wire [9:0] H_Back = 48;
        wire [9:0] H_Total = 800;
        
        wire [9:0] V_Visible = 480;
        wire [9:0] V_Front = 10;
        wire [9:0] V_Sync = 2;
        wire [9:0] V_Back = 33;
        wire [9:0] V_Total = 525;
        
        // h_count stuff
        wire [9:0] HCount_Next;
        wire HCount_Max = (hcount == 799);
        assign HCount_Next = HCount_Max ? 10'd0 : hcount + 1;
        
        FDRE h_ff0 (.C(clk), .CE(1'b1), .R(reset), .D(HCount_Next[0]), .Q(hcount[0]));
        FDRE h_ff1 (.C(clk), .CE(1'b1), .R(reset), .D(HCount_Next[1]), .Q(hcount[1]));
        FDRE h_ff2 (.C(clk), .CE(1'b1), .R(reset), .D(HCount_Next[2]), .Q(hcount[2]));
        FDRE h_ff3 (.C(clk), .CE(1'b1), .R(reset), .D(HCount_Next[3]), .Q(hcount[3]));
        FDRE h_ff4 (.C(clk), .CE(1'b1), .R(reset), .D(HCount_Next[4]), .Q(hcount[4]));
        FDRE h_ff5 (.C(clk), .CE(1'b1), .R(reset), .D(HCount_Next[5]), .Q(hcount[5]));
        FDRE h_ff6 (.C(clk), .CE(1'b1), .R(reset), .D(HCount_Next[6]), .Q(hcount[6]));
        FDRE h_ff7 (.C(clk), .CE(1'b1), .R(reset), .D(HCount_Next[7]), .Q(hcount[7]));
        FDRE h_ff8 (.C(clk), .CE(1'b1), .R(reset), .D(HCount_Next[8]), .Q(hcount[8]));
        FDRE h_ff9 (.C(clk), .CE(1'b1), .R(reset), .D(HCount_Next[9]), .Q(hcount[9]));
    
    
        // v_count stuff
        wire [9:0] VCount_Next;
        wire VCount_Max = (vcount == 524);
        wire vcount_en = HCount_Max;
        assign VCount_Next = VCount_Max ? 10'd0 : vcount + 1;
        
        FDRE v_ff0 (.C(clk), .CE(vcount_en), .R(reset), .D(VCount_Next[0]), .Q(vcount[0]));
        FDRE v_ff1 (.C(clk), .CE(vcount_en), .R(reset), .D(VCount_Next[1]), .Q(vcount[1]));
        FDRE v_ff2 (.C(clk), .CE(vcount_en), .R(reset), .D(VCount_Next[2]), .Q(vcount[2]));
        FDRE v_ff3 (.C(clk), .CE(vcount_en), .R(reset), .D(VCount_Next[3]), .Q(vcount[3]));
        FDRE v_ff4 (.C(clk), .CE(vcount_en), .R(reset), .D(VCount_Next[4]), .Q(vcount[4]));
        FDRE v_ff5 (.C(clk), .CE(vcount_en), .R(reset), .D(VCount_Next[5]), .Q(vcount[5]));
        FDRE v_ff6 (.C(clk), .CE(vcount_en), .R(reset), .D(VCount_Next[6]), .Q(vcount[6]));
        FDRE v_ff7 (.C(clk), .CE(vcount_en), .R(reset), .D(VCount_Next[7]), .Q(vcount[7]));
        FDRE v_ff8 (.C(clk), .CE(vcount_en), .R(reset), .D(VCount_Next[8]), .Q(vcount[8]));
        FDRE v_ff9 (.C(clk), .CE(vcount_en), .R(reset), .D(VCount_Next[9]), .Q(vcount[9]));
        
        wire Hsync1, Vsync1;
        assign Hsync1 = ~((hcount >= 655) && (hcount < 751));
        assign Vsync1 = ~((vcount >= 489) && (vcount < 491));
        
        FDRE #(.INIT (1'b1)) hsyncflop (.C(clk), .CE(1'b1), .R(reset), .D(Hsync1), .Q(Hsync));
        FDRE #(.INIT (1'b1)) vsyncflop (.C(clk), .CE(1'b1), .R(reset), .D(Vsync1), .Q(Vsync));

        assign video_on = (hcount < 640) && (vcount < 480);
endmodule