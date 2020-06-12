module mp3_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);
/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP3

assign rvfi.commit = dut.cpu.WB_packet_out.commit; // Set high when a valid instruction is modifying regfile or PC
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

assign rvfi.inst = dut.cpu.WB_packet_out.inst;
assign rvfi.trap = dut.cpu.WB_packet_out.trap;
assign rvfi.rs1_addr = dut.cpu.WB_packet_out.rs1_addr;
assign rvfi.rs2_addr = dut.cpu.WB_packet_out.rs2_addr;
assign rvfi.rs1_rdata = dut.cpu.WB_packet_out.rs1_rdata;
assign rvfi.rs2_rdata = dut.cpu.WB_packet_out.rs2_rdata;
assign rvfi.load_regfile = dut.cpu.WB_packet_out.load_regfile;
assign rvfi.rd_addr = dut.cpu.WB_packet_out.rd_addr;
assign rvfi.rd_wdata = dut.cpu.WB_packet_out.rd_wdata;
assign rvfi.pc_rdata = dut.cpu.WB_packet_out.pc_rdata;
assign rvfi.pc_wdata = dut.cpu.WB_packet_out.pc_wdata;
// NOTE: dut.cpu.datapath.mem_addr should be byte or 4-byte aligned
//       memory address for all loads and stores (including fetches)
assign rvfi.mem_addr = dut.cpu.WB_packet_out.mem_addr;
assign rvfi.mem_rmask = dut.cpu.WB_packet_out.mem_rmask;
assign rvfi.mem_wmask = dut.cpu.WB_packet_out.mem_wmask;
assign rvfi.mem_rdata = dut.cpu.WB_packet_out.mem_rdata;
assign rvfi.mem_wdata = dut.cpu.WB_packet_out.mem_wdata;

assign rvfi.halt = dut.cpu.WB_packet_out.commit & (dut.cpu.WB_packet_out.pc_rdata == dut.cpu.WB_packet_out.pc_wdata);   // Set high when you detect an infinite loop

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2

//shadow memory input
assign itf.inst_read = dut.cpu.inst_read;
assign itf.inst_addr = dut.cpu.inst_addr; 
assign itf.inst_rdata= dut.cpu.inst_rdata;
assign itf.inst_resp = dut.cpu.inst_resp;
assign itf.data_read = dut.cpu.data_read;
assign itf.data_write= dut.cpu.data_write;
assign itf.data_addr = dut.cpu.data_addr;
assign itf.data_rdata= dut.cpu.data_rdata;
assign itf.data_wdata= dut.cpu.data_wdata;
assign itf.data_resp = dut.cpu.data_resp;
assign itf.data_mbe  = dut.cpu.data_mbe;

//shadow memory output
//inst_sm_error;
//data_sm_error;
/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = dut.cpu.ID.regfile.data;


/*********************** Instantiate your design here ************************/
mp3 dut(
    .clk(itf.clk),
    .rst(itf.rst),
    .mem_read(itf.mem_read),
    .mem_write(itf.mem_write),
    .mem_addr(itf.mem_addr),
    .mem_wdata(itf.mem_wdata),
    .mem_resp(itf.mem_resp),
    .mem_rdata(itf.mem_rdata)
);
/***************************** End Instantiation *****************************/

endmodule