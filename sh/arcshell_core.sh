

# module_name="Core"
# module_about="Loads the core modules."
# module_version=1
# module_image="menu-4.png"
# copyright_notice="Copyright 2019 Arclogic Software"

if [[ -z "${arcHome}" || -z "${arcTmpDir}" || -z "${arcLogDir}" ]]; then
   echo "Something went wrong trying to load core ArcShell: arcshell_core.sh" 3>&1 1>&2 2>&3
   return
fi

. "${arcHome}/sh/arcshell_boot.sh" 
. "${arcHome}/sh/core/arcshell_alerts.sh"
. "${arcHome}/sh/core/arcshell_arc.sh"
. "${arcHome}/sh/core/arcshell_cache.sh"
. "${arcHome}/sh/core/arcshell_compiler.sh"
. "${arcHome}/sh/core/arcshell_config.sh"
. "${arcHome}/sh/core/arcshell_counters.sh"
. "${arcHome}/sh/core/arcshell_cron.sh"
. "${arcHome}/sh/core/arcshell_contact_groups.sh"
. "${arcHome}/sh/core/arcshell_dt.sh"
. "${arcHome}/sh/core/debug.sh"
. "${arcHome}/sh/core/arcshell_doceng.sh"
# . "${arcHome}/sh/core/arcshell_ext.sh"
. "${arcHome}/sh/core/arcshell_file.sh"
. "${arcHome}/sh/core/arcshell_flags.sh"
. "${arcHome}/sh/core/arcshell_gchart.sh"
. "${arcHome}/sh/core/arcshell_keywords.sh"
. "${arcHome}/sh/core/arcshell_lock.sh"
. "${arcHome}/sh/core/arcshell_logger.sh"
. "${arcHome}/sh/core/arcshell_logmon.sh"
. "${arcHome}/sh/core/arcshell_msg.sh"
. "${arcHome}/sh/core/arcshell_menu.sh"
. "${arcHome}/sh/core/arcshell_num.sh"
. "${arcHome}/sh/core/arcshell_obj.sh"
. "${arcHome}/sh/core/arcshell_os.sh"
. "${arcHome}/sh/core/arcshell_pkg.sh"
. "${arcHome}/sh/core/arcshell_rsync.sh"
. "${arcHome}/sh/core/arcshell_sch.sh"
. "${arcHome}/sh/core/arcshell_sendgrid.sh"
. "${arcHome}/sh/core/arcshell_sensor.sh"
. "${arcHome}/sh/core/arcshell_ssh_connections.sh"
. "${arcHome}/sh/core/arcshell_ssh.sh"
. "${arcHome}/sh/core/arcshell_stack.sh"
. "${arcHome}/sh/core/arcshell_stats.sh"
. "${arcHome}/sh/core/arcshell_stats_ext.sh"
. "${arcHome}/sh/core/arcshell_str.sh"
. "${arcHome}/sh/core/arcshell_tar.sh"
. "${arcHome}/sh/core/arcshell_timeout.sh"
. "${arcHome}/sh/core/arcshell_timer.sh"
. "${arcHome}/sh/core/unittest.sh"
. "${arcHome}/sh/core/arcshell_utl.sh"
. "${arcHome}/sh/core/arcshell_watch.sh"

PATH="$(utl_add_dirs_to_unix_path "${arcUserHome}/sh" "${arcHome}/sh" "${arcHome}/sh/core")"

