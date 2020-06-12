module cacheline_adaptor
(
    input clk,
    input reset,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

logic[31:0] address, ta;
assign address_o = address;
assign ta = address;

//Burst Read
logic [63:0] burst1_o, burst2_o, burst3_o, burst4_o, tb1, tb2, tb3, tb4;
assign line_o = {burst4_o,burst3_o,burst2_o,burst1_o};
assign tb1 = burst1_o;
assign tb2 = burst2_o;
assign tb3 = burst3_o;
assign tb4 = burst4_o;

//Burst Write
logic [63:0] burst1_i, burst2_i, burst3_i, burst4_i;
assign burst1_i = line_i[63:0];
assign burst2_i = line_i[127:64];
assign burst3_i = line_i[191:128];
assign burst4_i = line_i[255:192];

function void set_defaults();
    read_o = 1'b0;
    write_o = 1'b0;
    resp_o = 1'b0;
endfunction

enum int unsigned {
     //List of states
     read_or_write,
	 read_begin,
     read1,
     read2,
     read3,
     read4,
     read_finish,
     write_begin,
     write1,
     write2,
     write3,
     write4,
     write_finish
} state, next_states;

always_comb
begin : state_actions
    set_defaults();
    unique case (state)
            read_or_write: begin
                address = 32'b0;
					 burst1_o = 64'b0;
					 burst2_o = 64'b0;
					 burst3_o = 64'b0;
					 burst4_o = 64'b0;
                burst_o = 64'b0;
            end

            read_begin: begin
					 burst1_o = 64'b0;
					 burst2_o = 64'b0;
					 burst3_o = 64'b0;
					 burst4_o = 64'b0;
					 burst_o = 64'b0;
                address = address_i;
                read_o = 1'b1;
            end

            read1: begin
                address = ta;
                burst1_o = burst_i;
                burst2_o = 64'b0;
					 burst3_o = 64'b0;
					 burst4_o = 64'b0;
                burst_o = 64'b0;
					 read_o = 1'b1;
            end

            read2: begin
                address = ta;
                burst2_o = burst_i;
                burst1_o = tb1;
                burst3_o = 64'b0;
					 burst4_o = 64'b0;
                burst_o = 64'b0;
					 read_o = 1'b1;
            end

            read3: begin
                address = ta;
                burst3_o = burst_i;
                burst1_o = tb1;
                burst2_o = tb2;
					 burst4_o = 64'b0;
                burst_o = 64'b0;
					 read_o = 1'b1;
            end

            read4: begin
                address = ta;
                burst4_o = burst_i;
                burst1_o = tb1;
                burst2_o = tb2;
                burst3_o = tb3;
                burst_o = 64'b0;
					 read_o = 1'b1;
            end

            read_finish: begin
                address = ta;
                burst1_o = tb1;
                burst2_o = tb2;
                burst3_o = tb3;
                burst4_o = tb4;
                burst_o = 64'b0;
					 read_o = 1'b0;
                if(resp_i == 1'b0) begin
                    resp_o = 1'b1;
                end
            end

            write_begin: begin
                burst1_o = 64'b0;
					 burst2_o = 64'b0;
					 burst3_o = 64'b0;
					 burst4_o = 64'b0;
                burst_o = 64'b0;
                address = address_i;
                write_o = 1'b1;
            end

            write1: begin
                address = ta;
                burst_o = burst1_i;
                burst1_o = 64'b0;
					 burst2_o = 64'b0;
					 burst3_o = 64'b0;
					 burst4_o = 64'b0;
					 write_o = 1'b1;
            end

            write2: begin
                address = ta;
                burst_o = burst2_i;
                burst1_o = 64'b0;
					 burst2_o = 64'b0;
					 burst3_o = 64'b0;
					 burst4_o = 64'b0;
					 write_o = 1'b1;
            end

            write3: begin
                address = ta;
                burst_o = burst3_i;
                burst1_o = 64'b0;
					 burst2_o = 64'b0;
					 burst3_o = 64'b0;
					 burst4_o = 64'b0;
					 write_o = 1'b1;
            end

            write4: begin
                address = ta;
                burst_o = burst4_i;
                burst1_o = 64'b0;
					 burst2_o = 64'b0;
					 burst3_o = 64'b0;
					 burst4_o = 64'b0;
					 write_o = 1'b1;
            end

            write_finish: begin
                address = ta;
                burst1_o = 64'b0;
					 burst2_o = 64'b0;
					 burst3_o = 64'b0;
					 burst4_o = 64'b0;
					 burst_o = 64'b0;
					 write_o = 1'b0;
                if(resp_i == 1'b0) begin
                    resp_o = 1'b1;
                end
            end
    endcase
end

always_comb 
begin : next_state_logic
	next_states = state;	
    unique case (state)
            read_or_write: begin
                if(read_i == 1'b1) next_states = read_begin;
                else if(write_i == 1'b1) next_states = write_begin;
					 else next_states = read_or_write;
            end

            read_begin:     next_states = read1;

            read1: begin
					 if(resp_i == 1'b1) next_states = read2;
					 else next_states = read1;
				end
				
            read2:          next_states = read3;

            read3:          next_states = read4;

            read4:          next_states = read_finish;

            read_finish: begin
					 if(resp_i == 1'b0) next_states = read_or_write;	
					 else next_states = read_finish;
				end
				
            write_begin:    next_states = write1;

            write1: begin
					 if(resp_i == 1'b1) next_states = write2;
					 else next_states = write1;
				end 
				
            write2:         next_states = write3;

            write3:         next_states = write4;

            write4:         next_states = write_finish;

            write_finish: begin
					 if(resp_i == 1'b0) next_states = read_or_write;
					 else next_states = write_finish;
				end
    endcase
end

always_ff @ (posedge clk) 
begin : next_state_assignment
    if (reset)
        state <= read_or_write;
    else
        state <= next_states;
end

endmodule : cacheline_adaptor