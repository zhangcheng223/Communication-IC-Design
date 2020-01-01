`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/31 10:02:49
// Design Name: 
// Module Name: AHB_LED
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
`include "AMBA_defines.v"
`define ADDR_WIDTH      18
`define LED_DATA_ADDR   0
`define LED_CFG_ADDR    1
`define LED_STAT_ADDR   2
`define LED_UPPER_ADDR  10

module AHB_LED #(
    parameter                   LED_WIDTH   = 32    ,
    parameter                   CFG_WIDTH   = 32    ,
    parameter                   SAT_WIDTH   = 32
)(
    // AHB
    // input
    input                       HCLK                ,
    input                       HRESETn             ,
    input   [`ADDR_WIDTH+1:2]   HADDR               ,
    input                       HSEL                ,
    input                       HWRITE              ,
    input   [31:0]              HWDATA              ,
    input   [1:0]               HTRANS              ,
    input   [2:0]               HSIZE               ,
    input   [2:0]               HBURST              ,
    input   [3:0]               HPROT               ,
    input                       HMASTLOCK           ,
    input                       HREADY              ,

    // output
    output  reg                 HREADYOUT           ,
    output                      HRESP               ,
    output  reg     [31:0]      HRDATA              ,

    // user ports
    input   [SAT_WIDTH-1:0]     LED_STATUS          ,
    output reg  [CFG_WIDTH-1:0]     LED_CFG          ,
    output reg  [LED_WIDTH-1:0]     LED

    );

//--------------------------Internal signal----------------------------------
reg                             hresp_temp          ;
reg                             hresp_temp_1q       ;
reg                             hsel_1q             ;    
reg         [`ADDR_WIDTH+1:2]   haddr_1q            ;
reg                             hwrite_1q           ;     

//-------------------------------Main body----------------------------------
assign HRESP = hresp_temp || hresp_temp_1q;


// HREADYOUT and hresp_temp
always @(posedge HCLK or negedge HRESETn)
begin
    if(~HRESETn) begin
        HREADYOUT <= 1'b1;
        hresp_temp <= `HRESP_OK;
    end
    else if(HSEL && HREADY && (HTRANS == `HTRANS_NONSEQ || HTRANS == `HTRANS_SEQ)) begin
        if(HADDR[`ADDR_WIDTH+1:2] > `LED_UPPER_ADDR) begin
            HREADYOUT <= 1'b0;
            hresp_temp <= `HRESP_ERROR;
        end
        else begin
            HREADYOUT <= 1'b1;
            hresp_temp <= `HRESP_OK;
        end
    end
    else begin
        HREADYOUT <= 1'b1;
        hresp_temp <= `HRESP_OK;
    end
end

// hresp_temp delay a pitch
always @(posedge HCLK or negedge HRESETn)
begin
    if(~HRESETn)
        hresp_temp_1q <= `HRESP_OK;
    else
        hresp_temp_1q <= hresp_temp;
end

// HSEL, HWRITE, HADDR
always @(posedge HCLK or negedge HRESETn)
begin
    if(!HRESETn) begin
        hsel_1q <= 1'b0;
        hwrite_1q <= 1'b0;
        haddr_1q <= 0;
    end
    else if(HSEL && HREADY && (HTRANS == `HTRANS_NONSEQ || HTRANS == `HTRANS_SEQ)) begin
        hsel_1q <= 1'b1;
        hwrite_1q <= 1'b1;
        haddr_1q <= HADDR;
    end
    else if(HREADY) begin
        hsel_1q <= 1'b0;
        hwrite_1q <= 1'b0;
        haddr_1q <= 0;
    end
end

//------------------------------User logic-----------------------------------
always @(posedge HCLK or negedge HRESETn)
begin
    if(!HRESETn) begin
        HRDATA <= 32'd0;
    end
    else if(HSEL && HREADY && (HTRANS == `HTRANS_NONSEQ || HTRANS == `HTRANS_SEQ)) begin
        case(HADDR[`ADDR_WIDTH+1:2])
            `LED_DATA_ADDR: HRDATA <= {{{32-LED_WIDTH}{1'b0}}, LED};
            `LED_CFG_ADDR:  HRDATA <= {{{32-CFG_WIDTH}{1'b0}}, LED_CFG};
            `LED_STAT_ADDR: HRDATA <= {{{32-SAT_WIDTH}{1'b0}}, LED_STATUS};
            default: HRDATA <= 32'h0;
        endcase
    end
end

always @(posedge HCLK or negedge HRESETn)
begin
    if(~HRESETn) begin
        LED <= 0;
        LED_CFG <= 0;
    end
    else if(HSEL && HREADY && (HTRANS == `HTRANS_NONSEQ || HTRANS == `HTRANS_SEQ)) begin
        case(haddr_1q[`ADDR_WIDTH+1:2])
            `LED_DATA_ADDR: LED <= HWDATA;
            `LED_CFG_ADDR:  LED_CFG <= HWDATA;
        endcase
    end
end

endmodule
