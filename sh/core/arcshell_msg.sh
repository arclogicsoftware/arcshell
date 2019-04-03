
# module_name="Messaging"
# module_about="Manages the routing and sending of messages."
# module_version=1
# module_image="smartphone-1.png"
# copyright_notice="Copyright 2019 Arclogic Software"

#ToDo: Instead of keeping redundant messages in the queue have option to keep first and last and count them perhaps?

_msgDir="${arcTmpDir}/_arcshell_msg"
mkdir -p "${_msgDir}/queues"

# ToDo: Need to implement 2 groups, one with queuing and one with no queuing or short queueing.

function test_file_setup {
   arcshell_mail_program="_fakeMailX"
   (
   cat <<EOF
group_emails='foo@bar.com'
group_hold=1
EOF
   ) > "${arcHome}/config/contact_groups/foo.cfg"
}

function __readmeMessaging {
   cat <<EOF

## Hidden Variables

| Variable | Description |
| --- | --- | 
| __messaging_max_text_lines | Maximum number of lines to include when sending a text. Defaults to 3. |
| __messaging_max_email_lines | Maximum number of lines to include when sending an email. Defaults to 9999. |

EOF

}

_msgUniqId_=

function __configArcShellMessaging {
   ! timer_exists "lastTextSent" && timer_create "lastTextSent"
   counters_set "messaging,messages_sent,+0"
   ${returnTrue} 
}

# ToDo: Add Slack configuration settings to msg_check function.

function msg_check {
   # Returns a bunch of information about the state of messaging configuration.
   # >>> msg_check
   ${arcRequireBoundVariables}
   log_terminal "Checking messaging configuration..."
   log_terminal "Note: Use '\${arcGlobalHome}/config/arcshell.cfg' to modify most settings."
   if [[ -n "${arcshell_admin_emails:-}" ]]; then
      log_terminal "'arcshell_admin_emails' is set to '${arcshell_admin_emails}'."
   else
      log_terminal "[!] 'arcshell_admin_emails' is not set."
   fi
   log_terminal "'arcshell_message_prefix' is set to '${arcshell_message_prefix:-}'."
   log_terminal "'arcshell_mail_program' is set to '${arcshell_mail_program}'."
   if ! str_is_word_in_list "${arcshell_mail_program}" "mail,mailx,sendgrid"; then
      log_terminal "[!] 'arcshell_mail_program' setting is not a supported option."
      log_terminal "[!] Supported options are 'mail', 'mailx', and 'sendgrid'."
   fi
   if ! boot_is_program_found "mailx" && [[ "${arcshell_mail_program:-'mailx'}" == "mailx" ]]; then
      log_terminal "[!] 'mailx' not found in '\${PATH}'."
   fi
   if ! boot_is_program_found "mail" && [[ "${arcshell_mail_program:-'mail'}" == "mail" ]]; then
      log_terminal "[!] 'mail' not found in '\${PATH}'."
   fi
   if [[ -z "${arcshell_sendgrid_api_key:-}" ]] && [[ "${arcshell_mail_program:-'sendgrid'}" == "sendgrid" ]] ; then
      log_terminal "[!] 'arcshell_sendgrid_api_key' is not set."
   fi
   if [[ -n "${arcshell_from_address:-}" ]]; then
      log_terminal "'arcshell_from_address' is set to '${arcshell_from_address:-}'."
   else
      log_terminal "[!] 'arcshell_from_address' is not defined."
      log_terminal "[!] This address will default to '${LOGNAME}@$(hostname)'."
   fi
   log_terminal "'arcshell_default_keyword' is set to '${arcshell_default_keyword:-}'."
   if ! keyword_does_exist "${arcshell_default_keyword:-}"; then
      log_terminal "[!] The default keyword does not exist."
   fi
   if (( $(contact_groups_enabled_count) == 0 )); then
      log_terminal "[!] There are no enabled contact groups. There should always be one enabled group."
   fi
   log_terminal "There are $(_msgReturnQueueItemTypeCount 'emailQueue') items in the email queue."
   log_terminal "There are $(_msgReturnQueueItemTypeCount 'textQueue') items in the text queue."
   log_terminal "There are $(contact_groups_list | num_line_count) contact groups."
   log_terminal "There are $(contact_groups_enabled_count) available contact groups."
}  

