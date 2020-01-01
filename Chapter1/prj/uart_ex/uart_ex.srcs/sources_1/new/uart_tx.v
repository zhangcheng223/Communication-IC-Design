`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/30 16:04:30
// Design Name: 
// Module Name: uart_tx
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


module uart_tx(
    // input
    input           i_clk,                  // serial system clk
    input           i_rst_n,                // syschronous reset: low active
    input           i_start_n,              // start bit flag: low active
    input           i_tx_clk,               // Boud rate clk
    input   [7:0]   i_data,                 // data to be tx
    input   [1:0]   i_parity,               // parity mode

    // output
    output          o_tx_data,              // serial data output
    output          o_tx_intr               // complete tx flag
    );

//---------------------------Internal signal--------------------------------------
// localparam
localparam  [1:0]   P_EVEN  =   2'b00;
localparam  [1:0]   P_ODD   =   2'b01;
localparam  [1:0]   P_NONE  =   2'b10;

// reg
reg                 tx_start;
reg         [7:0]   tx_data;
reg                 tx_parity;
reg         [3:0]   tx_num;
// wire


//-------------------------------Main body----------------------------------------
// generate internal siganl
always @(posedge i_clk)
begin
    if(!i_rst_n) begin
        tx_start <= 1'b0;
        tx_data <= 8'h00;
        tx_parity <= 1'b0;
    end
    else if(!i_start_n) begin
        tx_start <= 1'b1;
        tx_data <=  i_data;
        tx_parity <= i_parity; 
    end
    else if(tx_num == 4'd11) begin
        tx_start <= 1'b1;
        tx_data <= 'bx;
        tx_parity <= 'bx;
    end
end

// process tx state
wire            tx_start_en;
reg             tx_data_temp;

assign tx_start_en = tx_start && (i_rst_n);
always @(posedge i_clk)
begin
    if(!i_rst_n) begin
        tx_data_temp <= 1'b1;
        tx_num <= 0;
    end
    else if(tx_start_en && i_tx_clk) begin
        tx_num <= tx_num + 1;
        case (tx_num)
            4'd0: tx_data_temp <= 0;                // start bit: 0
            4'd1: tx_data_temp <= tx_data[0];       // LSB first
            4'd2: tx_data_temp <= tx_data[1];
            4'd3: tx_data_temp <= tx_data[2];
            4'd4: tx_data_temp <= tx_data[3];
            4'd5: tx_data_temp <= tx_data[4];
            4'd6: tx_data_temp <= tx_data[5];
            4'd7: tx_data_temp <= tx_data[6];
            4'd8: tx_data_temp <= tx_data[7];
            4'd9:
            case(tx_parity)
                P_EVEN: tx_data_temp <= ~^tx_data;      // even parity
                P_ODD:  tx_data_temp <= ^tx_data;       // tx_data
                P_NONE: tx_data_temp <= 1;
                default: tx_data_temp <= 1;    
            endcase
            4'd10: tx_data_temp <= 1;                   // stop bit
            default: tx_data_temp <= 1;
        endcase
    end
    else if(tx_num == 4'd11)
        tx_num <= 0;
end

// generate interrupt siganl
reg         tx_intr;
always @(posedge i_clk)
begin
    if(!i_rst_n || (tx_start && tx_num != 4'd11))
        tx_intr <= 0;
    else if(tx_start && tx_num == 4'd11)
        tx_intr <= 1;
end
assign o_tx_intr = tx_intr;
assign o_tx_data = tx_data_temp;

endmodule
