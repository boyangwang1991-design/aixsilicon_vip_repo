UV ?= uv
SEED ?= 1
WAIT ?= 0
.PHONY: unit compile smoke vectors negative extensions full regression
unit:
	$(UV) run --no-sync python ../tools/run.py unit --seed $(SEED) --wait $(WAIT)
compile smoke vectors negative extensions full:
	$(UV) run --no-sync python ../tools/run.py $@ --seed $(SEED) --wait $(WAIT)
regression: full
