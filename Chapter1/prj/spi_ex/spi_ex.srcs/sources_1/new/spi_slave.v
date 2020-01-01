`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/29 17:01:59
// Design Name: 
// Module Name: spi_slave
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


module spi_slave(
    // input
    input           clk,                    // system clk
    input           ssel,                   // select sigal: low active
    input           sck,                    // master input sck
    input           mosi,                   // master output/slave input
    input   [7:0]   tx_data,                // slave 8-bit tx data

    // output
    output          miso,                   // master output/slave input
    output  reg     rx_data
    );

//------------------------Internal signal---------------------------------------
// wire
wire                sck_rise;
wire                sck_fall;
wire                mosi_data;
wire                ssel_active;

reg         [2:0]   sck_r;                  // sck delay 3 pitch
reg         [2:0]   mosi_r;                 // mosi delay 3 pitch
reg         [2:0]   ssel_r;                 // ssel delay 3 pitch

//---------------------Delay and eliminate metastable state---------------------
// sck_r
always @(posedge clk)
begin
    sck_r <= {sck_r[1:0], sck};
end

// mosi_r
always @(posedge clk)
begin
    mosi_r <= {mosi_r[1:0], mosi};
end

// ssel_r
always @(posedge clk)
begin
    ssel_r <= {ssel_r[1:0], ssel};
end

assign sck_rise = (sck_r[2:1] == 2'b01);            // sck rise flag
assign sck_fall = (sck_r[2:1] == 2'b10);            // sck fall flag
assign mosi_data = mosi_r[1];
assign ssel_active = ~(ssel_r[1]);                  // ssel_active: 1-read tx_data, 0-read mosi_data

//------------------------tx_data and rx_data------------------------------------
reg         [7:0]   byte_data_rx;
reg         [7:0]   byte_data_tx;
reg         [2:0]   bitcnt;
reg                 byte_rx_comp;

// byte_data_tx and byte_data_rx
always @(posedge clk)
begin
    if(ssel_active)
    begin
        byte_data_tx <= tx_data;
    end
    else
    begin
        bitcnt <= 3'b000;
        byte_data_rx <= 8'h00;

        if(sck_rise)
        begin
            bitcnt <= bitcnt + 1;
            byte_data_rx <= {byte_data_rx[6:0], mosi_data};
            byte_data_tx <= {byte_data_tx[6:0], 1'b0};
        end
        else
        begin
            bitcnt <= bitcnt;
            byte_data_rx <= byte_data_rx;
            byte_data_tx <= byte_data_tx;
        end
    end

end

// byte_rx_comp
always @(posedge clk)
begin
    byte_rx_comp <= ssel_active && sck_rise && (bitcnt == 3'b111);  
end

// rx_data
always @(posedge clk)
begin
    if(byte_rx_comp)
        rx_data <= byte_data_rx;
end

// miso
assign miso = byte_data_tx[7];                          // send MSB first

endmodule