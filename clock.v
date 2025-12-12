`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/24 13:27:25
// Design Name: 
// Module Name: clock
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

module world_clock_top(
    input clk,
    input rst,

    // 기존 버튼 (1~7)
    input adj_min_btn,      // BTN 2 (시계: 분 조정 / 알람: 분 조정)
    input adj_hour_btn,     // BTN 1 (시계: 시 조정 / 알람: 시 조정)
    input mode_toggle_btn,  // BTN 3 (12/24H 토글)
    input paris_btn,        // BTN 5 (물리적 5번 -> Paris / Alarm 2)
    input ny_btn,           // BTN 4 (물리적 4번 -> NY / Alarm 1)
    input uk_btn,           // BTN 6 (UK / Alarm 3)
    input korea_btn,        // BTN 7 (Korea)

    // 추가된 버튼 (8~10) - 타이머용 (*, 0, #)
    input btn_tm_min,       // Key * (타이머 분 / 알람 끄기)
    input btn_tm_sec,       // Key 0 (타이머 초 / 알람 끄기)
    input btn_tm_start,     // Key # (타이머 시작 / 알람 끄기)
    
    // 알람 리셋용 버튼 (Key 8)
    input btn_num_8,

    // 스위치
    input sw_timer,         // SW3 (Timer Mode)
    input sw_alarm,         // SW4 (Alarm Set Mode)

    // 출력
    output [7:0] seg_data,
    output [7:0] seg_com,
    output LCD_E,
    output LCD_RS,
    output LCD_RW,
    output [7:0] LCD_DATA,
    output reg piezo,       // 피에조 출력
    
    // LED 출력
    output wire tm_led_r, tm_led_g, tm_led_b, // 타이머 3색 LED
    output wire alm_led1, alm_led2, alm_led3  // 알람 1/2/3 상태 LED
);

    // ==================================================
    // 1. 버튼 입력 처리 (Oneshot) - 총 11개
    // ==================================================
    wire [10:0] btn_trig; 

    // oneshot 모듈의 입력 비트 순서가 중요합니다.
    oneshot_universal #(.WIDTH(11)) U_OS (
        .clk     (clk),
        .rst     (rst),
        .btn     ({btn_num_8, btn_tm_start, btn_tm_sec, btn_tm_min,
                    adj_min_btn, adj_hour_btn, mode_toggle_btn,
                    paris_btn,    ny_btn,       uk_btn, korea_btn}),
        .btn_trig(btn_trig)
    );

    // --- 버튼 신호 추출 (물리적 버튼 매핑) ---
    
    // [Keypad]
    // [수정 1] Key 8번(btn_trig[10])을 기능별로 분리
    wire btn_key8_raw = btn_trig[10];

    // SW3(Timer)가 켜져 있으면 '타이머 리셋', 꺼져 있으면 '알람 리셋'
    wire btn_timer_reset_p = (sw_timer) ? btn_key8_raw : 1'b0;
    wire btn_alarm_reset_p = (sw_timer) ? 1'b0 : btn_key8_raw;
    
    wire tm_start_p = btn_trig[9]; // Key #
    wire tm_sec_p   = btn_trig[8]; // Key 0
    wire tm_min_p   = btn_trig[7]; // Key *
    
    // 알람 시계(Alarm Clock)가 울릴 때 끄는 신호 (셋 중 아무거나)
    wire alarm_stop_signal = tm_start_p | tm_sec_p | tm_min_p;

    // [Time Control]
    wire adj_min_raw_p  = btn_trig[6]; // BTN 2
    wire adj_hour_raw_p = btn_trig[5]; // BTN 1
    wire mode_toggle_p  = btn_trig[4]; // BTN 3
    
    // [City Control]
    // oneshot 입력 순서: {..., paris_btn, ny_btn, ...}
    // btn_trig[3] = paris_btn (물리적 5번)
    // btn_trig[2] = ny_btn    (물리적 4번)
    
    wire btn_paris_raw = btn_trig[3]; // BTN 5
    wire btn_ny_raw    = btn_trig[2]; // BTN 4
    wire btn_uk_raw    = btn_trig[1]; // BTN 6
    wire btn_korea_raw = btn_trig[0]; // BTN 7

    
    // ==================================================
    // [버튼 MUX 로직] SW4 상태에 따라 기능 분배
    // ==================================================

    // 1. 시간 조절 (BTN 1, 2)
    // SW4 ON -> 알람 시간 조절, SW4 OFF -> 현재 시간 조절
    wire time_adj_min_p   = (sw_alarm) ? 1'b0 : adj_min_raw_p;
    wire time_adj_hour_p  = (sw_alarm) ? 1'b0 : adj_hour_raw_p;
    
    wire alarm_adj_min_p  = (sw_alarm) ? adj_min_raw_p : 1'b0;
    wire alarm_adj_hour_p = (sw_alarm) ? adj_hour_raw_p : 1'b0;

    // 2. 도시 선택 vs 알람 슬롯 선택 (BTN 4, 5, 6)
    
    // 시계 모드용 (SW4 OFF): 도시 선택
    wire clk_ny_p    = (sw_alarm) ? 1'b0 : btn_ny_raw;    // BTN 4 -> NY
    wire clk_paris_p = (sw_alarm) ? 1'b0 : btn_paris_raw; // BTN 5 -> Paris
    wire clk_uk_p    = (sw_alarm) ? 1'b0 : btn_uk_raw;    // BTN 6 -> UK
    
    // 알람 모드용 (SW4 ON): 슬롯 선택
    // 4번->알람1, 5번->알람2, 6번->알람3
    wire alm_slot1_p = (sw_alarm) ? btn_ny_raw    : 1'b0; // BTN 4 -> Slot 1
    wire alm_slot2_p = (sw_alarm) ? btn_paris_raw : 1'b0; // BTN 5 -> Slot 2
    wire alm_slot3_p = (sw_alarm) ? btn_uk_raw    : 1'b0; // BTN 6 -> Slot 3


    // ==================================================
    // 2. 세계 시계 로직 
    // ==================================================
    wire [5:0] wc_sec, wc_min;
    wire [4:0] hour_kst, hour24, hour_disp;
    wire mode_12h, is_pm;
    wire [1:0] tz_sel;

    time_base U_TIME (
        .clk      (clk),
        .rst      (rst),
        .adj_min_p(time_adj_min_p),
        .adj_hour_p(time_adj_hour_p),
        .sec      (wc_sec),
        .min      (wc_min),
        .hour     (hour_kst)
    );

    tz_mode_ctrl U_MODE (
        .clk            (clk),
        .rst            (rst),
        .mode_toggle_p (mode_toggle_p),
        .paris_p        (clk_paris_p), // BTN 5
        .ny_p           (clk_ny_p),    // BTN 4
        .uk_p           (clk_uk_p),    // BTN 6
        .korea_p        (btn_korea_raw),// BTN 7
        .mode_12h       (mode_12h),
        .tz_sel         (tz_sel)
    );

    world_time_calc U_WT (
        .hour_kst(hour_kst),
        .tz_sel  (tz_sel),
        .hour24  (hour24)
    );

    hour12_24 U_HMODE (
        .hour24  (hour24),
        .mode_12h(mode_12h),
        .hour_disp(hour_disp),
        .is_pm   (is_pm)
    );

    wire [3:0] wc_h_ten, wc_h_one;
    wire [3:0] wc_m_ten, wc_m_one;
    wire [3:0] wc_s_ten, wc_s_one;

    hms_to_bcd U_BCD_WC (
        .hour_disp(hour_disp),
        .min      (wc_min),
        .sec      (wc_sec),
        .h_ten    (wc_h_ten), .h_one(wc_h_one),
        .m_ten    (wc_m_ten), .m_one(wc_m_one),
        .s_ten    (wc_s_ten), .s_one(wc_s_one)
    );
    
    // ==================================================
    // [알람 시계 모듈] - 3 Slot Multi Alarm
    // ==================================================
    wire alarm_ringing;
    wire [3:0] alm_h_ten, alm_h_one;
    wire [3:0] alm_m_ten, alm_m_one;
    wire [2:0] edit_slot; // 현재 편집 중인 슬롯 번호
    wire a1_en, a2_en, a3_en;
    
    assign alm_led1 = a1_en;
    assign alm_led2 = a2_en;
    assign alm_led3 = a3_en;

    alarm_clock U_ALARM (
        .clk(clk), .rst(rst),
        .sw_alarm(sw_alarm),
        .btn_hour_p(alarm_adj_hour_p),
        .btn_min_p(alarm_adj_min_p),
        .btn_slot1_p(alm_slot1_p), // BTN 4
        .btn_slot2_p(alm_slot2_p), // BTN 5
        .btn_slot3_p(alm_slot3_p), // BTN 6
        .btn_reset_p(btn_alarm_reset_p), // BTN 8 (Reset All - SW3 OFF일때만)
        .btn_stop_p(alarm_stop_signal),  // *,0,# (Turn Off)
        .curr_hour(hour24),              // 24시간제 비교
        .curr_min(wc_min),
        .curr_sec(wc_sec),
        .alarm_ringing(alarm_ringing),
        .edit_slot(edit_slot),
        .alm1_en(a1_en), .alm2_en(a2_en), .alm3_en(a3_en),
        .alm_h_ten(alm_h_ten), .alm_h_one(alm_h_one),
        .alm_m_ten(alm_m_ten), .alm_m_one(alm_m_one)
    );

    // ==================================================
    // 3. 타이머 로직 
    // ==================================================
    wire [5:0] tm_min_val, tm_sec_val;
    wire tm_alarm;
    wire tm_run_led;
    wire [5:0] tm_init_min_val, tm_init_sec_val; // 초기 설정 시간

    // [수정] 타이머 모드가 꺼져있더라도(SW3 OFF), 타이머 알람이 울리면 버튼 입력을 허용
    wire tm_min_in   = (sw_timer || tm_alarm) ? tm_min_p : 1'b0;
    wire tm_sec_in   = (sw_timer || tm_alarm) ? tm_sec_p : 1'b0;
    wire tm_start_in = (sw_timer || tm_alarm) ? tm_start_p : 1'b0;

    // [수정 2] 타이머 모듈 인스턴스 (btn_reset_p 추가 연결)
    timer U_TIMER (
        .clk             (clk),
        .rst             (rst),
        .btn_min_p       (tm_min_in),
        .btn_sec_p       (tm_sec_in),
        .btn_start_stop_p(tm_start_in),
        .btn_reset_p     (btn_timer_reset_p), // SW3 ON일 때 Key 8 입력
        .tm_min          (tm_min_val),
        .tm_sec          (tm_sec_val),
        .tm_run_led      (tm_run_led),
        .tm_alarm        (tm_alarm),
        .led_r           (tm_led_r),
        .led_g           (tm_led_g),
        .led_b           (tm_led_b),
        .init_min        (tm_init_min_val),
        .init_sec        (tm_init_sec_val)
    );

    // 타이머용 BCD 변환
    wire [3:0] tm_m_ten, tm_m_one;
    wire [3:0] tm_s_ten, tm_s_one;

    hms_to_bcd U_BCD_TM (
        .hour_disp(5'd0),
        .min      (tm_min_val),
        .sec      (tm_sec_val),
        .h_ten    (), .h_one(), 
        .m_ten    (tm_m_ten), .m_one(tm_m_one),
        .s_ten    (tm_s_ten), .s_one(tm_s_one)
    );

    // ==================================================
    // 4. 화면 출력 멀티플렉싱 (MUX)
    // ==================================================
    wire [3:0] d_h_ten, d_h_one;
    wire [3:0] d_m_ten, d_m_one;
    wire [3:0] d_s_ten, d_s_one;

    // 우선순위: SW3(Timer) > SW4(Alarm) > Clock
    assign d_h_ten = sw_timer ? 4'd0 : (sw_alarm ? alm_h_ten : wc_h_ten);
    assign d_h_one = sw_timer ? 4'd0 : (sw_alarm ? alm_h_one : wc_h_one);
    
    assign d_m_ten = sw_timer ? tm_m_ten : (sw_alarm ? alm_m_ten : wc_m_ten);
    assign d_m_one = sw_timer ? tm_m_one : (sw_alarm ? alm_m_one : wc_m_one);
    
    assign d_s_ten = sw_timer ? tm_s_ten : (sw_alarm ? 4'd0 : wc_s_ten); 
    assign d_s_one = sw_timer ? tm_s_one : (sw_alarm ? 4'd0 : wc_s_one);
    
    // DP(소수점) 기능이 추가된 SegDriver
    seg6_driver U_SEG (
        .clk     (clk),
        .rst     (rst),
        .h_ten   (d_h_ten), .h_one(d_h_one),
        .m_ten   (d_m_ten), .m_one(d_m_one),
        .s_ten   (d_s_ten), .s_one(d_s_one),
        .seg_data(seg_data),
        .seg_com (seg_com)
    );

    // ==================================================
    // 5. 피에조 제어 (정각 타종 / 전화벨 / 비프음 분리)
    // ==================================================

    // [정각 알림용 레지스터]
    reg hourly_active;      
    reg [3:0] hourly_cnt;   
    reg [3:0] hourly_target;
    reg [9:0] hourly_timer; 
    reg hourly_out;         

    // 초(sec) 변화 감지 (정각 트리거용)
    reg [5:0] wc_sec_prev;
    always @(posedge clk) wc_sec_prev <= wc_sec;
    wire sec_tick = (wc_sec != wc_sec_prev); // 1초에 한 번 High

    // [전화벨 효과용 레지스터 (알람시계용)]
    reg [5:0] trill_cnt; 
    reg tone_sel;        
    reg freq_div;        
    
    // [타이머용 삐삐 카운터]
    reg [9:0] beep_cnt;  

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            piezo <= 0;
            trill_cnt <= 0; tone_sel <= 0; freq_div <= 0;
            beep_cnt <= 0;
            hourly_active <= 0; hourly_cnt <= 0; hourly_target <= 0; hourly_timer <= 0; hourly_out <= 0;
        end else begin
            
            // ----------------------------------------------------
            // A. 정각 알림 로직 (시간 수만큼 띠- 띠- 띠-)
            // ----------------------------------------------------
            if (sec_tick && (wc_min == 0) && (wc_sec == 0)) begin
                hourly_active <= 1;
                hourly_cnt <= 0;
                hourly_timer <= 0;
                hourly_out <= 1; // 띠! 시작
                
                // 타겟 횟수 계산 (12시간제 변환)
                if (hour_kst == 0) hourly_target <= 4'd12;               // 0시 -> 12번
                else if (hour_kst <= 12) hourly_target <= hour_kst[3:0]; // 1~12시
                else hourly_target <= hour_kst - 5'd12;                  // 13~23시 -> 1~11번
            end

            if (hourly_active) begin
                if (hourly_timer >= 499) begin
                    hourly_timer <= 0;
                    if (hourly_cnt + 1 >= hourly_target) begin
                        hourly_active <= 0; // 목표 횟수 채우면 종료
                        hourly_out <= 0;
                    end else begin
                        hourly_cnt <= hourly_cnt + 1;
                        hourly_out <= 1; // 다음 띠! 시작
                    end
                end else begin
                    hourly_timer <= hourly_timer + 1;
                    if (hourly_timer < 200) hourly_out <= 1; // 200ms ON
                    else hourly_out <= 0;                    // 300ms OFF
                end
            end else begin
                hourly_out <= 0;
            end

            // ----------------------------------------------------
            // B. 카운터 업데이트
            // ----------------------------------------------------
            // 알람시계(전화벨)용 (50ms 주기)
            if (trill_cnt >= 49) begin
                trill_cnt <= 0; tone_sel <= ~tone_sel;
            end else trill_cnt <= trill_cnt + 1;
            
            freq_div <= ~freq_div; // 250Hz 생성을 위한 2분주

            // 타이머용 (0.5초 주기)
            if (beep_cnt >= 999) beep_cnt <= 0;
            else beep_cnt <= beep_cnt + 1;

            // ----------------------------------------------------
            // C. Piezo 출력 MUX (우선순위: 알람시계 > 타이머 > 정각)
            // ----------------------------------------------------
            if (alarm_ringing) begin
                // [TYPE 1] 알람 시계: 전화벨 (Trill)
                if (tone_sel == 0) piezo <= ~piezo; // 500Hz
                else if (freq_div) piezo <= ~piezo; // 250Hz
            end
            else if (tm_alarm) begin
                // [TYPE 2] 타이머: 단순 삑-삑 (0.5초 간격)
                if (beep_cnt < 500) piezo <= ~piezo;
                else piezo <= 0;
            end
            else if (hourly_active && hourly_out) begin
                // [TYPE 3] 정각 알림: 짧은 띠! (시간 수만큼 반복)
                piezo <= ~piezo; // 500Hz 톤
            end
            else begin
                piezo <= 0;
            end
        end
    end

    // ==================================================
    // 6. LCD 모듈 인스턴스 (최종 연결)
    // ==================================================
    lcd_worldclock U_LCD (
        .clk(clk), .rst(rst),
        .mode_12h(mode_12h), .tz_sel(tz_sel), .is_pm(is_pm),
        .sw_timer(sw_timer),
        .tm_alarm(tm_alarm),
        .sw_alarm(sw_alarm),
        .alarm_ringing(alarm_ringing),
        
        .edit_slot(edit_slot),
        .alm1_en(a1_en), .alm2_en(a2_en), .alm3_en(a3_en),
        
        .tm_running(tm_run_led), 
        .tm_init_min(tm_init_min_val),
        .tm_init_sec(tm_init_sec_val),
        
        .LCD_E(LCD_E), .LCD_RS(LCD_RS), .LCD_RW(LCD_RW), .LCD_DATA(LCD_DATA)
    );
endmodule