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
module dpram #(
    parameter   ADDR_WIDTH  = 6,
    parameter   DATA_WIDTH  = 8
)(
    //  
    input clk,
    input we,
    input       [DATA_WIDTH-1:0]    data,
    input       [ADDR_WIDTH-1:0]    write_addr,
    input       [ADDR_WIDTH-1:0]    read_addr,
    
    // output
    output      [DATA_WIDTH-1:0]    q
);

//------------------------------Internal sinal-----------------------------------
reg             [DATA_WIDTH-1:0]    ram [2**ADDR_WIDTH-1:0] ;
reg             [ADDR_WIDTH-1:0]    q_reg;

//-------------------------------Main body---------------------------------------
always @(posedge clk) 
begin
    if(we)
        ram[write_addr] <= data;
    q_reg <= ram[read_addr];
end

assign q = q_reg;

endmodule