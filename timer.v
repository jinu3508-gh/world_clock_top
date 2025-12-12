`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/24 15:05:07
// Design Name: 
// Module Name: timer
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


module timer(
    input clk, rst,
    input btn_min_p, btn_sec_p, btn_start_stop_p,
    input btn_reset_p,
    output [5:0] tm_min, tm_sec,
    output reg tm_run_led,
    output reg tm_alarm,
    output reg led_r, led_g, led_b,
    
    output reg [5:0] init_min,
    output reg [5:0] init_sec
);

    localparam S_STOP  = 2'd0;
    localparam S_RUN   = 2'd1;
    localparam S_ALARM = 2'd2;

    reg [1:0] state;
    reg [9:0] tick_cnt;
    reg [5:0] curr_min, curr_sec;

    reg [11:0] total_sec_store; 
    wire [11:0] current_sec_val; 
    
    reg [3:0] pwm_cnt;      
    reg [9:0] blink_cnt;   

    assign tm_min = curr_min;
    assign tm_sec = curr_sec;
    assign current_sec_val = (curr_min * 6'd60) + curr_sec;

    // 카운터 동작 (PWM 등)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pwm_cnt    <= 4'd0;
            blink_cnt <= 10'd0;
        end else begin
            pwm_cnt    <= pwm_cnt + 4'd1;
            blink_cnt <= blink_cnt + 10'd1;
        end
    end

    // LED 로직
    always @(*) begin
        if (state == S_RUN) begin
            if (current_sec_val * 12'd5 <= total_sec_store) begin
                led_r = 1'b1; led_g = 1'b0; led_b = 1'b0;
            end
            else if (current_sec_val * 12'd2 > total_sec_store) begin
                led_r = 1'b0; led_g = 1'b1; led_b = 1'b0;
            end
            else begin
                led_r = (pwm_cnt < 4'd8) ? 1'b1 : 1'b0; 
                led_g = 1'b1; 
                led_b = 1'b0;
            end
        end 
        else if (state == S_ALARM) begin
            led_r = blink_cnt[9]; 
            led_g = 1'b0;
            led_b = 1'b0;
        end 
        else begin
            led_r = 1'b0; led_g = 1'b0; led_b = 1'b0;
        end
    end

    // 상태 머신
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_STOP;
            curr_min <= 6'd0;
            curr_sec <= 6'd0;
            tm_run_led <= 1'b0;
            tm_alarm <= 1'b0;
            tick_cnt <= 10'd0;
            total_sec_store <= 12'd0;
            init_min <= 0;
            init_sec <= 0;
        end else begin
            // 리셋 버튼(Key 8)이 눌리면 즉시 초기화
            if (btn_reset_p) begin
                state <= S_STOP;
                curr_min <= 6'd0;
                curr_sec <= 6'd0;
                tm_run_led <= 1'b0;
                tm_alarm <= 1'b0;
                tick_cnt <= 0;
                total_sec_store <= 0;
                // init_min/sec는 남겨둘지 지울지 선택 (여기선 0으로 초기화)
                init_min <= 0;
                init_sec <= 0;
            end
            else begin
                case (state)
                    S_STOP: begin
                        tm_run_led <= 1'b0;
                        tm_alarm <= 1'b0;
                        tick_cnt <= 10'd0;
                        total_sec_store <= (curr_min * 6'd60) + curr_sec;

                        if (btn_min_p) begin
                            if (curr_min >= 59) curr_min <= 0;
                            else curr_min <= curr_min + 1;
                        end
                        else if (btn_sec_p) begin
                            if (curr_sec >= 59) curr_sec <= 6'd0;
                            else curr_sec <= curr_sec + 1;        
                        end
                        
                        if (btn_start_stop_p) begin
                            if (curr_min != 0 || curr_sec != 0) begin
                                state <= S_RUN;
                                init_min <= curr_min;
                                init_sec <= curr_sec;
                            end
                        end
                    end

                    S_RUN: begin
                        tm_run_led <= 1'b1;
                        if (btn_start_stop_p) begin
                            state <= S_STOP;
                        end
                        else begin
                            if (tick_cnt >= 999) begin
                                tick_cnt <= 0;
                                if (curr_sec == 0) begin
                                    if (curr_min == 0) state <= S_ALARM;
                                    else begin
                                        curr_min <= curr_min - 1;
                                        curr_sec <= 59;
                                    end
                                end else begin
                                    curr_sec <= curr_sec - 1;
                                end
                            end else begin
                                tick_cnt <= tick_cnt + 1;
                            end
                        end
                    end

                    S_ALARM: begin
                        tm_run_led <= 1'b0;
                        tm_alarm <= 1'b1;
                        if (btn_start_stop_p || btn_min_p || btn_sec_p) begin
                            state <= S_STOP;
                            tm_alarm <= 1'b0;
                            curr_min <= 6'd0;
                            curr_sec <= 6'd0;
                        end
                    end
                endcase
            end
        end
    end
endmodule
