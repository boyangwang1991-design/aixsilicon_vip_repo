UV ?= uv
SEED ?= 1
WAIT ?= 0
export LOG_DIR
export BUILD_DIR
.PHONY: unit compile smoke vectors negative extensions full regression
unit compile smoke vectors negative extensions full:
	$(UV) run --no-sync python ../tools/run.py $@ --seed $(SEED) --wait $(WAIT)
regression: full