function msg_reset_all_queues {
   # Removes all messages from all queues for all groups.
   # >>> msg_reset_all_queues
   ${arcRequireBoundVariables}
   find "${_msgDir}/queues" -type f -exec rm {} \;
   log_terminal "Messages have been reset."
}

function _msgReturnQueueItemTypeCount {
   # Return total number of items in all queues of the provided type.
   # >>> _msgReturnQueueItemTypeCount "queue_type"
   queue_type="${1}"
   grep "^id=[0-9]*,[0-9]*" "${_msgDir}/queues/"*"${queue_type}" 2> /dev/null | num_line_count
}

function _msgPurgeInvalidContactGroups {
   # Removes queues for contact groups that no longer exist.
   # >>> _msgPurgeInvalidContactGroups
   ${arcRequireBoundVariables}
   typeset g
   while read g; do
      if ! contact_group_exists "${g}"; then
         find "${_msgDir}/queues" -type f -name "${g}.*" -exec rm {} \;
      fi
   done < <(ls "${_msgDir}/queues" | awk -F"." '{print $1}' | sort -u)
}

function msg_check_message_queues {
   # This function should be called periodically from the scheduler.
   # >>> msg_check_message_queues
   ${arcRequireBoundVariables}
   typeset queued_emails_count queued_texts_count
   debug1 "Checking message queues..."
   _msgPurgeInvalidContactGroups
   queued_emails_count=$(_msgReturnQueueItemTypeCount "emailQueue")
   queued_texts_count=$(_msgReturnQueueItemTypeCount "textQueue")
   counters_set "messaging,checked_queues,+1"
   counters_set "messaging,emails_in_queue,=${queued_emails_count}"
   counters_set "messaging,texts_in_queue,=${queued_texts_count}"
   if _msgCheckQueues; then
      ${returnTrue} 
   else 
      ${returnFalse} 
   fi
}

