`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/24 13:46:42
// Design Name: 
// Module Name: hms_to_bcd
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module hms_to_bcd(
    input  [4:0] hour_disp,      // 0~23 or 1~12
    input  [5:0] min,
    input  [5:0] sec,
    output [3:0] h_ten, h_one,
    output [3:0] m_ten, m_one,
    output [3:0] s_ten, s_one
);
    reg [3:0] h_ten_r, h_one_r;
    reg [3:0] m_ten_r, m_one_r;
    reg [3:0] s_ten_r, s_one_r;

    assign h_ten = h_ten_r;
    assign h_one = h_one_r;
    assign m_ten = m_ten_r;
    assign m_one = m_one_r;
    assign s_ten = s_ten_r;
    assign s_one = s_one_r;

    always @(*) begin
        h_ten_r = hour_disp / 10;
        h_one_r = hour_disp % 10;

        m_ten_r = min / 10;
        m_one_r = min % 10;

        s_ten_r = sec / 10;
        s_one_r = sec % 10;
    end
endmodule 
