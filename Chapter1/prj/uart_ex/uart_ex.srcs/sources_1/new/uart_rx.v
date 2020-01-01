`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/29 22:31:54
// Design Name: 
// Module Name: uart_rx
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

module uart_rx(
    // input
    input           i_clk,                          // system clk
    input           i_rst_n,                        // synchronous reset: low active
    input           i_enable_n,                     // enable rx: low active
    input           i_clk_rx,                       // serial rx shift clk
    input           i_int_clrxn,                    // clear interupt input
    input           i_rx_data,                      // serial rx shift data
    input   [1:0]   i_parity,                       // parity mode

    // output
    output  [1:0]   o_rx_int,                       // rx interupt output: rx data is ready
    output  [7:0]   o_data,                         // rx data
    output          o_rx_err                        // rx error flag
    );

//--------------------------Internal signal-------------------------------------
// localparam
localparam          P_EVEN      = 2'b00;            // even parity
localparam          P_ODD       = 2'b01;            // odd parity
localparam          P_NONE      = 2'b10;            // no parity

// wire
wire rx_start_en;
wire parity_finish;
wire none_parity_finish;

// reg
reg                 rx_start;
reg                 rx_parity;
reg     [3:0]       rx_num;
reg     [7:0]       rx_data;
reg                 rx_err;

//-----------------------------Main body-----------------------------------------
// assign
assign rx_start_en = rx_start && (~i_enable_n);
assign parity_finish =  (rx_num == 4'd10) && ((i_parity == P_EVEN) | (i_parity == P_ODD));
assign none_parity_finish = (rx_num == 4'd9) && (i_parity == P_NONE);

// rx_start
always @(posedge i_clk)
begin
    if(!i_rst_n | rx_err)
    begin
        rx_parity <= P_NONE;
        rx_start <= 0;
    end
    else if(i_clk_rx && !i_rx_data && rx_num == 0)
    begin
        rx_parity <= i_parity;
        rx_start <= 1;
    end
    else if(i_rx_data && (none_parity_finish | parity_finish))
    begin
        rx_parity <= P_NONE;
        rx_start <= 0;
    end
end

// rx_data
always @(posedge i_clk)
begin
    if(!i_rst_n)
    begin
        rx_num <= 4'b0;
        rx_data <= 8'b0000_0000;
        rx_err <= 1'b0;
    end
    else if(i_clk_rx && rx_start_en)
    begin
        rx_num <= rx_num + 1;
        case(rx_num)
            4'd0:
            begin
                rx_data[0] <= i_rx_data;
                rx_err <= 1'b0;
            end
            4'd1: rx_data[1] <= i_rx_data;
            4'd2: rx_data[2] <= i_rx_data;
            4'd3: rx_data[3] <= i_rx_data;
            4'd4: rx_data[4] <= i_rx_data;
            4'd5: rx_data[5] <= i_rx_data;
            4'd6: rx_data[6] <= i_rx_data;
            4'd7: rx_data[7] <= i_rx_data;
            4'd8: 
            case(rx_parity)                                // check parity bit
                P_EVEN: rx_err <= ^rx_data ^ i_rx_data;
                P_ODD:  rx_err <= ^rx_data ^ i_rx_data;
                P_NONE: rx_err <= ~i_rx_data;
            endcase
            4'd9: rx_err <= ~i_rx_data | rx_err;
        endcase
    end
    else if(none_parity_finish | parity_finish)
    rx_num <= 4'd0;
end

// data and intrupt
reg     [7:0]   data;
reg             rx_int;

always @(posedge i_clk)
begin
    if(!i_rst_n)
    begin
        data <= 8'h00;
        rx_int <= 0;
    end
    else if(none_parity_finish | parity_finish)
    begin
        if(!rx_err)
        begin
            data <= rx_data;
            rx_int <= 1'b1;
        end
        else
        begin
            data <= 8'hzz;
            rx_int <= 1'b0;
        end
    end
    else if(!i_int_clrxn)
    begin
        data <= 8'hzz;
        rx_int <= 1'b0;
    end
end

// ouput
assign o_data = data;
assign o_rx_int = rx_int;
assign o_rx_err = rx_err;

endmodule
