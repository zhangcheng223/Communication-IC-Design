`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/01/01 11:32:37
// Design Name: 
// Module Name: dram_tb
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


module dram_tb(

    );
// parameter
parameter   ADDR_WIDTH  = 8;
parameter   DATA_WIDTH  = 8;
parameter   PERIOD      = 10;

// reg
reg clk;
reg we;
reg       [DATA_WIDTH-1:0]    data;
reg       [ADDR_WIDTH-1:0]    addr;
    
// wire
wire      [DATA_WIDTH-1:0]    q   ;

// clock
initial
begin
    clk = 1;
    forever
        #(PERIOD/2) clk = ~clk;
end

// 
initial
begin
    we = 0;
    data = 0;
    addr = 0;
    
    #(PERIOD*2) we = 1'b1;
    #(PERIOD*3);
    addr = 8'h01;
    data = 8'h11;
    
    #(PERIOD*5);
    addr = 8'h02;
    data = 8'h22;
end

// instaniation
dram #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) u_dram(
    // input
    .clk(clk),
    .we(we),
    .addr(addr),
    .data(data),

    // output
    .q(q)
);


endmodule
