
# module_name="Chat"
# module_about="Supports sending messages to services like Slack."
# module_version=1
# module_image="smartphone-10.png"
# copyright_notice="Copyright 2019 Arclogic Software"

# ToDo: Add wget support if curl isn't present.

function __readmeChat {
  cat <<EOF
> Programming is not like being in the CIA; you don't get credit for being sneaky. It's more like advertising; you get lots of credit for making your connections as blatant as possible. -- Steve McConnell 

# Chat

**Supports sending messages to services like Slack.**

This module currently supports Slack. You will need to obtain a web hook from Slack which enables you to post messages to a single channel. You will specify the allowed channel when you create the web hook. 

You will need to set the \`\`\`arcshell_app_slack_webhook\`\`\` value in one of the \`\`\`arcshell.cfg\`\`\` configuration files. Do not modify the delivered file. Instead modify your global or user version. These are located in \`\`\`\${arcGlobalHome}/config/arcshell\`\`\` and \`\`\`\${arcUserHome}/config/arcshell\`\`\` directories.

You can optionally set the value of this parameter in the configuration file for a specific **contact group**.
EOF
}

function __exampleChat {

  # Post vmstat data to Slack
  vmstat 5 5 | send_slack -stdin 

  # Post a simple message to Slack.
  send_slack "Build is complete."

  # Messages can also be posted to Slack using the messaging system.
  vmstat 5 5 | send_message -slack "This is a Slack message too."

}

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

