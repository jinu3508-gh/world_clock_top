`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/24 13:38:46
// Design Name: 
// Module Name: oneshot_universal
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


module oneshot_universal #(
    parameter WIDTH = 1
)(
    input                  clk,
    input                  rst,
    input  [WIDTH-1:0]     btn,
    output [WIDTH-1:0]     btn_trig
);

    reg [WIDTH-1:0] btn_sync0;
    reg [WIDTH-1:0] btn_sync1;
    reg [WIDTH-1:0] btn_prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_sync0 <= {WIDTH{1'b0}};
            btn_sync1 <= {WIDTH{1'b0}};
            btn_prev  <= {WIDTH{1'b0}};
        end else begin
            btn_sync0 <= btn;
            btn_sync1 <= btn_sync0;
            btn_prev  <= btn_sync1;
        end
    end

    assign btn_trig = btn_sync1 & ~btn_prev;

endmodule
