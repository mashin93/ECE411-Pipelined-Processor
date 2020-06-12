module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	input rst,
	
	//CPU Datapath <--> Cache
	input logic [31:0] mem_address,
	output logic [31:0] mem_rdata,
	input logic [31:0] mem_wdata,
	input logic mem_read,
	input logic mem_write,
	input logic [3:0] mem_byte_enable,
	output logic mem_resp,
	output logic cache_hit,
	
	//Cache <--> Cacheline Adaptor/Main Memory
	output logic [31:0] pmem_address,
	input logic [255:0] pmem_rdata,
	output logic [255:0] pmem_wdata,
	output logic pmem_read,
	output logic pmem_write,
	input logic pmem_resp
);

//Bus Adapter
logic [255:0] mem_wdata256;
logic [255:0] mem_rdata256;
logic [31:0] mem_byte_enable256;

//Control
logic data_read, m_data_read, data_write, datain_mux, tag_read, tag_load, valid_load, valid_read, 
		dirty_in, dirty_mux, dirty_read, dirty_load, dirty, lru_load, lru_read, hit;
logic [23:0] tag_out;

assign cache_hit = hit;



cache_control control(.*);

cache_datapath datapath(.*);

bus_adapter bus_adapter(.*, .address(mem_address));

endmodule : cache