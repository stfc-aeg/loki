#!/bin/sh

#start() {
#    # code to start app comes here 
#    cd /opt/hexitec-mhz-detector/
#    odin_server --config=./config/test_emulator.cfgexample: daemon program_name &
#}
#
#stop() {
#    # code to stop app comes here 
#    # example: killproc program_name
#}
#
#case "$1" in 
#    start)
#       start
#       ;;
#    stop)
#       stop
#       ;;
#    restart)
#       stop
#       start
#       ;;
#    status)
#       # code to check status of app comes here 
#       # example: status program_name
#       ;;
#    *)
#       echo "Usage: $0 {start|stop|status|restart}"
#esac
#
#exit 0

cd /opt/hexitec-mhz-detector/
exec odin_server --config=./test/config/test_emulator.cfg &
echo "run finished" >> ./run.log
