`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/24 14:02:19
// Design Name: 
// Module Name: lcd_worldclock
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


module lcd_worldclock(
    input clk, rst, mode_12h, is_pm, sw_timer,
    input [1:0] tz_sel,
    input tm_alarm,          
    input sw_alarm,          
    input alarm_ringing,     
    
    input [2:0] edit_slot, 
    input alm1_en, alm2_en, alm3_en, 

    // 타이머 관련 입력
    input tm_running,
    input tm_paused,
    input [5:0] tm_init_min,
    input [5:0] tm_init_sec,

    output LCD_E, output reg LCD_RS, output reg LCD_RW, output reg [7:0] LCD_DATA
);
    reg [3:0] div_cnt;
    reg tick;
    always @(posedge clk or posedge rst) begin
        if (rst) begin div_cnt<=0; tick<=0; end
        else if (div_cnt==9) begin div_cnt<=0; tick<=1; end
        else begin div_cnt<=div_cnt+1; tick<=0; end
    end
    assign LCD_E = tick;

    // 상태 정의
    localparam S_DELAY = 0, S_FUNC_SET = 1, S_DISP_ON = 2, S_ENTRY_MODE = 3,
               S_WC_L1_SET = 4, S_WC_L1_DATA = 5, S_WC_L2_SET = 6, S_WC_L2_DATA = 7,
               S_TM_L1_SET = 8, S_TM_L1_DATA = 9, S_TM_L2_SET = 10, S_TM_L2_DATA = 11,
               S_RING_L1_SET=12,S_RING_L1_DATA=13,S_RING_L2_SET=14,S_RING_L2_DATA=15,
               S_PROG_L1_SET=16, S_PROG_L1_DATA=17, S_PROG_L2_SET=18, S_PROG_L2_DATA=19;

    reg [4:0] state;
    reg [5:0] step;

    wire [3:0] init_m_ten = tm_init_min / 10;
    wire [3:0] init_m_one = tm_init_min % 10;
    wire [3:0] init_s_ten = tm_init_sec / 10;
    wire [3:0] init_s_one = tm_init_sec % 10;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_DELAY; step <= 0; LCD_RS<=0; LCD_RW<=0; LCD_DATA<=0;
        end else if (tick) begin
            
            // 모드 전환 우선순위
            if (alarm_ringing) begin 
                if (state < S_RING_L1_SET || state > S_RING_L2_DATA) begin state <= S_RING_L1_SET; step <= 0; end
            end 
            else if (tm_alarm) begin 
                if (state < S_TM_L1_SET || state > S_TM_L2_DATA) begin state <= S_TM_L1_SET; step <= 0; end
            end
            else if (tm_running) begin 
                if (state < S_PROG_L1_SET || state > S_PROG_L2_DATA) begin state <= S_PROG_L1_SET; step <= 0; end
            end
            else if (sw_alarm) begin 
                 case (state)
                    S_TM_L1_SET, S_TM_L1_DATA, S_TM_L2_SET, S_TM_L2_DATA,
                    S_RING_L1_SET, S_RING_L1_DATA, S_RING_L2_SET, S_RING_L2_DATA,
                    S_PROG_L1_SET, S_PROG_L1_DATA, S_PROG_L2_SET, S_PROG_L2_DATA: begin
                        state <= S_WC_L1_SET; step <= 0;
                    end
                    default: ;
                 endcase
            end 
            else if (sw_timer) begin 
                if (state < S_TM_L1_SET || state > S_TM_L2_DATA) begin state <= S_TM_L1_SET; step <= 0; end
            end 
            else begin 
                if (state > S_WC_L2_DATA) begin state <= S_WC_L1_SET; step <= 0; end
            end

            // 상태 머신
            case (state)
                S_DELAY: begin
                    LCD_RS<=0; LCD_RW<=0; LCD_DATA<=0;
                    if (step >= 19) begin state <= S_FUNC_SET; step <= 0; end else step <= step + 1;
                end
                S_FUNC_SET: begin LCD_RS<=0; LCD_DATA<=8'h38; state <= S_DISP_ON; end
                S_DISP_ON: begin LCD_RS<=0; LCD_DATA<=8'h0C; state <= S_ENTRY_MODE; end
                S_ENTRY_MODE: begin LCD_RS<=0; LCD_DATA<=8'h06; state <= S_WC_L1_SET; end

                // ----------------------------------------------------
                // A. WORLD CLOCK / ALARM SET DISPLAY
                // ----------------------------------------------------
                S_WC_L1_SET: begin LCD_RS<=0; LCD_DATA<=8'h80; state <= S_WC_L1_DATA; step <= 0; end
                S_WC_L1_DATA: begin 
                    LCD_RS<=1;
                    if (sw_alarm) begin
                        if (edit_slot == 0) begin 
                            // "Alarm mode"
                            case(step)
                                0:LCD_DATA<=8'h41; 1:LCD_DATA<=8'h6C; 2:LCD_DATA<=8'h61; 3:LCD_DATA<=8'h72; 4:LCD_DATA<=8'h6D; 
                                5:LCD_DATA<=8'h20; 6:LCD_DATA<=8'h6D; 7:LCD_DATA<=8'h6F; 8:LCD_DATA<=8'h64; 9:LCD_DATA<=8'h65;
                                default:LCD_DATA<=8'h20;
                            endcase
                        end else begin
                            // "Alarm X"
                            case(step)
                                0:LCD_DATA<=8'h41; 1:LCD_DATA<=8'h6C; 2:LCD_DATA<=8'h61; 3:LCD_DATA<=8'h72; 4:LCD_DATA<=8'h6D;
                                5:LCD_DATA<=8'h20; 
                                6:begin
                                    // [수정 완료] edit_slot이 1(Setting) 또는 4(Set)일 때 -> '1' 표시
                                    if(edit_slot==1 || edit_slot==4) LCD_DATA<=8'h31;
                                    // edit_slot이 2(Setting) 또는 5(Set)일 때 -> '2' 표시
                                    else if(edit_slot==2 || edit_slot==5) LCD_DATA<=8'h32;
                                    // 그 외 (3, 6) -> '3' 표시
                                    else LCD_DATA<=8'h33;
                                end
                                default:LCD_DATA<=8'h20;
                            endcase
                        end
                    end else begin
                        // [12/24h]ClockMode
                        case (step)
                            6'd0:  LCD_DATA <= (mode_12h ? 8'h31 : 8'h32); 6'd1:  LCD_DATA <= (mode_12h ? 8'h32 : 8'h34); 
                            6'd2:  LCD_DATA <= 8'h68; 6'd3:  LCD_DATA <= 8'h43; 6'd4:  LCD_DATA <= 8'h6C; 6'd5:  LCD_DATA <= 8'h6F; 6'd6:  LCD_DATA <= 8'h63; 6'd7:  LCD_DATA <= 8'h6B;
                            6'd8:  LCD_DATA <= 8'h4D; 6'd9:  LCD_DATA <= 8'h6F; 6'd10: LCD_DATA <= 8'h64; 6'd11: LCD_DATA <= 8'h65; 
                            6'd12: LCD_DATA <= 8'h20; 6'd13: LCD_DATA <= 8'h20;
                            6'd14: LCD_DATA <= (mode_12h ? (is_pm ? 8'h50 : 8'h41) : 8'h20);
                            6'd15: LCD_DATA <= (mode_12h ? 8'h4D : 8'h20);
                            default: LCD_DATA <= 8'h20;
                        endcase
                    end
                    if (step >= 15) begin state <= S_WC_L2_SET; step <= 0; end else step <= step + 1;
                end

                S_WC_L2_SET: begin LCD_RS<=0; LCD_DATA<=8'hC0; state <= S_WC_L2_DATA; step <= 0; end
                S_WC_L2_DATA: begin 
                    LCD_RS<=1;
                    if (sw_alarm) begin
                        if (edit_slot == 0) begin 
                            // "Slot: 4/5/6"
                            case(step)
                                0:LCD_DATA<=8'h53; 1:LCD_DATA<=8'h6C; 2:LCD_DATA<=8'h6F; 3:LCD_DATA<=8'h74; 4:LCD_DATA<=8'h3A;
                                5:LCD_DATA<=8'h20; 6:LCD_DATA<=8'h34; 7:LCD_DATA<=8'h2F; 8:LCD_DATA<=8'h35; 9:LCD_DATA<=8'h2F; 10:LCD_DATA<=8'h36;
                                default:LCD_DATA<=8'h20;
                            endcase
                        end else if (edit_slot >= 4) begin 
                            // "Set!"
                            case(step)
                                0:LCD_DATA<=8'h53; 1:LCD_DATA<=8'h65; 2:LCD_DATA<=8'h74; 3:LCD_DATA<=8'h21;
                                default:LCD_DATA<=8'h20;
                            endcase
                        end else begin 
                            // "Setting..."
                            case(step)
                                0:LCD_DATA<=8'h53; 1:LCD_DATA<=8'h65; 2:LCD_DATA<=8'h74; 3:LCD_DATA<=8'h74; 4:LCD_DATA<=8'h69; 
                                5:LCD_DATA<=8'h6E; 6:LCD_DATA<=8'h67; 7:LCD_DATA<=8'h2E; 8:LCD_DATA<=8'h2E; 9:LCD_DATA<=8'h2E;
                                default:LCD_DATA<=8'h20;
                            endcase
                        end
                    end else begin
                        // 시계 모드 국적 (기존 유지)
                        case (tz_sel)
                            2'd0: begin /* Korea */
                                case(step) 0:LCD_DATA<=8'h48; 1:LCD_DATA<=8'h65; 2:LCD_DATA<=8'h72; 3:LCD_DATA<=8'h65; 4:LCD_DATA<=8'h20; 5:LCD_DATA<=8'h69; 6:LCD_DATA<=8'h73; 7:LCD_DATA<=8'h20; 8:LCD_DATA<=8'h4B; 9:LCD_DATA<=8'h6F; 10:LCD_DATA<=8'h72; 11:LCD_DATA<=8'h65; 12:LCD_DATA<=8'h61; 13:LCD_DATA<=8'h21; default:LCD_DATA<=8'h20; endcase
                            end
                            2'd1: begin /* Paris */
                                case(step) 0:LCD_DATA<=8'h48; 1:LCD_DATA<=8'h65; 2:LCD_DATA<=8'h72; 3:LCD_DATA<=8'h65; 4:LCD_DATA<=8'h20; 5:LCD_DATA<=8'h69; 6:LCD_DATA<=8'h73; 7:LCD_DATA<=8'h20; 8:LCD_DATA<=8'h50; 9:LCD_DATA<=8'h61; 10:LCD_DATA<=8'h72; 11:LCD_DATA<=8'h69; 12:LCD_DATA<=8'h73; 13:LCD_DATA<=8'h21; default:LCD_DATA<=8'h20; endcase
                            end
                            2'd2: begin /* NY */
                                case(step) 0:LCD_DATA<=8'h48; 1:LCD_DATA<=8'h65; 2:LCD_DATA<=8'h72; 3:LCD_DATA<=8'h65; 4:LCD_DATA<=8'h20; 5:LCD_DATA<=8'h69; 6:LCD_DATA<=8'h73; 7:LCD_DATA<=8'h20; 8:LCD_DATA<=8'h4E; 9:LCD_DATA<=8'h65; 10:LCD_DATA<=8'h77; 11:LCD_DATA<=8'h59; 12:LCD_DATA<=8'h6F; 13:LCD_DATA<=8'h72; 14:LCD_DATA<=8'h6B; 15:LCD_DATA<=8'h21; default:LCD_DATA<=8'h20; endcase
                            end
                            2'd3: begin /* UK */
                                case(step) 0:LCD_DATA<=8'h48; 1:LCD_DATA<=8'h65; 2:LCD_DATA<=8'h72; 3:LCD_DATA<=8'h65; 4:LCD_DATA<=8'h20; 5:LCD_DATA<=8'h69; 6:LCD_DATA<=8'h73; 7:LCD_DATA<=8'h20; 8:LCD_DATA<=8'h55; 9:LCD_DATA<=8'h4B; 10:LCD_DATA<=8'h21; default:LCD_DATA<=8'h20; endcase
                            end
                            default: LCD_DATA<=8'h20;
                        endcase
                    end
                    if (step >= 15) begin state <= S_WC_L1_SET; step <= 0; end else step <= step + 1;
                end

                // (B. TIMER MESSAGE - 생략 없이 포함)
                S_TM_L1_SET: begin LCD_RS<=0; LCD_DATA<=8'h80; state<=S_TM_L1_DATA; step<=0; end
                S_TM_L1_DATA: begin
                    LCD_RS<=1;
                    if(tm_alarm) begin case(step) 0:LCD_DATA<=8'h54; 1:LCD_DATA<=8'h69; 2:LCD_DATA<=8'h6D; 3:LCD_DATA<=8'h65; 4:LCD_DATA<=8'h20; 5:LCD_DATA<=8'h69; 6:LCD_DATA<=8'h73; 7:LCD_DATA<=8'h20; 8:LCD_DATA<=8'h4F; 9:LCD_DATA<=8'h56; 10:LCD_DATA<=8'h45; 11:LCD_DATA<=8'h52; 12:LCD_DATA<=8'h21; default:LCD_DATA<=8'h20; endcase end
                    else begin case(step) 0:LCD_DATA<=8'h54; 1:LCD_DATA<=8'h69; 2:LCD_DATA<=8'h6D; 3:LCD_DATA<=8'h65; 4:LCD_DATA<=8'h72; 5:LCD_DATA<=8'h20; 6:LCD_DATA<=8'h6D; 7:LCD_DATA<=8'h6F; 8:LCD_DATA<=8'h64; 9:LCD_DATA<=8'h65; default:LCD_DATA<=8'h20; endcase end
                    if(step>=15) begin state<=S_TM_L2_SET; step<=0; end else step<=step+1;
                end
                S_TM_L2_SET: begin LCD_RS<=0; LCD_DATA<=8'hC0; state<=S_TM_L2_DATA; step<=0; end
                S_TM_L2_DATA: begin
                    LCD_RS<=1;
                    if(tm_alarm) begin case(step) 0:LCD_DATA<=8'h2A; 1:LCD_DATA<=8'h2C; 2:LCD_DATA<=8'h20; 3:LCD_DATA<=8'h30; 4:LCD_DATA<=8'h2C; 5:LCD_DATA<=8'h20; 6:LCD_DATA<=8'h23; 7:LCD_DATA<=8'h20; 8:LCD_DATA<=8'h74; 9:LCD_DATA<=8'h6F; 10:LCD_DATA<=8'h20; 11:LCD_DATA<=8'h72; 12:LCD_DATA<=8'h65; 13:LCD_DATA<=8'h73; 14:LCD_DATA<=8'h65; 15:LCD_DATA<=8'h74; default:LCD_DATA<=8'h20; endcase end
                    else begin case(step) 0:LCD_DATA<=8'h50; 1:LCD_DATA<=8'h72; 2:LCD_DATA<=8'h65; 3:LCD_DATA<=8'h73; 4:LCD_DATA<=8'h73; 5:LCD_DATA<=8'h20; 6:LCD_DATA<=8'h23; 7:LCD_DATA<=8'h20; 8:LCD_DATA<=8'h74; 9:LCD_DATA<=8'h6F; 10:LCD_DATA<=8'h20; 11:LCD_DATA<=8'h53; 12:LCD_DATA<=8'h74; 13:LCD_DATA<=8'h61; 14:LCD_DATA<=8'h72; 15:LCD_DATA<=8'h74; default:LCD_DATA<=8'h20; endcase end
                    if(step>=15) begin state<=S_TM_L1_SET; step<=0; end else step<=step+1;
                end

                // (C. ALARM RINGING - 생략 없이 포함)
                S_RING_L1_SET: begin LCD_RS<=0; LCD_DATA<=8'h80; state<=S_RING_L1_DATA; step<=0; end
                S_RING_L1_DATA: begin 
                    LCD_RS<=1;
                    case(step) 0:LCD_DATA<=8'h50; 1:LCD_DATA<=8'h72; 2:LCD_DATA<=8'h65; 3:LCD_DATA<=8'h73; 4:LCD_DATA<=8'h73; 5:LCD_DATA<=8'h20; 6:LCD_DATA<=8'h2A; 7:LCD_DATA<=8'h2C; 8:LCD_DATA<=8'h20; 9:LCD_DATA<=8'h30; 10:LCD_DATA<=8'h2C; 11:LCD_DATA<=8'h20; 12:LCD_DATA<=8'h23; 13:LCD_DATA<=8'h20; 14:LCD_DATA<=8'h74; 15:LCD_DATA<=8'h6F; default:LCD_DATA<=8'h20; endcase
                    if(step>=15) begin state<=S_RING_L2_SET; step<=0; end else step<=step+1;
                end
                S_RING_L2_SET: begin LCD_RS<=0; LCD_DATA<=8'hC0; state<=S_RING_L2_DATA; step<=0; end
                S_RING_L2_DATA: begin 
                    LCD_RS<=1;
                    case(step) 0:LCD_DATA<=8'h74; 1:LCD_DATA<=8'h75; 2:LCD_DATA<=8'h72; 3:LCD_DATA<=8'h6E; 4:LCD_DATA<=8'h20; 5:LCD_DATA<=8'h6F; 6:LCD_DATA<=8'h66; 7:LCD_DATA<=8'h66; 8:LCD_DATA<=8'h20; 9:LCD_DATA<=8'h61; 10:LCD_DATA<=8'h6C; 11:LCD_DATA<=8'h61; 12:LCD_DATA<=8'h72; 13:LCD_DATA<=8'h6D; 14:LCD_DATA<=8'h21; 15:LCD_DATA<=8'h20; default:LCD_DATA<=8'h20; endcase
                    if(step>=15) begin state<=S_RING_L1_SET; step<=0; end else step<=step+1;
                end

                // (D. TIMER PROGRESSING - 생략 없이 포함)
                S_PROG_L1_SET: begin LCD_RS<=0; LCD_DATA<=8'h80; state<=S_PROG_L1_DATA; step<=0; end
                S_PROG_L1_DATA: begin 
                    LCD_RS<=1;
                    case(step)
                        0:LCD_DATA<=8'h53; 1:LCD_DATA<=8'h45; 2:LCD_DATA<=8'h54; 3:LCD_DATA<=8'h3A; 4:LCD_DATA<=8'h20; 
                        5:LCD_DATA<=8'h30; 6:LCD_DATA<=8'h30; 
                        7:LCD_DATA<=8'h3A; 
                        8:LCD_DATA<=8'h30 + init_m_ten; 9:LCD_DATA<=8'h30 + init_m_one; 
                        10:LCD_DATA<=8'h3A; 
                        11:LCD_DATA<=8'h30 + init_s_ten; 12:LCD_DATA<=8'h30 + init_s_one; 
                        default:LCD_DATA<=8'h20;
                    endcase
                    if(step>=15) begin state<=S_PROG_L2_SET; step<=0; end else step<=step+1;
                end
                S_PROG_L2_SET: begin LCD_RS<=0; LCD_DATA<=8'hC0; state<=S_PROG_L2_DATA; step<=0; end
                S_PROG_L2_DATA: begin 
                    LCD_RS<=1;
                        case(step)
                            0:LCD_DATA<=8'h50; 1:LCD_DATA<=8'h72; 2:LCD_DATA<=8'h6F; 3:LCD_DATA<=8'h67; 4:LCD_DATA<=8'h72; 
                            5:LCD_DATA<=8'h65; 6:LCD_DATA<=8'h73; 7:LCD_DATA<=8'h73; 8:LCD_DATA<=8'h69; 9:LCD_DATA<=8'h6E; 10:LCD_DATA<=8'h67;
                            11:LCD_DATA<=8'h2E; 12:LCD_DATA<=8'h2E; 13:LCD_DATA<=8'h2E; 
                            default:LCD_DATA<=8'h20;
                        endcase
                    if(step>=15) begin state<=S_PROG_L1_SET; step<=0; end else step<=step+1;
                end

                default: begin LCD_RS<=0; LCD_DATA<=0; state<=S_DELAY; step<=0; end
            endcase
        end
    end
endmodule