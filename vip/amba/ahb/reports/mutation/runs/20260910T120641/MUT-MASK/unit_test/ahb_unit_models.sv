// SPDX-License-Identifier: Apache-2.0
// Included inside ahb_unit_tb; independent expected values, not helper self-comparisons.
task model_checks();
  ahb_register_memory regmem;ahb_fifo_memory fifo;ahb_region_policy policy;ahb_region region;
  ahb_config config_obj;ahb_item req;int wait_count;bit[1:0] response;
  regmem=new();fifo=new();policy=new();config_obj=new();policy.cfg=config_obj;req=new();
  req.addr=0;req.size=2;req.write=1;req.data='h12345678;req.strobe=15;regmem.commit(req,4,LITTLE_ENDIAN);
  regmem.write_one_clear=1;req.data='h00340008;regmem.commit(req,4,LITTLE_ENDIAN);
  check("w1c",regmem.peek(0)=='h70 && regmem.peek(2)==0);
  regmem.read_clear=1;req.write=0;check("readclear_before_completion",(regmem.read_bus(req,4,LITTLE_ENDIAN) & 1024'hffffffff)==32'h12005670);
  regmem.commit(req,4,LITTLE_ENDIAN);check("readclear_commit_once",regmem.peek(0)==0);
  req.write=1;req.data='hfeedbeef;fifo.commit(req,4,LITTLE_ENDIAN);req.data=123;fifo.commit(req,4,LITTLE_ENDIAN);
  req.write=0;check("fifo_head",fifo.read_bus(req,4,LITTLE_ENDIAN)=='hfeedbeef);
  check("fifo_no_wait_side_effect",fifo.fifo.size()==2);fifo.commit(req,4,LITTLE_ENDIAN);check("fifo_pop_commit",fifo.fifo.size()==1 && fifo.read_bus(req,4,LITTLE_ENDIAN)==123);
  region=new();region.first='h100;region.last='h1ff;region.nonsecure_allowed=0;policy.regions.push_back(region);
  req.addr='h100;req.nonsecure=1;policy.select_response(req,wait_count,response);check("region_security_denied",response==1);
  req.nonsecure=0;policy.select_response(req,wait_count,response);check("region_security_allowed",response==0);
  req.addr='h200;policy.select_response(req,wait_count,response);check("region_hole",response==1);
  region=new();region.first='h180;region.last='h2ff;policy.regions.push_back(region);check("region_overlap_reject",policy.validate_regions()!="");region.priority_value=1;check("region_priority",policy.validate_regions()=="");
endtask
