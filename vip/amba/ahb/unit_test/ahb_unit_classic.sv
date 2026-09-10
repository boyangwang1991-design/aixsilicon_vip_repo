// SPDX-License-Identifier: Apache-2.0
task classic_checks();
  ahb_classic_retry_policy policy;ahb_item request,next_try;
  policy=new();request=new();request.response=2;
  check("classic_retry",policy.can_retry(request,2));next_try=policy.retry(request);
  check("classic_attempt",next_try.attempt==1 && request.attempt==0 && next_try.trans==2);
  request.response=3;policy.observe_response(request,2);check("classic_split_mask",!policy.can_retry(request,2));
  policy.release_split(16'h4);check("classic_split_release",policy.can_retry(request,2));
  request.attempt=16;check("classic_retry_limit",!policy.can_retry(request,2));
  policy.reset();check("classic_reset",policy.split_pending.num()==0);
endtask
