module cache_control (
	input clk,
	input rst,
	
	//<--> CPU
	input logic [31:0] mem_address,
	input logic mem_read,
	input logic mem_write,
	output logic mem_resp,
	
	//<--> Memory
	output logic [31:0] pmem_address,
	input logic pmem_resp,
	output logic pmem_read,
	output logic pmem_write,
	
	//<--> Cache Control
	output logic data_read,
	output logic m_data_read,
	output logic data_write,
	output logic datain_mux,
	output logic tag_load,
	output logic tag_read,
	output logic valid_load,
	output logic valid_read,
	output logic dirty_in,
	output logic dirty_mux,
	output logic dirty_read,
	output logic dirty_load,
	output logic lru_load,
	output logic lru_read,
	input logic hit,
	input logic dirty,
	input logic [23:0] tag_out
);

//Internal Control Signals
logic clean_miss, dirty_miss, resp, read_or_write;
logic [31:0] tag_address;

//Interal Assignments
assign clean_miss = !hit && !dirty && read_or_write;
assign dirty_miss = !hit && dirty && read_or_write; 
assign read_or_write = (mem_read || mem_write);
assign resp = hit && read_or_write;
assign tag_address = {tag_out, mem_address[7:0]};

enum int unsigned {
    /* List of states */
	 idle_compare,
	 write_back,
	 allocate
} state, next_states;


function void set_defaults();
	mem_resp = 1'b0;
	pmem_address = 32'b0;
	pmem_read = 1'b0;
	pmem_write = 1'b0;
	data_read = 1'b0;
	data_write = 1'b0;
	datain_mux = 1'b0;
	tag_load = 1'b0;
	tag_read = 1'b0;
	valid_load = 1'b0;
	valid_read = 1'b0;
	dirty_in = 1'b0;
	dirty_mux = 1'b0;
	dirty_read = 1'b0;
	dirty_load = 1'b0;
	lru_load = 1'b0;
	lru_read = 1'b0;
	m_data_read = 1'b0;
endfunction

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
	 unique case (state)
			idle_compare: begin
				data_write = mem_write;
				data_read = mem_read;
				dirty_read = 1'b1;
				dirty_load = mem_write;
				dirty_in = mem_write;
				lru_read = 1'b1;
				lru_load = 1'b1;
				tag_read = 1'b1;
				valid_read = 1'b1;
				mem_resp = resp;
			end
			
			write_back: begin
				dirty_load = 1'b1;
				dirty_mux = 1'b1;
				dirty_in = 1'b0;
				m_data_read = 1'b1;
				lru_read = 1'b1;
				tag_read = 1'b1;
				pmem_write = 1'b1;
				pmem_address = tag_address;
			end
			
			allocate: begin
				valid_load = 1'b1;
				datain_mux = pmem_resp;
				lru_read = 1'b1;
				pmem_read = 1'b1;
				pmem_address = mem_address;
				if (pmem_resp) tag_load = 1'b1;
			end
	endcase	
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	 next_states = state;
	 unique case (state)
			idle_compare: begin
				if (dirty_miss) next_states = write_back;
				else if (clean_miss) next_states = allocate;
				else next_states = idle_compare;
			end
			
			write_back: if (pmem_resp == 1'b1) next_states = allocate;
			
			allocate: if (pmem_resp == 1'b1) next_states = idle_compare;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 if (rst) begin
		state <= idle_compare;
	 end
	 else begin 
		state <= next_states;
	 end
end


endmodule : cache_control