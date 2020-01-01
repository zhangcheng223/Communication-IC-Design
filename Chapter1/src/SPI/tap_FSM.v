// Tap FSM implementation
module tap_FSM #(
    // parameter
    parameter sync_mode = 1)
(
    // input
    input tck,
    input trst_n,
    input tms,
    input tdi,
    
    // output
    output byp_out,
    output updateIR,
    output reset_n,
    
    output reg clockDR,
    output reg updateDR,
    output reg clockIR,
    output reg tdo_en,
    output reg shiftDR,
    output reg shiftIR,

    output selectIR,
    output sync_capture_en,
    output sync_update_dr,
    output flag,
    output [15:0] tap_state
);

//---------------------Internal signal declaration----------------------
// wire
wire updateIR_s;
wire scan_out;
wire nxt_st_3;
wire nxt_st_4;

// reg
reg[15:0] state;
reg[15:0] next_state;
reg scan_out_a;
reg scan_out_s;
reg updateIR_a;
reg rst_n;
reg sel;

//--------------------------Localparam-----------------------------------
localparam TEST_LOGIC_RESET     = 16'h0001;
localparam RUN_TEST_IDLE        = 16'h0002;
localparam SELECT_DR_SCAN       = 16'h0004;
localparam CAPTURE_DR           = 16'h0008;
localparam SHIFT_DR             = 16'h0010;
localparam EXIT1_DR             = 16'h0020;
localparam PAUSE_DR             = 16'h0040;
localparam EXIT2_DR             = 16'h0080;
localparam UPDATE_DR            = 16'h0100;
localparam SELECT_IR_SCAN       = 16'h0200;
localparam CAPTURE_IR           = 16'h0400;     // flag
localparam SHIFT_IR             = 16'h0800;     // flag
localparam EXIT1_IR             = 16'h1000;
localparam PAUSE_IR             = 16'h2000;
localparam EXIT2_IR             = 16'h4000;
localparam UPDATE_IR            = 16'h8000;

//--------------------Sequential logic state transition------------------
always @(posedge tck or negedge trst_n)
begin
    if(!trst_n)
        state <= TEST_LOGIC_RESET;
    else
        state <= next_state;
end

//-------------------Combinational logic state decode---------------------
always @(*)
begin
    case(state)
        TEST_LOGIC_RESET:
            if(tms)
                next_state = TEST_LOGIC_RESET;
            else
                next_state = RUN_TEST_IDLE;
        RUN_TEST_IDLE:
            if(tms)
                next_state = SELECT_DR_SCAN;
            else
                next_state = RUN_TEST_IDLE;
        SELECT_DR_SCAN:
            if(tms)
                next_state = SELECT_IR_SCAN;
            else
                next_state = CAPTURE_DR;
        CAPTURE_DR:
            if(tms)
                next_state = EXIT1_DR;
            else
                next_state = SHIFT_DR;
        SHIFT_DR:
            if(tms)
                next_state = EXIT1_DR;
            else
                next_state = SHIFT_DR;
        EXIT1_DR:
            if(tms)
                next_state = UPDATE_DR;
            else
                next_state = PAUSE_DR;
        PAUSE_DR:
            if(tms)
                next_state = EXIT2_DR;
            else
                next_state = PAUSE_DR;
        EXIT2_DR:
            if(tms)
                next_state = UPDATE_DR;
            else
                next_state = CAPTURE_DR;
        UPDATE_DR:
            if(tms)
                next_state = SELECT_DR_SCAN;
            else
                next_state = RUN_TEST_IDLE;
        SELECT_IR_SCAN:
            if(tms)
                next_state = TEST_LOGIC_RESET;
            else
                next_state = CAPTURE_IR;
        CAPTURE_IR:
            if(tms)
                next_state = EXIT1_IR;
            else
                next_state = SHIFT_IR;
        SHIFT_IR:
            if(tms)
                next_state = EXIT1_IR;
            else
                next_state = SHIFT_IR;
        EXIT1_IR:
            if(tms)
                next_state = UPDATE_IR;
            else
                next_state = PAUSE_IR;
        PAUSE_IR:
            if(tms)
                next_state = EXIT2_IR;
            else
                next_state = PAUSE_IR;
        EXIT2_IR:
            if(tms)
                next_state = UPDATE_IR;
            else
                next_state = SHIFT_IR;
        UPDATE_IR:
            if(tms)
                next_state = SELECT_DR_SCAN;
            else
                next_state = RUN_TEST_IDLE;
        default:
            next_state = 16'hxxxx;
    endcase
end

//-------------------------Combinational logic output-----------------------
assign flag = state[10] || state[11];
assign updateIR_s = (state == UPDATE_IR);
assign updateIR = sync_mode? updateIR_s: updateIR_a;
assign tap_state = state;
assign reset_n = rst_n & trst_n;
assign selectIR = (state == SHIFT_IR);
assign sync_capture_en = (shiftDR | (state == CAPTURE_DR) | (state == SHIFT_DR));
assign sync_update_dr = (state == UPDATE_DR);
assign scan_out = sel? scan_out_s : shiftDR & tdi;
assign nxt_st_3 = (state == SELECT_DR_SCAN) & ~tms;
assign nxt_st_4 = (state == CAPTURE_DR & ~tms) || (state == SHIFT_DR & ~tms); 
assign byp_out = sync_mode? scan_out_s : scan_out_a;

// clockDR/clockIR--posedge occurs at the posedge of tck
// updateDR/updateIR--posedge occurs at the negedge of tck
always @(tck or state)
begin
    if(!tck && (state == CAPTURE_DR || state == SHIFT_DR))
        clockDR = 1'b0;
    else
        clockDR = 1'b1;

    if(!tck && (state == UPDATE_DR))
        updateDR = 1'b1;
    else
        updateDR = 1'b0;

    if(!tck && (state == CAPTURE_IR || state == SHIFT_IR))
        clockIR = 1'b0;
    else
        clockIR = 1'b1;
    
    if(!tck && (state == UPDATE_IR))
        updateIR_a = 1'b1;
    else
        updateIR_a = 1'b0;
end

// tdo_en
always @(negedge tck)
begin
    if(state == SHIFT_IR || state == SHIFT_DR)
        tdo_en <= 1'b1;
    else
        tdo_en <= 1'b0;
end

// rst_n
always @(negedge tck)
begin
    if(state == TEST_LOGIC_RESET)
        rst_n <= 1'b1;
    else
        rst_n <= 1'b0;
end

// shiftDR
always @(negedge tck or negedge trst_n)
begin
    if(!trst_n)
        shiftDR <= 1'b0;
    else if(state == SHIFT_DR)
        shiftDR <= 1'b1;
    else
        shiftDR <= 1'b0;
end

// shiftIR
always @(negedge tck or negedge trst_n)
begin
    if(!trst_n)
        shiftIR <= 1'b0;
    else if(state == SHIFT_IR)
        shiftIR <= 1'b1;
    else
        shiftIR <= 1'b0;
end

// scana_out_a
always @(posedge clockDR)
begin
    scan_out_a <= shiftDR & tdi & ~(state == CAPTURE_DR);
end

// sel
always @(posedge tck or negedge trst_n)
begin
    if(!trst_n)
        sel <= 0;
    else
        sel <= ~(nxt_st_3 | nxt_st_4);
end

endmodule
