// SPDX-License-Identifier: Apache-2.0
task parity_checks();
  ahb_checker pc;ahb_config cc;ahb_cycle s;int seen;
  cc=new();cc.profile=AHB5;cc.aw=17;cc.dw=32;cc.pw=7;cc.mw=4;cc.au=9;cc.du=9;cc.ru=3;cc.secure=1;cc.exclusive=1;cc.strobe=1;cc.parity=1;
  pc=new();pc.cfg=cc;
  for(int group_index=0;group_index<17;group_index++) begin
    string rule;
    s=new();s.reset_n=0;pc.sample(s);
    // Independent expected parity for all-zero fields except HPROT=3 and HTRANS=NONSEQ.
    s=new();s.reset_n=1;s.ready=1;s.readyout=1;s.sel=1;s.trans=2;s.resp=0;s.exokay=0;s.address.size=0;
    s.wdata=0;s.rdata=0;s.strb=0;s.wu=0;s.ru=0;s.bu=0;
    s.transchk=0;s.addrchk=7;s.ctrl1=1;s.ctrl2=1;s.protchk=1;s.readychk=0;s.readyoutchk=0;s.respchk=1;s.selchk=0;
    s.auchk=3;s.wuchk=3;s.ruchk=3;s.buchk=1;s.wdchk=15;s.rdchk=15;s.strbchk=1;
    // Arrange a data phase independently of address decoding for group validity tests.
    pc.pending=new();pc.pending.write=!(group_index inside {10,15});
    case(group_index)
      0:begin s.transchk=1;rule="AHB-CHECK-PAR-TRANS";end
      1:begin s.addrchk=3;rule="AHB-CHECK-PAR-ADDR";end
      2:begin s.ctrl1=0;rule="AHB-CHECK-PAR-CTRL1";end
      3:begin s.ctrl2=0;rule="AHB-CHECK-PAR-CTRL2";end
      4:begin s.protchk=0;rule="AHB-CHECK-PAR-PROT";end
      5:begin s.readychk=1;rule="AHB-CHECK-PAR-READY";end
      6:begin s.readyoutchk=1;rule="AHB-CHECK-PAR-READYOUT";end
      7:begin s.selchk=1;rule="AHB-CHECK-PAR-SEL";end
      8:begin s.respchk=0;rule="AHB-CHECK-PAR-RESP";end
      9:begin s.wdchk=14;rule="AHB-CHECK-PAR-WDATA";end
      10:begin s.rdchk=14;rule="AHB-CHECK-PAR-RDATA";end
      11:begin s.strbchk=0;rule="AHB-CHECK-PAR-STRB";end
      12:begin s.auchk=1;rule="AHB-CHECK-PAR-AUSER";end
      13:begin s.wuchk=1;rule="AHB-CHECK-PAR-WUSER";end
      14:begin s.buchk=0;rule="AHB-CHECK-PAR-BUSER";end
      15:begin s.ruchk=1;rule="AHB-CHECK-PAR-RUSER";end
      16:begin s.wdata=3;rule="none_even_fault";end
    endcase
    pc.sample(s);seen=0;foreach(pc.violations[i]) if(pc.violations[i].rule_id==rule) seen++;
    check($sformatf("parity_group_%0d_%s",group_index,rule),group_index==16?pc.violations.size()==0:(seen==1 && pc.violations.size()==1));
    // Invalid write data windows must not check WDATA/WUSER.
  end
endtask
