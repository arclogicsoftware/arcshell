

# Collects the size of the ArcShell home directory every hour.
# ToDo: Set up alerting feature on % increase as well as hard threshold and bump threshold.
counters_set "arcshell,arcshell_home_size_mb,=$(file_get_dir_mb_size "${arcHome}")"

