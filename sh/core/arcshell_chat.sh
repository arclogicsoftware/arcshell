
# module_name="Chat"
# module_about="Supports sending messages to services like Slack."
# module_version=1
# module_image="smartphone-10.png"
# copyright_notice="Copyright 2019 Arclogic Software"

# ToDo: Add wget support if curl isn't present.

function send_slack {
   # Post a message to the configured slack channel.
   # >>> send_slack [-stdin] ["slack_message"]
   # -stdin: Get message from standard input.
   # slack_message: Get message from this variable.
   ${arcRequireBoundVariables}
   debug3 "send_slack: $*"
   typeset slack_message check_ok 
   if [[ -z "${APP_SLACK_WEBHOOK:-}" ]]; then
      utl_raise_empty_var "arcshell_app_slack_webhook" "${arcshell_app_slack_webhook:-}" && ${returnFalse} 
      APP_SLACK_WEBHOOK="${arcshell_app_slack_webhook}"
   fi
   if [[ "${1:-}" == "-stdin" ]]; then
      slack_message="$(cat | sed 's/"/\\"/g')"
   else 
      slack_message="$(echo "${1}" | sed 's/"/\\"/g')"
   fi
   check_ok=$(curl --silent --data-urlencode \
    "$(printf 'payload={"text": "%s", "channel": "%s", "username": "%s", "as_user": "true", "link_names": "true", "icon_emoji": "%s" }' \
        "${slack_message}" \
        "" \
        "" \
        "" \
    )" \
    ${APP_SLACK_WEBHOOK}
    )
   if [[ "${check_ok:-}" != "ok" ]]; then
      log_error -2 -logkey "messaging" -tags "slack" "$(printf 'payload={"text": "%s", "channel": "%s", "username": "%s", "as_user": "true", "link_names": "true", "icon_emoji": "%s" }' \
        "${slack_message}" \
        "" \
        "" \
        "" \
        )"
      log_error -2 -logkey "messaging" -tags "slack" "An error occurred making the Slack web request: '${check_ok:-}': send_slack"
      counters_set "messaging,messages_failed,+1"
   else
      counters_set "messaging,messages_success,+1" 
   fi
}

