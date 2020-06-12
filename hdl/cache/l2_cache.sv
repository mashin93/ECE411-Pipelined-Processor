module l2_cache #(
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
	
	//Arbiter <--> L2 Cache
	input logic [31:0] mem_address,
	output logic [255:0] mem_rdata,
	input logic [255:0] mem_wdata,
	input logic mem_read,
	input logic mem_write,
	output logic mem_resp,
	
	//Cache <--> Cacheline Adaptor/Main Memory
	output logic [31:0] pmem_address,
	input logic [255:0] pmem_rdata,
	output logic [255:0] pmem_wdata,
	output logic pmem_read,
	output logic pmem_write,
	input logic pmem_resp
);


//Control
logic data_read, m_data_read, data_write, datain_mux, tag_read, tag_load, valid_load, valid_read, 
		dirty_in, dirty_mux, dirty_read, dirty_load, dirty, lru_load, lru_read, hit;
logic [23:0] tag_out;





l2_cache_control control(.*);

l2_cache_datapath datapath(.*);

endmodule : l2_cache