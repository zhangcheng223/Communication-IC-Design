`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/17 21:09:59
// Design Name: 
// Module Name: freq_count
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

module freq_count(
    // input
    input refclk_i,
    input tstclk_i,

    // output
    output reg freq_cnt_o
    );

// paramter
parameter refclk_freq = 32'd125_000_000;            // refclk_i frequence
localparam  mea_time= 32'd100_000_000;              // measure time
localparam  mea_cnt = refclk_freq/mea_time;         // the ref_clk counter in measure time

//--------------------------------Signal Declaration-------------------------------------
reg [31:0] refclk_cnt = 31'd0;
reg [31:0] tstclk_cnt;

reg pulse = 0;
reg pulse_rega;
reg pulse_regb;
reg pulse_regc;

//-----------------------------------Main body--------------------------------------------
// generate pulse
always @(posedge refclk_i)
begin
    if(refclk_cnt <= mea_cnt-1)
    begin
        pulse <= pulse;
        refclk_cnt <= refclk_cnt + 1;
    end
    else
    begin
        refclk_cnt <= refclk_cnt;
        pulse <= ~pulse;
    end
end

// align tstclk_cnt and pulse
always @(posedge tstclk_i)
begin
    pulse_rega <= pulse;
    pulse_regb <= pulse_rega;
    pulse_regc <= pulse_regb;
end

// tstclk_i count frequence
always@(posedge tstclk_i)
begin
    if(pulse_regc == 1'b0 && pulse_regb == 1'b1)
    begin
        tstclk_cnt <= 32'd0;
        freq_cnt_o <= tstclk_cnt;
    end
    else if(pulse_regc == 1'b1)
        tstclk_cnt <= tstclk_cnt + 1;
    else
        tstclk_cnt <= tstclk_cnt;
end

endmodule
