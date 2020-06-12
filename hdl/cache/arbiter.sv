module arbiter(
    input logic clk,
    input logic rst,

    //icache <--> arbiter
    input logic icache_read,
    output logic [255:0] icache_data,
    input logic [31:0] icache_addr,
    output logic icache_resp,

    //dcache <--> arbiter
    input logic dcache_read,
    input logic dcache_write,
    input logic [255:0] dcache_wdata,
    output logic [255:0] dcache_rdata,
    input logic [31:0] dcache_addr,
    output logic dcache_resp,

    //arbiter <--> cacheline_adapter
    input logic arbiter_resp,
    output logic [31:0] arb_mem_address_buf,
    output logic arb_mem_read_buf,
    output logic arb_mem_write_buf,
    input logic [255:0] arb_mem_rdata,
    output logic [255:0] arb_mem_wdata_buf
);

logic dcache_request;
assign dcache_request = dcache_read || dcache_write;

logic arb_mem_read, arb_mem_write;
logic [31:0] arb_mem_address;
logic [255:0] arb_mem_wdata;

always_ff @(posedge clk) begin
	if (rst) begin
		arb_mem_read_buf <= '0;
		arb_mem_write_buf <= '0;
		arb_mem_address_buf <= '0;
		arb_mem_wdata_buf <= '0;
	end else begin
		arb_mem_read_buf <= arb_mem_read;
		arb_mem_write_buf <= arb_mem_write;
		arb_mem_address_buf <= arb_mem_address;
		arb_mem_wdata_buf <= arb_mem_wdata;
	end
end

function void set_defaults();
	icache_data = 256'b0;
    icache_resp = 1'b0;
    dcache_rdata = 256'b0;
    dcache_resp = 1'b0;
    arb_mem_address = 32'b0;
    arb_mem_read = 1'b0;
    arb_mem_write = 1'b0;
    arb_mem_wdata = 256'b0;
endfunction

enum int unsigned {
    /* List of states */
    idle,
    instruction,
    data
} state, next_states;

always_comb
begin : state_actions
    /* Actions for each state */
    set_defaults();
    unique case (state)
        idle: ;
        
        instruction:
        begin    
            arb_mem_address = icache_addr;
            icache_resp = arbiter_resp;
            arb_mem_read = icache_read;
            arb_mem_write = 1'b0;
            icache_data = arb_mem_rdata;
        end
		  
        data:
        begin
            if (dcache_read == 1'd1) begin
                arb_mem_address = dcache_addr;
                dcache_resp = arbiter_resp;
                arb_mem_read = dcache_read;
                arb_mem_write = dcache_write;
                dcache_rdata = arb_mem_rdata;
					 arb_mem_wdata = dcache_wdata;
            end
            else if (dcache_write == 1'd1) begin
                arb_mem_address = dcache_addr;
                dcache_resp = arbiter_resp;
                arb_mem_write = dcache_write;
                arb_mem_read = dcache_read;
                arb_mem_wdata = dcache_wdata;
					 dcache_rdata = arb_mem_rdata;
            end
        end
    endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
    next_states = state;
    unique case (state)
        idle:
            begin
            if(dcache_request) next_states = data;
            else if(icache_read) next_states = instruction;
            else next_states = idle;
            end
				
        instruction:
            begin
            if(icache_resp) next_states = idle;//arbiter_resp
            else next_states = instruction;
            end
				
        data:
            begin
            if(dcache_resp) next_states = idle;//
            else next_states = data;
            end
    endcase
end

always_ff @(posedge clk)
    begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if (rst) begin
        state <= idle;
    end
    else begin 
        state <= next_states;
    end
end 
    
endmodule : arbiter