`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/27 21:47:48
// Design Name: 
// Module Name: write_enable_signal
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
`define LAST_TIME_2 3_000_000
`define DLY_1 1
module write_enable_signal#(
    parameter WIDTH = 16,
    parameter FILENAME = "sin_write.txt"
)(
    // input
    input clk,
    input enable,
    input signed [WIDTH-1:0] signal_in
    
    );

//----------------------------Internal sigal declaration---------------------------
integer signal_fw;
reg signal_isNotFirstRise = 0;
reg signal_isSimulationEnd = 0;
reg signed [WIDTH-1:0] sign_in_temp;
reg write_flag = 0;


//-----------------------------Main body------------------------------------------
// open file
initial
begin
    #`DLY_1;
    signal_fw = $fopen(FILENAME, "w");
    if(signal_fw == 0)
    begin
        $display("Error at opening files: %s", FILENAME);
        $stop();
    end
    else
        $display("Loading %s ......", FILENAME);
end

// signal_isNotFirstRise
always @(posedge clk)
begin
    #`DLY_1 signal_isNotFirstRise <= 1'b1;
end

// write data
always @(posedge clk)
begin
    if(signal_isNotFirstRise)
    begin
        if(enable)
        begin
            # `DLY_1
            $fwrite(signal_fw, "%d\n", signal_in);
        end
    end
end

endmodule
