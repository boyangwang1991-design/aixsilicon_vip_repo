// SPDX-License-Identifier: Apache-2.0
module ahb_unit_tb;
  import uvm_pkg::*;import ahb_types_pkg::*;import ahb_pkg::*;
  `include "unit_test_runner.sv"
  `include "ahb_unit_models.sv"
  `include "ahb_unit_parity.sv"
  `include "ahb_unit_classic.sv"
  initial begin
    ahb_config cfg;ahb_item t,c;ahb_memory mem;ahb_checker scb;ahb_cycle s;
    cfg=new();t=new();mem=new();scb=new();scb.cfg=cfg;
    check("default_config",cfg.validate()=="");
    cfg.dw=24;check("invalid_data_width",cfg.validate()!="");cfg.dw=32;
    cfg.strobe=1;check("lite_strobe_reject",cfg.validate()!="");cfg.strobe=0;
    for(int burst=2;burst<=6;burst+=2) begin
      int length;length=(burst==2)?4:(burst==4)?8:16;
      for(int start=0;start<length;start++) check($sformatf("wrap_%0d_%0d",burst,start),next_address('h100+4*start,2,3'(burst))==('h100+4*((start+1)%length)));
    end
    check("address_64",next_address(64'hffff_ffff_0000_0100,2,1)==64'hffff_ffff_0000_0104);
    check("lane_le",active_mask(2,1,4,LITTLE_ENDIAN)==12);
    check("lane_be",active_mask(2,1,4,BYTE_BIG_ENDIAN)==3);
    check("parity_tail10",parity_bytes(10'h301,10)==2);
    check("parity_tail17",parity_bytes(17'h10000,17)==3);
    t.addr=2;t.size=1;t.data='x;t.data[31:16]='h1234;
    c=t.duplicate();t.data=0;check("copy_four_state",c.data[31:16]=='h1234 && $isunknown(c.data[15:0]));
    t.addr=0;t.size=2;t.write=1;t.data='h12345678;t.strobe=15;t.status=ERROR;mem.commit(t,4,LITTLE_ENDIAN);
    check("error_no_write",!mem.valid(0));t.status=OKAY;mem.commit(t,4,LITTLE_ENDIAN);
    check("little_memory",mem.peek(0)=='h78 && mem.peek(3)=='h12);
    t.strobe=0;t.data=0;mem.commit(t,4,LITTLE_ENDIAN);check("zero_strobe",mem.peek(0)=='h78 && mem.bytes_written==4 && mem.writes==2);
    t.addr=2;t.size=0;t.strobe='1;t.data='h00ab0000;mem.commit(t,4,LITTLE_ENDIAN);check("inactive_strobe",mem.peek(2)=='hab && mem.peek(1)=='h56 && mem.peek(3)=='h12);
    t.addr=64'hffff000000000000;t.size=2;t.exclusive=1;t.write=0;t.strobe=15;mem.commit(t,4,LITTLE_ENDIAN,3);
    check("exclusive_reserve",mem.exclusive_match(t,3));
    mem.poke(t.addr+127,1);check("granule_invalidation",!mem.exclusive_match(t,3));
    t.write=1;t.data='hdeadbeef;mem.commit(t,4,LITTLE_ENDIAN,3);check("failed_exclusive_no_write",!mem.valid(t.addr));
    t.write=0;mem.commit(t,4,LITTLE_ENDIAN,3);t.write=1;mem.commit(t,4,LITTLE_ENDIAN,3);check("exclusive_success",mem.peek(t.addr)=='hef);
    mem.reset(1);check("warm_reset",mem.peek(0)=='h78 && mem.reservations.num()==0);mem.reset(0);check("cold_reset",!mem.valid(0));
    mem.init_policy=INIT_RANDOM;check("seeded_memory",mem.peek(42)===mem.peek(42));check("init_valid_separate",!mem.valid(42));
    model_checks();
    parity_checks();
    classic_checks();
    $display("UNIT_TEST_SUMMARY checks=%0d failures=%0d",checks,failures);
    if(failures) $fatal(1,"UNIT_TEST_FAIL");$display("UNIT_TEST_PASS");$finish;
  end
endmodule
