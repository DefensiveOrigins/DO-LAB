#!/bin/bash



# Log Entering Script
echo "Time: $(date). RunAtReboot Starting" >> /etc/DOAZLAB/DOAZLABLog


# If RunOnce trigger file (RunInstallToolsAtNextReboot) exists, run Install-Tools and delete trigger -- else do nothing except update log
if test -f /etc/DOAZLAB/RunInstallToolsAtNextReboot; then
    echo "Time: $(date). Triggering Tool Install." >> /etc/DOAZLAB/DOAZLABLog
    /bin/bash /etc/DOAZLAB/Install-Tools.sh
    echo "Time: $(date). Removing Install Trigger" >> /etc/DOAZLAB/DOAZLABLog
    rm /etc/DOAZLAB/RunInstallToolsAtNextReboot
fi

# Log Exiting Script
echo "Time: $(date). RunAtReboot Finishing" >> /etc/DOAZLAB/DOAZLABLog
