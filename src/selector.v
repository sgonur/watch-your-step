`timescale 1ns / 1ps

module selector(
    input [3:0] sel_i,
    input [15:0] n_i,
    output [3:0] h_o
    );
    
    wire [3:0] h0, h1, h2, h3;
    
    // Pre extract each 4 bit group
    assign h0 = n_i[3:0];
    assign h1 = n_i[7:4];
    assign h2 = n_i[11:8];
    assign h3 = n_i[15:12];
    
    // build output based on sel_i
    assign h_o[0] = (sel_i[0] & h0[0]) |
                    (sel_i[1] & h1[0]) |
                    (sel_i[2] & h2[0]) |
                    (sel_i[3] & h3[0]);

    assign h_o[1] = (sel_i[0] & h0[1]) |
                    (sel_i[1] & h1[1]) |
                    (sel_i[2] & h2[1]) |
                    (sel_i[3] & h3[1]);

    assign h_o[2] = (sel_i[0] & h0[2]) |
                    (sel_i[1] & h1[2]) |
                    (sel_i[2] & h2[2]) |
                    (sel_i[3] & h3[2]);

    assign h_o[3] = (sel_i[0] & h0[3]) |
                    (sel_i[1] & h1[3]) |
                    (sel_i[2] & h2[3]) |
                    (sel_i[3] & h3[3]);
    
endmodule
