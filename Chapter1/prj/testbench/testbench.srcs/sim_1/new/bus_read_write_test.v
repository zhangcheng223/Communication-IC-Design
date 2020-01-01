`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/28 17:26:37
// Design Name: 
// Module Name: bus_read_write_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: The example of test bus read and write
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module bus_read_write_test();

// parameter
localparam PERIOD = 100;

// internal signal
reg clk;            
reg rd;                     // flag of read
reg wr;                     // flag of write
reg ce;                     // 1: read and write, 0: don't do anything
reg [7:0] addr;
reg [7:0] data_wr;          // ram
reg [7:0] data_rd;          // ram

reg [7:0] read_data;        


// Clock generator
initial
begin: clk_gen
    clk = 0;
    forever #(PERIOD/2) clk = ~clk;
end

// initial variable
initial
begin
    rd = 0;
    wr = 0;
    ce = 0;
    addr = 0;
    data_wr = 0;
    data_rd = 0;
end

// write and read
initial
begin
    // call cpu_write
    #1 cpu_write(8'h55, 8'hF0);
    #1 cpu_write(8'hAA, 8'h0F);
    #1 cpu_write(8'hBB, 8'hCC);
    
    // call cpu_read
    #1 cpu_read(8'h55, read_data);
    #1 cpu_read(8'hAA, read_data);
    #1 cpu_read(8'hBB, read_data);

    repeat(10) @(posedge clk)
    $finish(2);
end


// task: cpu_write
task cpu_write;
    // input
    input [7:0] address;
    input [7:0] data;

    // main body
    begin
        $display("%g CPU Write @ address: %h Data: %h", $time, address, data);
        $display("%g Diriving CE, WR, WR data and ADDRESS on to bus", $time);

        // load address and data state
        @(posedge clk);
        addr = address;
        ce = 1;
        wr = 1;
        data_wr = data;

        // idle state
        @(posedge clk)
        addr = 0;
        ce = 0;
        wr = 0;
        data_wr = 0;

        $display("=======================================================");
    end
endtask

// task: cpu_read
task cpu_read;
    input [7:0] address;
    output [7:0] data;

    // main body
    begin
        $display("%g CPU Read @ address: %h", $time, address);
        $display("%g Diriving CE, RD, and ADDRESS on to bus", $time);

        // load address
        @(posedge clk)
        addr = address;
        ce = 1;
        rd = 1;

        // read data
        @(negedge clk)
        data = data_rd;

        @(posedge clk)
        addr = 0;
        ce = 0;
        rd = 0;

        $display("%g CPU Read data  : %h", $time, data);
        $display("=======================================================");
    end
endtask

// ram model: width 8, address 256
reg [7:0] mem [0:255];
always @(*)
begin
    if(ce)
    begin
        if(wr)
            mem[addr] = data_wr;
        if(rd)
            data_rd = mem[addr];
    end
end

endmodule
