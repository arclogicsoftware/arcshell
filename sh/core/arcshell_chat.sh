

# module_name="Chat"
# module_about="Supports sending messages to services like Slack."
# module_version=1
# module_image="smartphone-10.png"
# copyright_notice="Copyright 2019 Arclogic Software"

function send_slack {
   # Post a message to the configured slack channel.
   # >>> send_slack [-stdin] ["slack_message"]
   # -stdin: Get message from standard input.
   # slack_message: Get message from this variable.
   ${arcRequireBoundVariables}
   debug3 "send_slack: $*"
   typeset slack_message check_ok
   if [[ "${1:-}" == "-stdin" ]]; then
      slack_message="$(cat)"
   else 
      slack_message="${1}"
   fi
   echo "${slack_message}"
   eval "$(config_load_object "chat_services" "slack.cfg")"
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
      log_error -2 -logkey "chat" -tags "slack" "An error occurred making the Slack web request: '${check_ok:-}': send_slack"
      counters_set "slack,messages_failed,+1"
   else
      counters_set "slack,messages_success,+1" 
   fi
}

