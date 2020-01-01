`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/26 22:17:39
// Design Name: 
// Module Name: read_enable_signal_tb
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


module read_enable_signal_tb();

// parameter
localparam WIDTH = 16;
localparam RD_FILENAME =  "F:/FPGA/FPGA_Tutorial/Communication_IC_Design/Chapter1/prj/testbench/user_files/data/sin_data_fix.txt";
localparam WR_FILENAME = "F:/FPGA/FPGA_Tutorial/Communication_IC_Design/Chapter1/prj/testbench/user_files/data/sin_write.txt";
//localparam FILENAME =  "./user_files/data/sin_data_fix.txt";
localparam RD_PERIOD = 100; 
localparam WR_PERIOD = 200;
localparam WR_RD_DLY = 2;                         

// input
reg rd_clk;                     // 10MHz
reg wr_clk;                     // 5MHz
reg rd_enable;                  
reg wr_enable;


// output
wire signed [WIDTH-1:0] rd_signal;
wire rd_isSimulationEnd = 0;
wire wr_isSimulationEnd = 0;


// signal initial
initial
begin
    rd_clk = 0;
    wr_clk = 0;
    rd_enable = 0;
    wr_enable = 0;

    #(2*RD_PERIOD)      rd_enable = 1;
    #WR_RD_DLY          wr_enable = 1;

    #(1000*RD_PERIOD)   rd_enable = 0;
    # WR_RD_DLY         wr_enable = 0;
    #(10010*RD_PERIOD)  rd_enable = 1;
    # WR_RD_DLY         wr_enable = 1;

//    #(110000*RD_PERIOD) $finish(2);
end

// clock
always #(RD_PERIOD/2) rd_clk = ~rd_clk;
always #(WR_PERIOD/2) wr_clk = ~wr_clk;

// instantiation
read_enable_signal#(
    .WIDTH(WIDTH),
    .FILENAME(RD_FILENAME)
)  u_read_enable_signal(
    // input
    .clk(rd_clk),
    .enable(rd_enable),

    // output
    .signal_out(rd_signal)
);

write_enable_signal#(
    .WIDTH(WIDTH),
    .FILENAME(WR_FILENAME)
)  u_write_enable_signal(
    // input
    .clk(rd_clk),
    .enable(rd_enable),
    .signal_in(rd_signal)
);

endmodule
