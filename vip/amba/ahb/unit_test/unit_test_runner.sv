// SPDX-License-Identifier: Apache-2.0
// Included in the unit top: one accumulator shared by all behavioral suites.
int checks=0,failures=0;
task check(string id,bit ok);
  checks++;
  if(!ok) begin failures++;$display("FAILED: %s",id);end
endtask