function send_message {
   # Create a message using standard input and route to the appropriate queues.
   # >>> send_message [-${keyword}] [-groups,-g "X,..."] [-now] ["subject"]
   # -${keyword}: A valid mail message/alerting keyword.
   # -groups: List of groups to route the message to. Groups override
   # -now: Send message and skip queuing.
   # subject: Message subject.
   ${arcRequireBoundVariables}
   debug3 "send_message: $*"
   typeset tmpFile keyword groups group_name subject send_now event_counter_char
   groups=
   subject="ArcShell Message"
   keyword="${arcshell_default_keyword:-"log"}"
   send_now=0
   sleep 1
   _msgUniqId_="$(dt_epoch),$$"
   while (( $# > 0)); do
      if keyword_does_exist "${1:1}"; then
         keyword="${1:1}"
      else
         case "${1}" in
            "-keyword"|"-k") shift; keyword="${1}"         ;;
            "-group"|"-g"|"-groups") shift; groups="${1}"  ;;
            "-now"|"-n") send_now=1 ;;
            *) break ;;
         esac
      fi
      shift
   done
   utl_raise_invalid_option "send_message" "(( $# <= 1 ))" "$*" && ${returnFalse}
   keyword_raise_not_found "${keyword}" && ${returnFalse} 
   (( $# == 1 )) && subject="${1}"
   if [[ -n "${arcshell_message_prefix:-}" ]]; then
      subject="${arcshell_message_prefix:-} ${subject}"
   fi
   tmpFile="$(mktempf)"
   cat > "${tmpFile}.1"
   if [[ ! -s "${tmpFile}.1" ]]; then
      rm "${tmpFile}"*
      ${returnFalse} 
   fi

   # Make sure the message gets logged even if it doesn't get sent (below).
   cat "${tmpFile}" | log_message -stdin -logkey "${keyword}" "${subject}"

   # We need to get at least one group to send a message to.
   if [[ -z "${groups:-}" ]]; then
      groups="$(contact_groups_list_default | str_to_csv ",")"
   fi
   if [[ -z "${groups:-}" ]]; then
      # Error here is debatable. It is possible to configure with no available groups. We will assume it is intentional.
      # log_error -2 -logkey "messaging" "There are no available contact groups to send this message to."
      ${returnFalse} 
   fi

   eval "$(keyword_load "${keyword}")"
   [[ -n "${event_counter_char:-}" ]] && event_counter_add_event "messaging" "${event_counter_char}"
   
   _msgReturnMessageBanner "${subject}" "${keyword}" "${groups}" > "${tmpFile}"
   cat "${tmpFile}.1" >> "${tmpFile}" && rm "${tmpFile}.1"
   while read group_name; do

      # Load keyword every time even through it does not change.
      # Why? One of the values might be over-ridden in a contact group.
      eval "$(keyword_load "${keyword}")"
      eval "$(contact_group_load "${group_name}")"

      # Messages can only be sent to disabled groups if -now has been provided.
      if ! contact_group_is_enabled "${group_name}" && ! (( ${send_now} )); then
         continue
      fi

      if is_truthy "${send_slack:-0}" && [[ -n "${arcshell_app_slack_webhook:-}" ]]; then
         cat "${tmpFile}" | send_slack -stdin
      fi

      # Messages are sent right away when no queuing or the -now option provided.
      if (( ${send_now} )) || ! _msgIsQueuingEnabled "${group_name}"; then
         cat "${tmpFile}" | _msgSendNow "${keyword}" "${group_name}" "${subject}"
         log_terminal "Sending message to '${group_name}'."
      else
         # Message will be queued for the group.
         _msgAppendToQueues "${group_name}" "${tmpFile}" "${keyword}" 
         log_terminal "Queuing message for '${group_name}'."
      fi
      
   done < <(echo "${groups}" | str_split_line -stdin ",")
   rm "${tmpFile}" 2> /dev/null
   ${returnTrue} 
}

function _msgSendNow {
   # Used to bypass all buffering and send a message immediately. 
   # > Messages are sent to groups, even when disabled, when the send_message -now option is used.
   # >>> _msgSendNow "keyword" "group_name" "subject" 
   ${arcRequireBoundVariables}
   debug3 "_msgSendNow: $*"
   typeset keyword group_name subject tmpFile
   keyword="${1}"
   group_name="${2}"
   subject="${3}"
   eval "$(keyword_load "${keyword}")"
   tmpFile="$(mktempf)"
   cat > "${tmpFile}"
   eval "$(contact_group_load "${group_name}")"
   if is_truthy ${send_text:-0} && [[ -n "${group_texts:-}" ]]; then
      cat "${tmpFile}" | utl_remove_blank_lines -stdin | \
         _msgSendMail "${group_texts}" "${subject}" "${__messaging_max_text_lines:-3}"
      send_email=1
      sleep 60
   fi
   [[ -z "${group_emails:-}" ]] && group_emails="${arcshell_admin_emails:-}"
   utl_raise_empty_var "'group_emails' and 'arcshell_admin_emails' are not set." "${group_emails}" && ${returnFalse}
   if is_truthy ${send_email:-0}; then
      cat "${tmpFile}" | _msgSendMail "${group_emails}" "${subject}" "${__messaging_max_email_lines:-9999}"
   fi
   rm "${tmpFile}"
   ${returnTrue} 
}

function test__msgSendNow {
   echo "foo" | _msgSendNow "email" "admins" "_msgSendNow Test" | \
      assert_match "_msgSendNow Test"
}

function _msgSendMail {
   # Sends a message using the defined mail program. Message is read from standard in.
   # >>> _msgSendMail "to" "subject" "max_lines"
   # to: Comma separated list of email addresses.
   # subject: Subject text.
   # max_lines: Maximum number of lines to send.
   ${arcRequireBoundVariables}
   debug3 "_msgSendMail: $*"
   typeset to subject from_address 
   utl_raise_invalid_option "_msgSendMail" "(( $# == 3 ))" && ${returnFalse} 
   to="${1}"
   subject="${2}"
   from_address="${arcshell_from_address:-${LOGNAME}@$(hostname)}"
   if [[ "${arcshell_mail_program:-"mail"}" == "mail" ]]; then
      debug3 "mail -a 'From: ${from_address}' -s '${subject}' '${to}'"
      cat | mail -a "From: " -s "${subject}" "${to}"
   elif [[ "${arcshell_mail_program:-}" == "mailx" ]]; then
      cat | mailx -r "${from_address}" -s "${subject}" "${to}"
   elif [[ "${arcshell_mail_program:-}" == "_fakeMailX" ]]; then
      cat | _fakeMailX -s "${subject}" "${to}" 
   elif [[ "${arcshell_mail_program:-}" == "sendgrid" ]]; then
      cat | sendgrid_send -a "${from_address}" -s "${subject}" "${to}"
   else
      log_error -2 -logkey "messaging" "Mail program is not recognized."
      ${returnFalse} 
   fi 
   counters_set "messaging,messages_sent,+1"
   counters_set "messaging,messages_sent_to_${to},+1"
   log_boring -logkey "arcshell" -tags "messaging,send" "Sending email with subject '${subject}' to '${to}'."
   ${returnTrue} 
}

function _fakeMailX {
   # Read standard input and sends as an email message to our fake mail program.
   # >>> _fakeMailX -s "subject" "to"
   # subject: Subject text.
   # to: Email addresses of recipients. Comma separated.
   ${arcRequireBoundVariables}
   typeset to subject
   shift 
   utl_raise_invalid_option "_fakeMailX" "(( $# == 2 ))" && ${returnFalse} 
   subject="${1}"
   to="${2}"
   echo "Sending email to '${to}' with subject of '${subject}'..."
   cat 3>&1 1>&2 2>&3
   ${returnTrue} 
}

function test__fakeMailX {
   echo "foo" | _fakeMailX -s "Message for foo and bar." "foo@bar.com,bar@foo.com" && pass_test || fail_test 
}

function _msgDeleteEmails {
   # Delete any existing emails for a group.
   # >>> _msgDeleteEmails "group_name"
   ${arcRequireBoundVariables}
   typeset group_name  
   group_name="${1}"
   _msgDeleteQueue "${group_name}" "emailQueue"
}

function _msgDeleteTexts {
   # Delete any existing emails for a group.
   # >>> _msgDeleteTexts "group_name"
   ${arcRequireBoundVariables}
   typeset group_name  
   group_name="${1}"
   _msgDeleteQueue "${group_name}" "textQueue"
}

function _msgDeleteQueue {
   # Delete all of the messages from a queue.
   # >>> _msgDeleteQueue "group_name" "queue_name"
   ${arcRequireBoundVariables}
   typeset group_name queue_name 
   group_name="${1}"
   queue_name="${2}"
   _groupsRaiseGroupNotFound "${group_name}" && ${returnFalse} 
   cp /dev/null "${_msgDir}/queues/${group_name}.${queue_name}"
   ${returnTrue} 
}

function _msgReturnMessageBanner {
   #
   # >>> _msgReturnMessageBanner "subject" "keyword" "groups"
   ${arcRequireBoundVariables}
   typeset subject keyword groups 
   subject="${1}"
   keyword="${2}"
   groups="${3}"

      cat <<EOF
-------------------------------------------------------------------------------
${subject}
$(date)
node=${arcNode} | keyword=${keyword} | groups=${groups}
id=${_msgUniqId_}
-------------------------------------------------------------------------------
EOF
}

function _msgAppendToQueues {
   # Generates a message for each group in the queues which the keyword maps to.
   # >>> _msgAppendToQueues "group_name" "message_file" "keyword"
   ${arcRequireBoundVariables}
   debug3 "_msgAppendToQueues: $*"
   typeset group_name message_file keyword
   group_name="${1}"
   message_file="${2}"
   keyword="${3}"
   eval "$(keyword_load "${keyword}")"
   if is_truthy "${send_text:-0}"; then
      _msgAppendToTextQueue "${message_file}" "${group_name}" || send_email=1
   fi
   if is_truthy "${send_email:-0}"; then
      _msgAppendToEmailQueue "${message_file}" "${group_name}"
   fi
}

function _msgAppendToTextQueue {
   # Write message to a group's text queue if configured and enabled.
   # >>> _msgAppendToTextQueue "message_file" "group_name"
   ${arcRequireBoundVariables}
   debug3 "_msgAppendToTextQueue: $*"
   typeset message_file group_name 
   message_file="${1}"
   group_name="${2}"
   eval "$(contact_group_load "${group_name}")"
   is_truthy "${group_disable_texts:-0}" && ${returnFalse} 
   [[ -z "${group_texts:-}" ]]           && ${returnFalse} 
   _msgLockMessages
   cat "${message_file}" >> "${_msgDir}/queues/${group_name}.textQueue"
   _msgUnlockMessages
   ${returnTrue} 
}

function test__msgAppendToTextQueue {
   :
}

function _msgAppendToEmailQueue {
   # Write message to a group's email queue.
   # >>> _msgAppendToEmailQueue "message_file" "group_name"
   ${arcRequireBoundVariables}
   debug3 "_msgAppendToEmailQueue: $*"
   typeset message_file group_name 
   message_file="${1}"
   group_name="${2}"
   eval "$(contact_group_load "${group_name}")"
   if [[ -z "${group_emails:-}" && -z "${arcshell_admin_emails:-}" ]]; then
      ${returnFalse} 
   fi
   _msgLockMessages
   cat "${message_file}" >> "${_msgDir}/queues/${group_name}.emailQueue"
   _msgUnlockMessages
   ${returnTrue} 
}

function test__msgAppendToEmailQueue {
   :
}

function _msgWaitForLock {
   # Waits up to 60 seconds if the file which indicates message delivery is running exists.
   # >>> _msgWaitForLock [seconds]
   # seconds: Number of seconds to wait. Defaults to 60.
   ${arcRequireBoundVariables}
   debug3 "_msgWaitForLock: $*"
   typeset file x seconds
   seconds=${1:-60}
   file="${_msgDir}/.lock"
   [[ ! -f "${file}" ]] && ${returnTrue} 
   x=0
   while (( ${x} < ${seconds} )); do
      ((x=x+1))
      sleep 1
      [[ ! -f "${file}" ]] && ${returnTrue} 
   done
   _msgUnlockMessages
   log_error -2 -logkey "messaging" "Removed lock by force after ${seconds} seconds."
   ${returnTrue} 
}

function test__msgWaitForLock {
   _msgLockMessages 
   assert_banner "An error is expected here..."
   _msgWaitForLock 5 && pass_test || fail_test 
}

function _msgLockMessages {
   # Sets the mail lock. Lock is forced after 60 seconds if not available.
   # >>> _msgLockMessages
   ${arcRequireBoundVariables}
   debug3 "_msgLockMessages: $*"
   _msgWaitForLock
   touch "${_msgDir}/.lock"
   ${returnTrue} 
}

function test__msgLockMessages {
   _msgUnlockMessages && pass_test || fail_test 
   echo "${_msgDir}/.lock" | assert ! -f 
   _msgLockMessages && pass_test || fail_test 
   echo "${_msgDir}/.lock" | assert -f 
   _msgUnlockMessages && pass_test || fail_test 
}

function _msgUnlockMessages {
   # Remove the mail lock.
   # >>> _msgUnlockMessages
   ${arcRequireBoundVariables}
   debug3 "_msgUnlockMessages: $*"
   rm "${_msgDir}/.lock" 2> /dev/null
   ${returnTrue} 
}

function test__msgUnlockMessages {
   _msgLockMessages && pass_test || fail_test 
   echo "${_msgDir}/.lock" | assert -f 
   _msgUnlockMessages && pass_test || fail_test 
   echo "${_msgDir}/.lock" | assert ! -f 
}

function _msgAreEmailsReadyToSend {
   # Return true if emails need to be sent for the group.
   # >>> _msgAreEmailsReadyToSend "group_name"
   ${arcRequireBoundVariables}
   utl_raise_invalid_option "_msgAreEmailsReadyToSend" "(( $# == 1 ))" "$*" && ${returnFalse} 
   debug3 "_msgAreEmailsReadyToSend: $*"
   typeset group_name queued_seconds idle_seconds queue_size group_hold group_emails
   group_name="${1}"
   eval "$(contact_group_load "${group_name}")"
   is_truthy "${group_hold:-0}" && ${returnFalse} 
   touch "${_msgDir}/queues/${group_name}.emailQueue"
   queue_size="$(_msgReturnQueuedItemsCount "${group_name}" "emailQueue")"
   queued_seconds=$(_msgReturnMaxQueuedSeconds "${group_name}" "emailQueue")
   idle_seconds=$(_msgReturnMinQueuedSeconds "${group_name}" "emailQueue")
   log_data -logkey "messaging" -tags "${group_name}" \
      "group_name='${group_name}';queue_type='email';queue_size=${queue_size};queue_seconds=${queued_seconds};idle_seconds=${idle_seconds}"
   ! (( ${queue_size} )) && ${returnFalse} 
   if (( ${queue_size} > ${group_max_email_queue_count:-0} )) || \
      (( ${queued_seconds} > ${group_max_email_queue_seconds:-0} )) || \
      (( ${idle_seconds} > ${group_max_email_queue_idle_seconds:-0} )); then
      ${returnTrue}  
   else
      ${returnFalse} 
   fi
}

function test__msgAreEmailsReadyToSend {
   _msgDeleteQueue "foo" "emailQueue"
   echo "bar" | send_message -email -group "foo" "Bar"
   _msgReturnQueuedItemsCount "foo" "emailQueue" | assert "=1" "Email queue should contain 1 item."
   assert_sleep 5
   _msgAreEmailsReadyToSend "foo" && pass_test || fail_test 
}

function _msgIsQueuingEnabled {
   # Return true if any queuing attribute is > than zero.
   # >>> _msgIsQueuingEnabled "group_name"
   ${arcRequireBoundVariables}
   typeset group_name 
   group_name="${1}"
   eval "$(contact_group_load "${group_name}")"
   if (( ${group_max_email_queue_count:-0} > 0 )) || \
      (( ${group_max_email_queue_seconds:-0} > 0 )) || \
      (( ${group_max_email_queue_idle_seconds:-0} > 0 )) || \
      (( ${group_max_text_queue_seconds:-0} > 0 )) || \
      is_truthy "${group_hold:-0}"; then
      ${returnTrue} 
   else
      ${returnFalse} 
   fi
}

function _msgAreTextsReadyToSend {
   # Return true if texts need to be sent for the group.
   # >>> _msgAreTextsReadyToSend "group_name"
   ${arcRequireBoundVariables}
   debug3 "_msgAreTextsReadyToSend: $*"
   typeset group_name queued_seconds queue_size group_hold
   group_name="${1}"
   _groupsRaiseGroupNotFound "${group_name}" && ${returnFalse} 
   eval "$(contact_group_load "${group_name}")"
   is_truthy "${group_hold:-0}" && ${returnFalse} 
   touch "${_msgDir}/queues/${group_name}.textQueue"
   queue_size="$(_msgReturnQueuedItemsCount "${group_name}" "textQueue")"
   queued_seconds=$(_msgReturnMaxQueuedSeconds "${group_name}" "textQueue")
   log_data -logkey "messaging" -tags "${group_name}" \
      "group_name='${group_name}';queue_type='text';queue_size=${queue_size};queued_seconds=${queued_seconds}"
   ! (( ${queue_size} )) && ${returnFalse} 
   if (( ${queued_seconds} > ${group_max_text_queue_seconds:-0} )); then
      ${returnTrue} 
   else 
      ${returnFalse} 
   fi
}

function _msgReturnQueuedItemsCount {
   # Return the number of items in a queue.
   # >>> _msgReturnQueuedItemsCount "group_name" "queue_name"
   ${arcRequireBoundVariables}
   typeset group_name queue_name x
   group_name="${1}"
   queue_name="${2}"
   _groupsRaiseGroupNotFound "${group_name}" && ${returnFalse} 
   touch "${_msgDir}/queues/${group_name}.${queue_name}"
   x=$(grep "^id=[0-9]*,[0-9]*" "${_msgDir}/queues/${group_name}.${queue_name}" | wc -l)
   debug3 "x=${x}: _msgReturnQueuedItemsCount"
   echo ${x}
}

function test__msgReturnQueuedItemsCount {
   echo "bar" | send_message -group "foo" -keyword "email" "Bar Test"
   _msgReturnQueuedItemsCount "foo" "emailQueue" | assert ">0"
}

function _msgReturnMaxQueuedSeconds {
   # How long has the oldest item been in a queue for (in seconds)?
   # >>> _msgReturnMaxQueuedSeconds "group_name" "queue_name"
   ${arcRequireBoundVariables}
   typeset group_name now first_item x queue_name
   group_name="${1}"
   queue_name="${2}"
   now=$(dt_epoch)
   first_item=$(grep "^id=[0-9]*,[0-9]*" "${_msgDir}/queues/${group_name}.${queue_name}" | head -1 | awk -F"=" '{print $2}' | cut -d"," -f1)
   if [[ -z "${first_item:-}" ]]; then
      x=0
   else 
      ((x=now-first_item))
   fi
   debug3 "queued_seconds=${x}: $*: _msgReturnMaxQueuedSeconds"
   echo ${x}
}

function test__msgReturnMaxQueuedSeconds {
   echo "bar" | send_message -email -group "foo" "Bar Test"
   assert_sleep 5
   _msgReturnMaxQueuedSeconds "foo" "emailQueue" | assert ">0"
}

function _msgReturnMinQueuedSeconds {
   # How long has the most recent item been in a queue for (in seconds)?
   # >>> _msgReturnMinQueuedSeconds "group_name" "queue_name"
   ${arcRequireBoundVariables}
   typeset group_name now last_item x queue_name 
   group_name="${1}"
   queue_name="${2}"
   now=$(dt_epoch)
   last_item=$(grep "^id=[0-9]*,[0-9]*" "${_msgDir}/queues/${group_name}.${queue_name}" | tail -1 | awk -F"=" '{print $2}' | cut -d"," -f1)
   if num_is_num ${last_item}; then
      ((x=now-last_item))
   else
      x=0
   fi
   echo ${x}
}

function test__msgReturnMinQueuedSeconds {
   _msgReturnMinQueuedSeconds "foo" "emailQueue" | assert ">0"
}

function _msgCheckQueues {
   # Checks all queues for all groups to see if items are ready to send.
   # >>> _msgCheckQueues
   ${arcRequireBoundVariables}
   typeset group_name elapsed_secs
   debug3 "_msgCheckQueues: $*"
   timer_create -force -start "_msgCheckQueues"
   while read group_name; do
      if  _msgAreEmailsReadyToSend "${group_name}"; then
         _msgDeliverEmail "${group_name}"
      fi
      if _msgAreTextsReadyToSend "${group_name}"; then
         _msgDeliverTexts "${group_name}"
      fi
   done < <(contact_groups_list)
   elapsed_secs=$(timer_seconds "_msgCheckQueues")
   # __msg_check_warning_seconds: Log 'INFO' record if '_msgCheckQueues' execution exceeds this value.
   if (( ${elapsed_secs} > ${__msg_check_warning_seconds:-45} )); then
      log_notice -logkey "arcshell" -tags "messaging" "It took more than ${elapsed_secs} to check the message queues."
   fi
   timer_delete "_msgCheckQueues"
}

function test__msgCheckQueues {
   _msgCheckQueues && pass_test || fail_test 
}

function _msgDeliverEmail {
   # Delivers mail for a group, assuming there is at least one address configured.
   # Todo: Add "default_email" option.
   # >>> _msgDeliverEmail "group_name"
   ${arcRequireBoundVariables}
   debug3 "_msgDeliverEmail: $*"
   typeset group_name message_count
   group_name="${1}"
   eval "$(contact_group_load "${group_name}")"
   if [[ -z "${group_emails:-}" ]]; then
      group_emails="${arcshell_admin_emails:-}"
   fi
   if [[ -z "${group_emails:-}" ]]; then
      log_error -2 -logkey "arcshell" -tags "messaging,email" "'${group_name}' does not have a delivery address defined."
      cat "${_msgDir}/queues/${group_name}.emailQueue" | \
         log_notice -stdin -logkey "arcshell" -tags "messaging,email" "Dumping undelivered email for '${group_name}'..."
      cp /dev/null "${_msgDir}/queues/${group_name}.emailQueue"
      ${returnFalse} 
   else
      _msgWaitForLock
      cat "${_msgDir}/queues/${group_name}.emailQueue" | \
         _msgSendMail "${group_emails}" "'${group_name}' Email Messages" ${__messaging_max_email_lines:-9999}
      cp /dev/null "${_msgDir}/queues/${group_name}.emailQueue"
      _msgUnlockMessages
      ${returnTrue} 
   fi
}

function test__msgDeliverEmail {
   echo "foo" | send_message "Testing _msgDeliverEmail..."
}

function _msgDeliverTexts {
   # Deliver text messages.
   # >>> _msgDeliverTexts "group_name"
   ${arcRequireBoundVariables}
   debug3 "_msgDeliverTexts: $*"
   typeset group_name text_count
   group_name="${1}"
   eval "$(contact_group_load "${group_name}")"
   text_count="$(_msgReturnQueuedItemsCount "${group_name}" "textQueue")"
   ! (( ${text_count} )) && ${returnTrue} 
   if [[ -z "${group_texts:-}" ]]; then
      log_error -2 -logkey "arcshell" -tags "messaging,texts" "'${group_name}' does not have a delivery address defined."
      cat "${_msgDir}/queues/${group_name}.textQueue" | \
         log_notice -stdin -logkey "arcshell" -tags "messaging,texts" "Dumping undelivered texts for '${group_name}'..."
      cp /dev/null "${_msgDir}/queues/${group_name}.textQueue"
      ${returnFalse} 
   else 
      _msgWaitForLock
      cat "${_msgDir}/queues/${group_name}.textQueue" | \
         _msgSendMail "${group_texts}" "'${group_name}' Text Messages" ${__messaging_max_text_lines:-3}
      cp /dev/null "${_msgDir}/queues/${group_name}.textQueue"
      timer_reset "lastTextSent"
      _msgUnlockMessages
      ${returnTrue} 
   fi
}

function test_file_teardown {
   # Unit test teardown for the file.
   contact_group_delete "foo"
   contact_group_delete "bar"
   arcshell_mail_program="mail"
   rm "${arcHome}/config/contact_groups/foo.cfg" 2> /dev/null
}


