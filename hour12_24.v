`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/24 13:59:22
// Design Name: 
// Module Name: hour12_24
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


module hour12_24(
    input [4:0] hour24,
    input mode_12h,
    output reg [4:0] hour_disp,
    output reg is_pm
);
    always @(*) begin
        if (!mode_12h) begin
            hour_disp = hour24;
            is_pm     = 1'b0;
        end else begin
            if (hour24 < 5'd12) begin
                is_pm = 1'b0;
                if (hour24 == 5'd0)
                    hour_disp = 5'd0;
                else
                    hour_disp = hour24;
            end else begin
                is_pm = 1'b1;
                if (hour24 == 5'd12)
                    hour_disp = 5'd12;
                else
                    hour_disp = hour24 - 5'd12;
            end
        end
    end
endmodule
