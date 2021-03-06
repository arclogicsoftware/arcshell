
# module_name="SendGrid"
# module_about="SendGrid interface."
# module_version=1
# module_image="incoming.png"
# copyright_notice="Copyright 2019 Arclogic Software"

[[ -z "${arcTmpDir}" ]] && return

SENDGRID_API_KEY="${SENDGRID_API_KEY:-"${arcshell_sendgrid_api_key:-}"}"
sendgrid_from_address="${sendgrid_from_address:-"DoNotReply@notaframework.com"}"

function __readmeSendGrid {
   cat <<EOF
> The really good programmers spend a lot of time programming. I haven’t seen very good programmers who don’t spend a lot of time programming. If I don’t program for two or three days, I need to do it. And you get better at it—you get quicker at it. The side effect of writing all this other stuff is that when you get to doing ordinary problems, you can do them very quickly. -- Joe Armstrong

# SendGrid

**SendGrid interface.**

EOF
}
function sendgrid_send {
   # Sends the message from standard in using SendGrid API settings.
   # >>> sendgrid_send -a "X" -s "X" "to"
   # -a: From address.
   # -s: Subject text.
   # to: Comma separated list of email addresses.
   ${arcRequireBoundVariables}
   debug3 "sendgrid_send: $*"
   typeset to subject maxlines tmpFile from_address
   from_address="${arcshell_from_address:-}"
   subject=
   while (( $# > 0)); do
      case "${1}" in
         "-a") shift; from_address="${1}" ;;
         "-s") shift; subject="$(echo ${1} | sed 's/"/\\"/g')" ;;
         *) break ;;
      esac
      shift
   done
   to="${1}"
   tmpFile="$(mktempf)"
   cat > "${tmpFile}"
   cat "${tmpFile}" | sed 's/"/\\"/g' | str_replace_end_of_line_with_slash_n -stdin > "${tmpFile}1"
   # curl --request POST \
   #    --url https://api.sendgrid.com/v3/mail/send \
   #    --header "Authorization: Bearer ${SENDGRID_API_KEY}" \
   #    --header "Content-Type: application/json" \
   #    --data "$(_sendgridReturnJSONDataRecord "${to}" "${from_address}" "${subject}" "${tmpFile}1")"
   _sendgridReturnJSONDataRecord "${to}" "${from_address}" "${subject}" "${tmpFile}1"
   curl --request POST \
      --url https://api.sendgrid.com/v3/mail/send \
      --header "Authorization: Bearer ${SENDGRID_API_KEY}" \
      --header "Content-Type: application/json" \
      -d @${tmpFile}1.data
   
   if (( $? )); then
      cat "${tmpFile}" | log_error -stdin -2 -logkey "sendgrid" -tags "sendgrid" "Error: Trying to post to SendGrid."
      rm "${tmpFile}"*
      ${returnFalse} 
   else
      rm "${tmpFile}"*
      ${returnTrue} 
   fi
}

function _sendgridReturnJSONDataRecord {
   # Returns the data that is posted to the SendGrid API in JSON format.
   # >>> _sendgridReturnJSONDataRecord "to" "from" "subject" "tmpFile"
   # to: To address.
   # from: From address.
   # subject: Subject text.
   # tmpFile: Path to file containing contents of the message to encode.
   ${arcRequireBoundVariables}
   debug3 "_sendgridReturnJSONDataRecord: $*"
   typeset to from subject tmpFile
   to="${1}"
   from="${2}"
   subject="${3}"
   tmpFile="${4}"
   [[ ! -s "${tmpFile}" ]] && date > "${tmpFile}"
   (
   cat <<EOF
{  
   "personalizations":[  
      {  
         "to":[  
            {  
               "email":"${to}"
            }
         ]
      }
   ],
   "from":{  
      "email":"${from}"
   },
   "subject":"${subject}",
   "content":[  
      {  
         "type":"text/plain",
         "value":"$(cat "${tmpFile}")"
      }
   ]
}
EOF
   ) > "${tmpFile}.data"
   debug3 "${tmpFile}.data"
   cat "${tmpFile}.data" | debugd3
   ${returnTrue} 
}

function test__sendgridReturnJSONDataRecord {
   date > "/tmp/$$.tmp"
   _sendgridReturnJSONDataRecord "foo@acme.com" "bar@acme.com" "SendGrid Test" "/tmp/$$.tmp" | assert_match "content"
   rm "/tmp/$$.tmp"
}

function _sendgridThrowError {
   # Error handler for this library.
   # >>> _strThrowError "errorText"
   throw_error "arcshell_sendgrid.sh" "${1}"
}

