import rv32i_types::*;

module mp3(
    input clk,
    input rst,
    output logic mem_read,
    output logic mem_write,
    output logic [31:0] mem_addr,
    output logic [63:0] mem_wdata,
    input logic mem_resp,
    input logic [63:0] mem_rdata
);

/***********arbiter signals************/

//icache <--> arbiter
logic icache_read;
logic [255:0] icache_data;
logic [31:0] icache_addr;
logic icache_resp;

//dcache <--> arbiter
logic dcache_read;
logic dcache_write;
logic [255:0] dcache_wdata;
logic [255:0] dcache_rdata;
logic [31:0] dcache_addr;
logic dcache_resp;

//arbiter <--> cacheline_adapter
logic arbiter_resp;
logic [31:0] arb_mem_address;
logic arb_mem_read;
logic arb_mem_write;
logic [255:0] arb_mem_rdata;
logic [255:0] arb_mem_wdata; 

/********end arbiter signals************/

/**********icache signals***********/

//CPU Datapath <--> Cache
logic [31:0] icache_mem_address;
logic [31:0] icache_mem_rdata;
logic icache_mem_read;
logic icache_mem_resp;
logic icache_hit;

logic [3:0] icache_mem_byte_enable;
assign icache_mem_byte_enable = 4'b1111;
logic icache_mem_write, icache_write;
assign icache_mem_write = 1'b0;
logic [31:0] icache_mem_wdata;
assign icache_mem_wdata = 32'b0;
logic [255:0] icache_wdata;
	
/*********end icache signals********/

/**********dcache signals***********/

//CPU Datapath <--> Cache
logic [31:0] dcache_mem_address;
logic [31:0] dcache_mem_rdata;
logic [31:0] dcache_mem_wdata;
logic dcache_mem_read;
logic dcache_mem_write;
logic [3:0] dcache_mem_byte_enable;
logic dcache_mem_resp;
logic dcache_hit;

/**********end dcache signals********/

/*********l2 cache signals*********/

logic l2_resp;
logic [31:0] l2_mem_address;
logic l2_mem_read;
logic l2_mem_write;
logic [255:0] l2_mem_rdata;
logic [255:0] l2_mem_wdata; 

/*******end l2 cache signals*******/

cpu cpu(
    .clk,
    .rst,
    .inst_rdata(icache_mem_rdata),
    .inst_resp(icache_mem_resp),
    .data_resp(dcache_mem_resp),
	 .data_rdata(dcache_mem_rdata),
    .inst_read(icache_mem_read),
    .inst_addr(icache_mem_address),
    .data_read(dcache_mem_read),
    .data_write(dcache_mem_write),
    .data_mbe(dcache_mem_byte_enable),
    .data_addr(dcache_mem_address),
    .data_wdata(dcache_mem_wdata),
	 .icache_hit,
	 .dcache_hit
);

cache icache (
   .clk,
	.rst,
	
	//CPU Datapath <--> Cache
	.mem_address(icache_mem_address),
	.mem_rdata(icache_mem_rdata),
	.mem_wdata(icache_mem_wdata),
	.mem_read(icache_mem_read),
	.mem_write(icache_mem_write),
	.mem_byte_enable(icache_mem_byte_enable),
	.mem_resp(icache_mem_resp),
	.cache_hit(icache_hit),
	
	//Cache <--> Arbiter
	.pmem_address(icache_addr),
	.pmem_rdata(icache_data),
	.pmem_wdata(icache_wdata),
	.pmem_read(icache_read),
	.pmem_write(icache_write),
	.pmem_resp(icache_resp)
);

cache dcache (
   .clk,
	.rst,
	
	//CPU Datapath <--> Cache
	.mem_address(dcache_mem_address),
	.mem_rdata(dcache_mem_rdata),
	.mem_wdata(dcache_mem_wdata),
	.mem_read(dcache_mem_read),
	.mem_write(dcache_mem_write),
	.mem_byte_enable(dcache_mem_byte_enable),
	.mem_resp(dcache_mem_resp),
	.cache_hit(dcache_hit),
	
	//Cache <--> Arbiter
	.pmem_address(dcache_addr),
	.pmem_rdata(dcache_rdata),
	.pmem_wdata(dcache_wdata),
	.pmem_read(dcache_read),
	.pmem_write(dcache_write),
	.pmem_resp(dcache_resp)
);

arbiter arbiter (
    .clk,
    .rst,

    //icache <--> arbiter
    .icache_read,
    .icache_data(icache_data),
    .icache_addr,
    .icache_resp(icache_resp),

    //dcache <--> arbiter
    .dcache_read,
    .dcache_write,
    .dcache_wdata,
    .dcache_rdata(dcache_rdata),
    .dcache_addr,
    .dcache_resp(dcache_resp),

    //arbiter <--> l2_cache
    .arbiter_resp,
    .arb_mem_address_buf(arb_mem_address),
    .arb_mem_read_buf(arb_mem_read),
    .arb_mem_write_buf(arb_mem_write),
    .arb_mem_rdata,
    .arb_mem_wdata_buf(arb_mem_wdata)  
);
 
l2_cache l2_cache (
	 .clk,
	 .rst,
	
	 //Arbiter <--> Cache
	 .mem_address(arb_mem_address),
	 .mem_rdata(arb_mem_rdata),
	 .mem_wdata(arb_mem_wdata),
	 .mem_read(arb_mem_read),
	 .mem_write(arb_mem_write),
	 .mem_resp(arbiter_resp),
	
	 //Cache <--> Cacheline Adaptor
	 .pmem_address(l2_mem_address),
	 .pmem_rdata(l2_mem_rdata),
	 .pmem_wdata(l2_mem_wdata),
	 .pmem_read(l2_mem_read),
	 .pmem_write(l2_mem_write),
	 .pmem_resp(l2_resp)
);

cacheline_adaptor cacheline_adaptor (
    .clk,
    .reset(rst),

    // Port to LLC (Lowest Level Cache)
    .line_i(l2_mem_wdata),
    .line_o(l2_mem_rdata),
    .address_i(l2_mem_address),
    .read_i(l2_mem_read),
    .write_i(l2_mem_write),
    .resp_o(l2_resp),

    // Port to memory
    .burst_i(mem_rdata),
    .burst_o(mem_wdata),
    .address_o(mem_addr),
    .read_o(mem_read),
    .write_o(mem_write),
    .resp_i(mem_resp)
);

endmodule : mp3