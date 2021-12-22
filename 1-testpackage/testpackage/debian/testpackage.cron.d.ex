#
# Regular cron jobs for the testpackage package
#
0 4	* * *	root	[ -x /usr/bin/testpackage_maintenance ] && /usr/bin/testpackage_maintenance
