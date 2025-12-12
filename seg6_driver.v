`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/24 13:44:23
// Design Name: 
// Module Name: seg6_driver
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


module seg6_driver(
    input clk,
    input rst,
    input [3:0] h_ten, h_one,
    input [3:0] m_ten, m_one,
    input [3:0] s_ten, s_one,
    output [7:0] seg_data,
    output [7:0] seg_com
);
    reg [2:0] s_cnt;
    reg [7:0] seg_data_r, seg_com_r;

    assign seg_data = seg_data_r;
    assign seg_com  = seg_com_r;

    wire [7:0] seg_h_ten, seg_h_one;
    wire [7:0] seg_m_ten, seg_m_one;
    wire [7:0] seg_s_ten, seg_s_one;

    seg_decoder U0(h_ten, seg_h_ten);
    seg_decoder U1(h_one, seg_h_one);
    seg_decoder U2(m_ten, seg_m_ten);
    seg_decoder U3(m_one, seg_m_one);
    seg_decoder U4(s_ten, seg_s_ten);
    seg_decoder U5(s_one, seg_s_one);

    // 시분할 카운터 (0~5)
    always @(posedge clk or posedge rst)
        if (rst) s_cnt <= 3'd0;
        else     s_cnt <= s_cnt + 3'd1;

    // 자리 선택 (Common)
    always @(posedge clk or posedge rst) begin
        if (rst) seg_com_r <= 8'b1111_1111;
        else begin
            case (s_cnt)
                3'd0: seg_com_r <= 8'b1111_0111; // 시 10
                3'd1: seg_com_r <= 8'b1111_1011; // 시 1
                3'd2: seg_com_r <= 8'b1111_1101; // 분 10
                3'd3: seg_com_r <= 8'b1111_1110; // 분 1
                3'd4: seg_com_r <= 8'b1110_1111; // 초 10
                3'd5: seg_com_r <= 8'b1101_1111; // 초 1
                default: seg_com_r <= 8'b1111_1111;
            endcase
        end
    end

    // 데이터 출력 (Segment Data + DP)
    always @(posedge clk or posedge rst) begin
        if (rst) seg_data_r <= 8'b0000_0000;
        else begin
            case (s_cnt)
                3'd0: seg_data_r <= seg_h_ten;
                
                // [수정] HH.MM.SS 표현을 위해 시(1의자리) 뒤에 점 추가 (Bit 0 = 1)
                3'd1: seg_data_r <= seg_h_one | 8'b0000_0001; 
                
                3'd2: seg_data_r <= seg_m_ten;
                
                // [수정] HH.MM.SS 표현을 위해 분(1의자리) 뒤에 점 추가 (Bit 0 = 1)
                3'd3: seg_data_r <= seg_m_one | 8'b0000_0001;
                
                3'd4: seg_data_r <= seg_s_ten;
                3'd5: seg_data_r <= seg_s_one;
                default: seg_data_r <= 8'b0000_0000;
            endcase
        end
    end
endmodule