// SPDX-License-Identifier: Apache-2.0
// Reference memory intentionally uses the same byte storage API but an independent instance.
// It must be updated from monitor completion events, as done by ahb_scoreboard.
typedef ahb_memory ahb_reference_model;
