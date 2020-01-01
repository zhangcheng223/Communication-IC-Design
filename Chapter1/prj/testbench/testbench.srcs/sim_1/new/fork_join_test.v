`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/28 16:07:11
// Design Name: 
// Module Name: fork_join_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: The test for fork-join and begin-end
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fork_join_test(
    output reg a,
    output reg b,
    output reg c,
    output reg d,
    output reg e,
    output reg f
    );

localparam PERIOD = 40;

// clk
reg clk = 0;
initial
begin: clock_gen
    clk = 0;
    forever #(PERIOD/2) clk = ~clk;
end

// initial ouput
initial
begin
    a = 0;
    b = 0;
    c = 0;
    d = 0;
    e = 0;
    f = 0;

    repeat(5) @(posedge clk);
    $finish(2);
end

// monitor
initial $monitor($time, "a = %b, b = %b, c = %b, d = %b,e = %b, f = %b", a, b, c, d, e, f);

// fork-join
always @(posedge clk)
fork
    #2 a = ~a;
    #2 b = ~b;

    begin                       // 6ns
        #2 c = ~a;
        #2 d = ~b;
        #2 e = ~c;
    end

    #2 f = ~e;
join

endmodule
