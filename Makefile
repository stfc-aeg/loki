SHELL := /bin/bash

.PHONY: all os mostlyclean clean

all: os

hardware:
	$(MAKE) -C ${HWSW_PATH} hardware

software:
	$(MAKE) -C ${HWSW_PATH} software

os: hardware software
	$(MAKE) -C ${OS_PATH} all

mostlyclean:
	$(info mostlycleaning HW/SW files)
	$(MAKE) -C ${HWSW_PATH} mostlyclean
	$(info mostlycleaning OS image files)
	$(MAKE) -C ${OS_PATH} mostlyclean

clean:
	$(info cleaning HW/SW files)
	$(MAKE) -C ${HWSW_PATH} clean
	$(info cleaning OS image files)
	$(MAKE) -C ${OS_PATH} clean

clobber:
	$(info clobbering HW/SW files)
	$(MAKE) -C ${HWSW_PATH} clean
	$(info cleaning OS image files)
	$(MAKE) -C ${OS_PATH} clean
