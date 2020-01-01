`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/26 17:15:55
// Design Name: 
// Module Name: count
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


module count #(
    parameter N = 8
)(
    // input
    input clear,
    input clk,

    // output
    output [N-1:0] cnt_Q
    );
//---------------------------Signal Declaration---------------------------
reg [N-1:0] cnt;

//-----------------------------Main body----------------------------------
assign cnt_Q = cnt;

always@(posedge clk or posedge clear)
begin
    if(clear)
        cnt <= 'h0;
    else
        cnt <= cnt+1;
end


endmodule
