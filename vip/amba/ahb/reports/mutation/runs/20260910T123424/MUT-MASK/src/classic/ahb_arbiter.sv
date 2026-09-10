// SPDX-License-Identifier: Apache-2.0
// Reference arbitration policy, with independent address/data owner tracking.
// IHI0011A sections 3.11 and 3.12. Master 0 is the default IDLE-only master.
module ahb_arbiter #(int MASTERS=4,bit ROUND_ROBIN=1)(
  input logic HCLK,HRESETn,HREADY,
  input logic [1:0] HRESP,
  input logic [MASTERS-1:0] HBUSREQ,HLOCK,HSPLIT,
  input logic [1:0] HTRANS,
  output logic [MASTERS-1:0] HGRANT,
  output logic [3:0] HMASTER,DATA_MASTER,
  output logic HMASTLOCK,
  output logic [MASTERS-1:0] split_mask
);
  int next_master,rr_start;
  logic data_valid,data_locked;
  logic [MASTERS-1:0] effective_mask;
  always_comb begin
    effective_mask=split_mask & ~HSPLIT;
    if(data_valid && HRESP==3) effective_mask[DATA_MASTER]=1;
    next_master=0;
    if((HLOCK[HMASTER] || data_locked) && !effective_mask[HMASTER]) next_master=int'(HMASTER);
    else begin
      for(int offset=MASTERS-1;offset>=0;offset--) begin
        int candidate;candidate=ROUND_ROBIN?(rr_start+offset)%MASTERS:offset;
        if(candidate!=0 && HBUSREQ[candidate] && !effective_mask[candidate]) next_master=candidate;
      end
    end
    HGRANT='0;HGRANT[next_master]=1;
  end
  always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn) begin HMASTER<=0;DATA_MASTER<=0;HMASTLOCK<=0;split_mask<=0;rr_start<=1;data_valid<=0;data_locked<=0;end
    else begin
      split_mask<=effective_mask;
      if(HREADY) begin
        DATA_MASTER<=HMASTER;data_valid<=HTRANS[1];data_locked<=HMASTLOCK && HTRANS[1];
        HMASTER<=4'(next_master);HMASTLOCK<=HLOCK[next_master];
        if(next_master!=0) rr_start<=(next_master+1)%MASTERS;
      end
    end
  end
  initial if(MASTERS<2 || MASTERS>16) $fatal(1,"AHB arbiter master count");
endmodule
