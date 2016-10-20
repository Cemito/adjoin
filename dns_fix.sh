#!/bin/bash

cd /opt/likewise/bin

echo "Configuring Default login shell as /bin/bash"
/opt/pbis/bin/config LoginShellTemplate /bin/bash >/dev/null 2>&1

echo "Updating DNS and setting as daily cron job"
echo $'#!/bin/bash\nsudo /opt/pbis/bin/update-dns' > /etc/cron.daily/dns
chmod 755 /etc/cron.daily/dns
/opt/pbis/bin/update-dns