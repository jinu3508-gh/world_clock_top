`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/01 14:49:04
// Design Name: 
// Module Name: alarm_clock
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


module alarm_clock(
    input clk, rst,
    input sw_alarm,              // SW4
    input btn_hour_p,            // 시 조절 (BTN 1)
    input btn_min_p,             // 분 조절 (BTN 2)
    input btn_slot1_p,           // 알람 1 (BTN 4)
    input btn_slot2_p,           // 알람 2 (BTN 5)
    input btn_slot3_p,           // 알람 3 (BTN 6)
    input btn_reset_p,           // 초기화 (BTN 8)
    input btn_stop_p,            // 알람 끄기 (*, 0, #)
    input [4:0] curr_hour,       
    input [5:0] curr_min,        
    input [5:0] curr_sec,        
    
    output reg alarm_ringing,    // 알람 울림 상태
    output reg [2:0] edit_slot,  // 현재 편집 상태
    
    output reg alm1_en, alm2_en, alm3_en, // LED 출력
    output [3:0] alm_h_ten, alm_h_one,
    output [3:0] alm_m_ten, alm_m_one
);

    reg [4:0] h1, h2, h3;
    reg [5:0] m1, m2, m3;
    
    reg [4:0] disp_h;
    reg [5:0] disp_m;
    reg [10:0] delay_cnt; 
    // 어떤 알람이 울리고 있는지 기억하는 레지스터 (Bit 0: Alm1, Bit 1: Alm2, Bit 2: Alm3)
    reg [2:0] ring_src; 

    hms_to_bcd U_ALM_BCD (
        .hour_disp(disp_h), .min(disp_m), .sec(6'd0),
        .h_ten(alm_h_ten), .h_one(alm_h_one),
        .m_ten(alm_m_ten), .m_one(alm_m_one),
        .s_ten(), .s_one() 
    );

    // 디스플레이 데이터 MUX
    always @(*) begin
        case (edit_slot)
            3'd1, 3'd4: begin disp_h = h1; disp_m = m1; end 
            3'd2, 3'd5: begin disp_h = h2; disp_m = m2; end 
            3'd3, 3'd6: begin disp_h = h3; disp_m = m3; end 
            default:    begin disp_h = 5'd0; disp_m = 6'd0; end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            h1 <= 0; m1 <= 0; alm1_en <= 0;
            h2 <= 0; m2 <= 0; alm2_en <= 0;
            h3 <= 0; m3 <= 0; alm3_en <= 0;
            edit_slot <= 0;
            alarm_ringing <= 0;
            delay_cnt <= 0;
            ring_src <= 0;
        end else begin
            
            // ------------------------------------
            // 1. 슬롯 제어 로직 (SW4 ON)
            // ------------------------------------
            if (sw_alarm) begin
                if (btn_reset_p) begin
                    // 전체 초기화
                    h1 <= 0; m1 <= 0; alm1_en <= 0;
                    h2 <= 0; m2 <= 0; alm2_en <= 0;
                    h3 <= 0; m3 <= 0; alm3_en <= 0;
                    edit_slot <= 0;
                    alarm_ringing <= 0;
                    ring_src <= 0;
                end
                else begin
                    case (edit_slot)
                        3'd0: begin
                            if (btn_slot1_p) begin edit_slot <= 3'd1; alm1_en <= 0; end
                            else if (btn_slot2_p) begin edit_slot <= 3'd2; alm2_en <= 0; end
                            else if (btn_slot3_p) begin edit_slot <= 3'd3; alm3_en <= 0; end
                        end

                        3'd1: begin // Alarm 1 Setting
                            if (btn_slot1_p) begin 
                                alm1_en <= 1; edit_slot <= 3'd4; delay_cnt <= 0; 
                            end else if (btn_slot2_p) begin 
                                edit_slot <= 3'd2; alm2_en <= 0;
                            end else if (btn_slot3_p) begin 
                                edit_slot <= 3'd3; alm3_en <= 0;
                            end
                            if (btn_hour_p) h1 <= (h1>=23)? 0 : h1+1;
                            if (btn_min_p)  m1 <= (m1>=59)? 0 : m1+1;
                        end
                        
                        3'd2: begin // Alarm 2 Setting
                            if (btn_slot2_p) begin 
                                alm2_en <= 1; edit_slot <= 3'd5; delay_cnt <= 0;
                            end else if (btn_slot1_p) begin 
                                edit_slot <= 3'd1; alm1_en <= 0;
                            end else if (btn_slot3_p) begin 
                                edit_slot <= 3'd3; alm3_en <= 0;
                            end
                            if (btn_hour_p) h2 <= (h2>=23)? 0 : h2+1;
                            if (btn_min_p)  m2 <= (m2>=59)? 0 : m2+1;
                        end

                        3'd3: begin // Alarm 3 Setting
                            if (btn_slot3_p) begin 
                                alm3_en <= 1; edit_slot <= 3'd6; delay_cnt <= 0;
                            end else if (btn_slot1_p) begin 
                                edit_slot <= 3'd1; alm1_en <= 0;
                            end else if (btn_slot2_p) begin 
                                edit_slot <= 3'd2; alm2_en <= 0;
                            end
                            if (btn_hour_p) h3 <= (h3>=23)? 0 : h3+1;
                            if (btn_min_p)  m3 <= (m3>=59)? 0 : m3+1;
                        end

                        3'd4, 3'd5, 3'd6: begin // Set! Display
                            if (delay_cnt >= 2000) begin
                                edit_slot <= 3'd0; 
                                delay_cnt <= 0;
                            end else begin
                                delay_cnt <= delay_cnt + 1;
                            end
                            if (btn_slot1_p) begin edit_slot <= 3'd1; alm1_en <= 0; end
                            else if (btn_slot2_p) begin edit_slot <= 3'd2; alm2_en <= 0; end
                            else if (btn_slot3_p) begin edit_slot <= 3'd3; alm3_en <= 0; end
                        end
                    endcase
                end
            end 

            // ------------------------------------
            // 2. 알람 울림 체크 (Trigger)
            // ------------------------------------
            if (!alarm_ringing) begin
                if (curr_sec == 0) begin
                    if (alm1_en && (curr_hour == h1) && (curr_min == m1)) begin
                        alarm_ringing <= 1'b1;
                        ring_src <= 3'b001; // 1번 알람이 울림
                    end
                    else if (alm2_en && (curr_hour == h2) && (curr_min == m2)) begin
                        alarm_ringing <= 1'b1;
                        ring_src <= 3'b010; // 2번 알람이 울림
                    end
                    else if (alm3_en && (curr_hour == h3) && (curr_min == m3)) begin
                        alarm_ringing <= 1'b1;
                        ring_src <= 3'b100; // 3번 알람이 울림
                    end
                end
            end

            // ------------------------------------
            // 3. 알람 끄기 및 초기화 (Stop & Reset Specific Alarm)
            // ------------------------------------
            if (alarm_ringing) begin
                // 끄기 버튼(*, 0, #)을 누르면?
                if (btn_stop_p) begin
                    alarm_ringing <= 1'b0; // 소리 멈춤
                    
                    // 울리고 있던 알람만 골라서 초기화(Reset & Disable)
                    if (ring_src[0]) begin // Alarm 1이었으면
                        alm1_en <= 0; h1 <= 0; m1 <= 0;
                    end
                    if (ring_src[1]) begin // Alarm 2였으면
                        alm2_en <= 0; h2 <= 0; m2 <= 0;
                    end
                    if (ring_src[2]) begin // Alarm 3였으면
                        alm3_en <= 0; h3 <= 0; m3 <= 0;
                    end
                    
                    ring_src <= 0; // 기록 초기화
                end
            end
        end
    end
endmodule
