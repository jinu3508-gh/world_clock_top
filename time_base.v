`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/24 14:05:06
// Design Name: 
// Module Name: time_base
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


module time_base(
    input clk,
    input rst,
    input adj_min_p,
    input adj_hour_p,
    output reg [5:0] sec,
    output reg [5:0] min,
    output reg [4:0] hour
);
    reg [9:0] h_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst)
            h_cnt <= 10'd0;
        else if (h_cnt >= 10'd999)
            h_cnt <= 10'd0;
        else
            h_cnt <= h_cnt + 10'd1;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sec  <= 6'd0;
            min  <= 6'd0;
            hour <= 5'd0;
        end
        else if (adj_min_p) begin
            if (min >= 6'd59)
                min <= 6'd0;
            else
                min <= min + 6'd1;
        end
        else if (adj_hour_p) begin
            if (hour >= 5'd23)
                hour <= 5'd0;
            else
                hour <= hour + 5'd1;
        end
        else if (h_cnt == 10'd999) begin
            if (sec >= 6'd59) begin
                sec <= 6'd0;
                if (min >= 6'd59) begin
                    min <= 6'd0;
                    if (hour >= 5'd23)
                        hour <= 5'd0;
                    else
                        hour <= hour + 5'd1;
                end
                else begin
                    min <= min + 6'd1;
                end
            end
            else begin
                sec <= sec + 6'd1;
            end
        end
    end
endmodule
