`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/24 14:01:03
// Design Name: 
// Module Name: world_time_calc
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


module world_time_calc(
    input  [4:0] hour_kst,
    input  [1:0] tz_sel,
    output reg [4:0] hour24
);
    reg [4:0] utc_hour;
    reg [5:0] tmp; // [수정] 5비트([4:0]) -> 6비트([5:0])로 확장 (최대값 32 표현 가능)

    always @(*) begin
        // 1) KST -> UTC
        if (hour_kst >= 5'd9) utc_hour = hour_kst - 5'd9;
        else                  utc_hour = hour_kst + 5'd15;

        // 2) UTC -> 각 도시
        case (tz_sel)
            2'd0: begin  // Korea (UTC+9)
                tmp = utc_hour + 6'd9; // [수정] 상수도 6비트로 처리 권장
                if (tmp >= 6'd24) tmp = tmp - 6'd24;
                hour24 = tmp[4:0]; // 하위 5비트만 할당
            end
            2'd1: begin  // Paris (UTC+1)
                tmp = utc_hour + 6'd1;
                if (tmp >= 6'd24) tmp = tmp - 6'd24;
                hour24 = tmp[4:0];
            end
            2'd2: begin  // New York (UTC-5)
                if (utc_hour >= 5'd5) tmp = utc_hour - 5'd5;
                else                  tmp = utc_hour + 5'd19;
                hour24 = tmp[4:0];
            end
            2'd3: begin  // UK (UTC+0)
                hour24 = utc_hour;
            end
            default: hour24 = hour_kst;
        endcase
    end
endmodule
