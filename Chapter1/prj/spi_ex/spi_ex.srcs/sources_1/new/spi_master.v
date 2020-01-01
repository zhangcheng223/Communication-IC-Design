`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/28 21:21:06
// Design Name: 
// Module Name: spi_master
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


module spi_master(
    input           sysclk,                 // Global clock
    input           rst_x,                  // low asychronous reset
    input           enable,                 // synchronous enable

    // SPI interface signals
    output          sck,                    // SPI serial clock signal
    input           miso,                   // SPI master input/slave output signal
    output  reg     mosi,                   // SPI master output/slave input signal

    // SPI master internal signals
    input           cpol,                   // SPI serial clock polarity
    input           cpha,                   // SPI serial clock phase
    output          ss,                     // SPI slave select signal

    // SPI serial clock divisor and tx rx data internal signal
    input   [7:0]   tx_data_reg,            // tx data register
    input           rx_reg_re,              // read enable for rx_data_reg
    input   [2:0]   clocksel,               // clock divisor select signal
    output          rx_data_ready,          // status signal: rx data ready to read
    output          tx_reg_empty,           // status signal: tx reg can be written
    output  reg [7:0]   rx_data_reg,            // rx data register

    // status signal: spi master is busy transmitting data or has data in the tx_data_reg to be transimitted
    input           spi_rd_shift,
    output          busy,
    output          rx_error,
    input           tx_reg_we,              // write enable for tx_data_reg
    input           clear_error             // synchronous reset for clearing rx error

);
//------------------------------------internal signals--------------------------------------------------------
// localparam
localparam  [3:0]   IDLE    =   4'd0;
localparam  [3:0]   D7      =   4'd1;
localparam  [3:0]   D6      =   4'd2;
localparam  [3:0]   D5      =   4'd3;
localparam  [3:0]   D4      =   4'd4;
localparam  [3:0]   D3      =   4'd5;
localparam  [3:0]   D2      =   4'd6;
localparam  [3:0]   D1      =   4'd7;
localparam  [3:0]   D0      =   4'd8;
localparam  [3:0]   FINAL_CYCLE =4'd9;
localparam  [3:0]   LOAD_SHIFT_REG  = 4'd10;

// wire and reg
reg         [3:0]   state;
reg         [3:0]   next_state;
reg                 i_sck;
reg                 d_sck;
wire                c_sck;
reg                 tsck;
reg                 i_ss;
reg                 tss;
reg                 i_tx_reg_empty;
reg         [7:0]   clock_count;
reg                 tx_data_ready;
reg                 clear_tx_data_ready;
reg         [7:0]   tx_shift_reg;
reg         [7:0]   rx_shift_reg;
reg                 shift_enable;
reg                 tx_shift_reg_load;
reg                 d_tx_shfit_reg_load;
reg                 sck_enable;
reg                 load_rx_data_reg;
reg                 rx_error_i;
reg                 rx_data_waiting;
reg                 rx_shift_enable1;
reg                 rx_shift_enable2;
wire                 rx_shift_enable;

//----------------------------------Serial Data clock generation----------------------------------------------
always @(posedge sysclk or negedge rst_x)
begin
    if(!rst_x)
    begin
        clock_count <= 8'd0;
        i_sck <= 1'b0;
        d_sck <= 1'b0;
    end
    else
    begin
        if(enable)
        begin
            clock_count <= clock_count + 8'd1;
        end
        case(clocksel)
            3'b000:
            begin
                i_sck <= clock_count[0];                // sysclk/2
            end
            3'b001:
            begin
                i_sck <= clock_count[1];                // sysclk/4
            end
            3'b010:
            begin
                i_sck <= clock_count[2];                // sysclk/8
            end
            3'b011:
            begin
                i_sck <= clock_count[3];                // sysclk/16
            end
            3'b100:
            begin
                i_sck <= clock_count[4];                // sysclk/32
            end
            3'b101:
            begin
                i_sck <= clock_count[5];                // sysclk/64
            end
            3'b110:
            begin
                i_sck <= clock_count[6];                // sysclk/128
            end
            3'b111:
            begin
                i_sck <= clock_count[7];                // sysclk/256
            end
            default:
            begin
                i_sck <= clock_count[0];                // default: sysclk/2
            end
        endcase
    end
    d_sck <= i_sck;                                     // i_sck delay a beat
end

// // c_sck
assign c_sck = (cpol == 1'b0 && cpha == 1'b0)? sck_enable & (~d_sck)    :
               (cpol == 1'b0 && cpha == 1'b1)? sck_enable & d_sck       :
               (cpol == 1'b1 && cpha == 1'b0)? ~(sck_enable & (~d_sck)) :
                sck_enable & d_sck;

//---------------------------tsck------------------------------
always @(posedge sysclk or negedge rst_x)
begin
    if(!rst_x)
        tsck <= 1'b0;
    else
        tsck <= c_sck;
end

//--------------------------tss---------------------------------
always @(posedge sysclk or negedge rst_x)
begin
    if(!rst_x)
        tss <= 1'b1;
    else
        tss <= i_ss;
end

assign sck = tsck;                                      // sck
assign ss = tss;                                        // tss

//--------------------------FSM---------------------------------
always @(posedge sysclk or rst_x)
begin
    if(!rst_x)
        state <= IDLE;
    else if(enable)
        state <= next_state;
    else
        state <= IDLE;
end

always @(*)
begin
//initial
clear_tx_data_ready = 1'b0;
shift_enable = 1'b0;
tx_shift_reg_load = 1'b0;
i_ss = 1'b0;
sck_enable = 1'b0;
load_rx_data_reg = 1'b0;
next_state = IDLE;
    case(state)
        IDLE:
        begin
            if(tx_data_ready == 1'b1 && i_sck == 1'b1 & d_sck == 1'b0)
            begin   
                clear_tx_data_ready = 1'b1;
                next_state = LOAD_SHIFT_REG;
            end
            else
                next_state = IDLE;
        end
        LOAD_SHIFT_REG:
        begin
            tx_shift_reg_load = 1'b1;
            if(d_sck == 1'b0)
            begin
                i_ss = 1'b0;
                if(i_sck == 1'b1)
                    next_state = D7;
                else
                    next_state = LOAD_SHIFT_REG;
            end
            else
                next_state = LOAD_SHIFT_REG;
        end
        D7:
        begin
            i_ss = 1'b0;
            sck_enable = 1'b1;
            if(i_sck == 1'b1 && d_sck == 1'b0)
            begin
                shift_enable = 1'b1;
                next_state = D6;
            end
            else
                next_state = D7;
        end
        D6:
        begin
            i_ss = 1'b0;
            sck_enable = 1'b1;
            if(i_sck == 1'b1 && d_sck == 1'b0)
            begin
                shift_enable = 1'b1;
                next_state = D5;
            end
            else
                next_state = D6;
        end
        D5:
        begin
            i_ss = 1'b0;
            sck_enable = 1'b1;
            if(i_sck == 1'b1 && d_sck == 1'b0)
            begin
                shift_enable = 1'b1;
                next_state = D4;
            end
            else
                next_state = D5;
        end
        D4:
        begin
            i_ss = 1'b0;
            sck_enable = 1'b1;
            if(i_sck == 1'b1 && d_sck == 1'b0)
            begin
                shift_enable = 1'b1;
                next_state = D3;
            end
            else
                next_state = D4;
        end
        D3:
        begin
            i_ss = 1'b0;
            sck_enable = 1'b1;
            if(i_sck == 1'b1 && d_sck == 1'b0)
            begin
                shift_enable = 1'b1;
                next_state = D2;
            end
            else
                next_state = D3;
        end
        D2:
        begin
            i_ss = 1'b0;
            sck_enable = 1'b1;
            if(i_sck == 1'b1 && d_sck == 1'b0)
            begin
                shift_enable = 1'b1;
                next_state = D1;
            end
            else
                next_state = D2;
        end
        D1:
        begin
            i_ss = 1'b0;
            sck_enable = 1'b1;
            if(i_sck == 1'b1 && d_sck == 1'b0)
            begin
                shift_enable = 1'b1;
                next_state = D0;
            end
            else
                next_state = D1;
        end
        D0:
        begin
            i_ss = 1'b0;
            sck_enable = 1'b1;
            if(i_sck == 1'b1 && d_sck == 1'b0)
            begin
                shift_enable = 1'b1;
                next_state = FINAL_CYCLE;
            end
            else
                next_state = D0;
        end
        FINAL_CYCLE:
            if(d_sck == 1'b1)
            begin
                i_ss = 1'b0;
                next_state = FINAL_CYCLE;
            end
            else
            begin
                load_rx_data_reg = 1'b1;
                i_ss = 1'b1;
                if(tx_data_ready == 1'b1 & i_sck == 1)
                begin
                    clear_tx_data_ready = 1'b1;
                    next_state = LOAD_SHIFT_REG;
                end
                else
                    next_state = IDLE;
            end
        default:
            next_state = 4'bxxxx;
    endcase
end

//--------------------------tx_shift_reg---------------------------------
always @(posedge sysclk or negedge rst_x)
begin
    if(rst_x == 1'b0)
    begin
        tx_shift_reg <= 8'b0000_0000;
        mosi <= 1'b0;
    end
    else
    begin
        if(tx_shift_reg_load)
            tx_shift_reg <= tx_data_reg;
        else if(shift_enable)
            tx_shift_reg[7:1] <= tx_shift_reg[6:0];
        mosi <= tx_shift_reg[7];
    end
end



//--------------------------rx_shift_reg---------------------------------
// rx_shift_enable
always @(*)
begin
    if(i_ss == 1'b0)
    begin
        if((cpol ^ cpha) == 1'b0)
            rx_shift_enable1 = c_sck & (~tsck);
        else
            rx_shift_enable1 = (~c_sck) & tsck;
    end
    else
        rx_shift_enable1 = 1'b0;
end

always @(posedge sysclk or negedge rst_x)
begin
    if(!rst_x)
        rx_shift_enable2 <= 1'b0;
    else
        rx_shift_enable2 <= rx_shift_enable1;
end
assign rx_shift_enable = (clocksel == 3'b000)? rx_shift_enable2 : rx_shift_enable1;

// rx_shift_reg
always @(posedge sysclk or negedge rst_x)
begin
    if(!rst_x)
    begin
        rx_shift_reg <= 8'b0000_0000;
    end
    else
    begin
        if(rx_shift_enable == 1'b1)
        begin
            rx_shift_reg[0] <= miso;
            rx_shift_reg[7:1] <= rx_shift_reg[6:0];
        end
        else
            rx_shift_reg <= rx_shift_reg;
    end
end

//------------------------Rx data register---------------------------------
reg [7:0]   rx_shift_mode_data;
reg         sck_d0;
always @(posedge sysclk or negedge rst_x)
begin
    if(!rst_x)
        sck_d0 <= 1'b0;
    else
        sck_d0 <= sck;
end

always @(posedge sysclk or negedge rst_x)
begin
    if(!rst_x)
        rx_shift_mode_data <= 1'b0;
    else if(enable == 1'b1)
    begin
        if(sck_d0 == 1 && sck== 1'b0)
            rx_shift_mode_data <= {rx_shift_mode_data[6:0], miso};
    end
end

always @(posedge sysclk or negedge rst_x)
begin
    if(!rst_x)
    begin
        rx_data_reg <= 8'b0000_0000;
    end
    else
    begin
        if(spi_rd_shift == 1'b0)
        begin
            if(load_rx_data_reg == 1'b1)
                rx_data_reg <= rx_shift_reg;
        end
        else
            rx_data_reg <= rx_shift_mode_data;
    end
end

//----------------------Generate rx data waiting flag----------------------
always @(posedge sysclk or negedge rst_x)
begin
    if(rst_x == 1'b0)
    begin
        rx_data_waiting <= 1'b0;
        rx_error_i <= 1'b0;
    end
    else
    begin
        if(rx_reg_re == 1'b1)
            rx_data_waiting <= 1'b0;
        else if(clear_error == 1'b1)
            rx_error_i <= 1'b0;
        else if(load_rx_data_reg == 1'b1)
        begin
            if(rx_data_waiting == 1'b1)
                rx_error_i <= 1'b1;
            else
                rx_data_waiting <= 1'b1;
        end
    end
end

assign rx_error = rx_error_i;
assign rx_data_ready = rx_data_waiting;

// -----------------------Generate tx_data ready flag------------------------
always @(posedge sysclk or negedge rst_x)
begin
    if(rst_x == 1'b0)
    begin
        tx_data_ready <= 1'b0;
        i_tx_reg_empty <= 1'b1;
        d_tx_shfit_reg_load <= 1'b0;
    end
    else
    begin
        if(tx_reg_we == 1'b1)
        begin
            tx_data_ready <= 1'b1;
            i_tx_reg_empty <= 1'b0;
        end
        else if(clear_tx_data_ready == 1'b1)
        begin
            clear_tx_data_ready <= 1'b0;
        end
        else if(tx_shift_reg_load == 1'b0 && d_tx_shfit_reg_load == 1'b1)
            i_tx_reg_empty <= 1'b1;
        d_tx_shfit_reg_load <= tx_shift_reg_load;
    end
end
assign tx_reg_empty = i_tx_reg_empty;

//-----------------------------Generate busy flag-------------------------
assign busy = (tss == 1'b0 | (~i_tx_reg_empty) == 1'b1 | state != IDLE)?
              1'b1 : 1'b0;
endmodule
