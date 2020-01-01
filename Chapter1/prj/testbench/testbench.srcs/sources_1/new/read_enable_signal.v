`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/26 21:09:13
// Design Name: 
// Module Name: read_enable_signal
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
///////////////////////////////////////                                                                                                                                                                                                                                                                  
///////////////////////////////////////////
`define LAST_TIME 3_000_000
`define DLAY_1 1

module read_enable_signal#(
    parameter WIDTH = 16,
    parameter FILENAME = "./user_files/data/sin_data_fix.txt"
)(
    // input
    input clk,
    input enable,

    // output
    output reg signed[WIDTH-1:0] signal_out
    );

//------------------------------signal declaration----------------------------
integer signal_FILE;
reg signal_isNotFirstRise = 0;
reg signal_isSimulationEnd = 0;
reg signed [WIDTH-1:0] signal_temp_i;

//-------------------------------main body0----------------------------------
// open file
initial
begin
    signal_out = 0;
    #`DLAY_1 signal_FILE = $fopen(FILENAME, "r");
    if(signal_FILE == 0)
    begin
        $display("Error at opening files: %s", FILENAME);
        $stop;
    end
    else
        $display("Loading %s ......", FILENAME);
end

// signal_isNotFirstRise
always @(posedge clk)
begin
    signal_isNotFirstRise <= #`DLAY_1 1'b1;
end

// read data
always @(posedge clk)
begin
    if(signal_isNotFirstRise)
    begin
        if($feof(signal_FILE) != 0)
        begin
            signal_isSimulationEnd = 1;
            $fclose(signal_FILE);
            #`LAST_TIME;
            $finish(2);
        end
        else if(enable)
        begin
            if($fscanf(signal_FILE, "%d\n", signal_temp_i)<1)           // read data failure
            begin
                signal_isSimulationEnd = 1;
                #`LAST_TIME;
                $finish(2);
            end
            else
            begin
                `ifdef DATA_DEBUG
                    $display("Data is %d", signal_temp_i);
                `endif
                signal_out <= #`DLAY_1 signal_temp_i;
            end
        end
    end
end

endmodule
