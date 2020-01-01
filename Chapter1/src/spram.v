`timescale 1ns / 1ps
/******************************************************************************
//=============================================================================
module name 	: dram
project			: Comunication-IC-Design/Chapter1
Create Date     : 2020/01/01
version			: v0.1
author			: zhangcheng
called by		: 
calling			:
description		: The verilog for simple single SRAM

******************************************************************************/
module spram #(
    parameter   ADDR_WIDTH  = 6,
    parameter   DATA_WIDTH  = 8
)(
    //  
    input clk,
    input we,
    input       [DATA_WIDTH-1:0]    data,
    input       [ADDR_WIDTH-1:0]    addr,
    
    // output
    output      [DATA_WIDTH-1:0]    q
);

//------------------------------Internal sinal-----------------------------------
reg             [DATA_WIDTH-1:0]    ram [2**ADDR_WIDTH-1:0] ;
reg             [ADDR_WIDTH-1:0]    addr_reg;

//-------------------------------Main body---------------------------------------
always @(posedge clk) 
begin
    if(we)
        ram[addr] <= data;
    addr_reg <= addr;
end

assign q = ram[addr_reg];

endmodule