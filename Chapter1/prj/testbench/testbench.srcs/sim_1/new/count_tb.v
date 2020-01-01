`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/26 17:22:38
// Design Name: 
// Module Name: count_tb
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


module count_tb();
// parameter
localparam N = 4;               // width
localparam PERIOD = 100;        // 10MHz

// input
reg rst;
reg clk;

// output
wire [N-1:0] cnt;

// intial signal
initial
begin
    clk = 0;
    rst = 0;
    #PERIOD rst = 1;
    #(2*PERIOD) rst = 0;

    #(1000*PERIOD) $finish;
end

// clk
always #(PERIOD/2) clk = ~clk;

// monitor
initial
begin
    $monitor($time, "clk = %d, reset = %d, cnt = %d.", clk, rst, cnt);
end

// instantiation: count
count #(
    .N(N)
) u_count(
    // input
    .clear(rst),
    .clk(clk),

    // output
    .cnt_Q(cnt)
);


endmodule
