#!/bin/sh

cd /opt/hexitec-mhz-detector/
exec odin_server --config=./test/config/test_emulator.cfg &
echo "run finished" >> ./run.log
