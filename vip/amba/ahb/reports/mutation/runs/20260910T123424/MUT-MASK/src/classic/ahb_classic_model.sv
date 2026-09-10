// SPDX-License-Identifier: Apache-2.0
class ahb_classic_retry_policy extends uvm_object;
  int unsigned max_attempts=16;
  bit split_pending[int unsigned];
  `uvm_object_utils(ahb_classic_retry_policy)
  function new(string name="ahb_classic_retry_policy");super.new(name);endfunction
  function void observe_response(ahb_item t,int unsigned owner);
    if(t.response==3) split_pending[owner]=1;
  endfunction
  function void release_split(bit[15:0] releases);
    for(int i=0;i<16;i++) if(releases[i]) split_pending.delete(i);
  endfunction
  function bit can_retry(ahb_item t,int unsigned owner);
    return (t.response inside {2,3}) && t.attempt<max_attempts && (!split_pending.exists(owner) || !split_pending[owner]);
  endfunction
  function ahb_item retry(ahb_item t);
    ahb_item request;request=t.duplicate();request.attempt++;request.trans=2;request.lifecycle=REQUESTED;request.status=OKAY;request.response=0;request.waits=0;return request;
  endfunction
  function void reset();split_pending.delete();endfunction
endclass
