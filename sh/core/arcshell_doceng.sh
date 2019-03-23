
# module_name="Documentation Engine"
# module_about="Generate documentation and help commands from source files."
# module_version=1
# module_image="compose.png"
# copyright_notice="Copyright 2019 Arclogic Software"

[[ -z "${arcTmpDir}" ]] && return
_docengDir="${arcTmpDir}/_arcshell_doceng"
mkdir -p "${_docengDir}"

function doceng_generate_page_modules_index {
   # Builds the 'README.md' file in the 'docs' folder.
   # >>> doceng_generate_page_modules_index 
   ${arcRequireBoundVariables}
   typeset source_file file_path root_file image_markdown tmpFile link_string
   tmpFile="$(mktempf)"
   echo "# Modules Reference" > "${tmpFile}"
   echo "" >> "${tmpFile}"
   echo "| Module | About |" >> "${tmpFile}"
   echo "| --- | --- |" >> "${tmpFile}"
   (
   while read source_file; do
      file_path="${arcHome}/sh/core/${source_file}"
      root_file="$(file_get_file_root_name "${source_file}")"
      eval "$(doceng_load_source_file_header "${file_path}")"
      if [[ -n "${module_image:-}" ]]; then
         module_image="![${module_image}](./images/${module_image})"
         # module_image="<img src="./${module_image}" width="70"></img></br>"
      fi
      if [[ -n "${module_name:-}" ]]; then
         link_string="$(str_to_lower_case "${module_name}" | str_to_key_str)"
         echo "| [${module_name}](#${link_string}) | ${module_about} |" >> "${tmpFile}"
         cat <<EOF
<a name="${link_string}"/>

${module_image:-}

## ${module_name} (${source_file})

${module_about}

$(doceng_return_examples "${file_path}")

### Links

* [Reference](./${root_file}.md)
$(doceng_return_links "${file_path}")

----

EOF
      fi
   done < <(file_list_files "${arcHome}/sh/core" | sort)
   ) > "${tmpFile}1"
   ( 
   cat "${tmpFile}" 
   echo ""
   echo "----" 
   cat "${tmpFile}1" 
   ) > "${arcHome}/docs/README.md"
   rm "${tmpFile}"*
}

function doceng_load_source_file_header {
   # Builds a loadable file containing header variables and returns the string to load it.
   # >>> eval "$(doceng_load_source_file_header "source_file")"
   ${arcRequireBoundVariables}
   typeset source_file file_key
   source_file="${1}"
   file_key="$(_docengReturnFileKey "${source_file}")"
   (
   cat <<EOF 
module_file=
module_name=
module_about=
module_version=
module_image=
copyright_notice=
EOF
   ) > "${_docengDir}/${file_key}/source_file_header.txt"
   egrep "^# module_" "${source_file}" | sed 's/^# //' >> "${_docengDir}/${file_key}/source_file_header.txt"
   echo ". "${_docengDir}/${file_key}/source_file_header.txt""
}

function doceng_return_examples {
   # Returns the body of the special '__example*' function if it exists. 
   # >>> doceng_return_examples "file_path"
   ${arcRequireBoundVariables}
   typeset file_path function_name
   file_path="${1}"
   function_name="$(grep "^function __example.*" "${file_path}" | awk '{print $2}')"
   if [[ -n "${function_name}" ]]; then
      echo "## Example(s)"
      echo "\`\`\`bash"
      utl_get_function_body "${file_path}" "${function_name}"
      echo "\`\`\`"
   fi
}

function doceng_return_links {
   # Runs the __links* function if it exists which returns a list of links.
   # >>> doceng_return_links "source_file"
   ${arcRequireBoundVariables}
   typeset source_file function_name
   file_key="$(_docengReturnFileKey "${1}")"
   function_name="$(grep "^function __link" "${1}" | awk '{print $2}')"
   [[ -n "${function_name}" ]] && ${function_name}
}

function _docengReturnFileKey {
   # Return file path as 'key' string so it can be used as a lookup key.
   # >>> _docengReturnFileKey "source_file"
   ${arcRequireBoundVariables}
   typeset source_file file_key
   source_file="${1}"
   file_key="$(str_to_key_str "${source_file}")"
   mkdir -p "${_docengDir}/${file_key}"
   echo "${file_key}"
}

function doceng_delete_all {
   # Deletes most of the files created by doceng.
   # >>> doceng_delete_all
   ${arcRequireBoundVariables}
   debug2 "doceng_delete_all: $*"
   rm -rf "${_docengDir}"
   mkdir -p "${_docengDir}"
   ${returnTrue} 
}

function _docengCreateSingleLoadableHelpFile {
   # Creates single loadable "_.Help" file from individual "_.Help" files. Called from setup.
   # >>> _docengCreateSingleLoadableHelpFile
   ${arcRequireBoundVariables}
   find "${_docengDir}" -type f -name "_.Help" -exec cat {} \; \
      > "${arcTmpDir}/_.Help~"
   # The awk program renames some functions. See the .awk file for details.
   ${arcAwkProg} -f "${arcHome}/sh/core/_doceng_help.awk" \
      "${arcTmpDir}/_.Help~" > "${arcTmpDir}/_.Help"
   rm "${arcTmpDir}/_.Help~"
}

function _docengReturnReadme {
   # Runs the _readme* function in file if found.
   # >>> _docengReturnReadme "file_path"
   ${arcRequireBoundVariables}
   typeset file_path readme_function
   file_path="${1}"
   readme_function="$(grep "^function __readme" "${file_path}" | cut -d" " -f2)"
   if [[ -n "${readme_function:-}" ]]; then 
      ${readme_function}
      ${returnTrue} 
   else
      echo "# $(basename "${file_path}")"
      ${returnFalse} 
   fi
}

function _docengDoesRepoExist {
   # Return true if a repo exists for the provided directory.
   # >>> _docengDoesRepoExist "directory"
   ${arcRequireBoundVariables}
   debug2 "_docengDoesRepoExist: $*"
   typeset directory
   directory="${1}"
   file_raise_dir_not_found "${directory}" && ${returnFalse} 
   repo_path="$(_docengReturnRepoPath "${directory}")"
   if [[ -d "${repo_path}" ]]; then
      debug2 "${repo_path} exists"
      ${returnTrue} 
   else
      debug2 "${repo_path} does not exist"
      ${returnFalse} 
   fi
}

function _docengReturnRepoPath {
   # Returns dogengine repo path for the given file.
   # >>> _docengReturnRepoPath "file_path"
   ${arcRequireBoundVariables}
   typeset file_path repo_path
   file_path="${1}"
   if [[ -f "${file_path}" ]]; then
      file_path="$(dirname "${file_path}")"
   fi
   repo_path="$(str_to_key_str "${file_path}")"
   echo "${_docengDir}/${repo_path}"
}

function _docengReturnRepoKey {
   # Return the key used to store the file in the repository directory.
   # >>> _docengReturnRepoKey "file_path"
   ${arcRequireBoundVariables}
   typeset file_path repo_key
   file_path="${1}"
   repo_key="$(echo "$(basename "${file_path}")" | str_to_key_str)"
   echo "${repo_key}"
}

function doceng_get_synopsis {
   # Returns the list of functions and the synopsis from a file. The automatically generated *_help functions call this.
   # >>> doceng_get_synopsis [ -a | -aa ] "file_path"
   # -a: Include private functions.
   # -aa: Return all documentation for the item.
   ${arcRequireBoundVariables}
   debug3 "doceng_get_synopsis: $*"
   typeset repo_key showAll repo_path showFull file_path
   showAll=0
   showFull=0
   while (( $# > 0)); do
      case "${1}" in
         "-a") showAll=1 ;;
         "-aa") showFull=1 ;;
         *) break ;;
      esac
      shift
   done
   utl_raise_invalid_option "doceng_get_synopsis" "(( $# == 1 ))" "$*" && ${returnFalse}
   file_path="${1}"
   repo_path="$(_docengReturnRepoPath "${file_path}")"
   repo_key="$(_docengReturnRepoKey "${file_path}")"
   if (( ${showFull} )); then
      cat "${repo_path}/${repo_key}.txt"
   else [[ -f "${repo_path}/${repo_key}.PublicSynopsis" ]]
      cat "${repo_path}/${repo_key}.PublicSynopsis"
      if (( ${showAll} )) && [[ -f "${repo_path}/${repo_key}.PrivateSynopsis" ]]; then
         cat "${repo_path}/${repo_key}.PrivateSynopsis"
      fi
   fi
}


function doceng_get_documentation {
   # Returns help for a file.
   # >>> doceng_get_documentation "file_path"
   ${arcRequireBoundVariables}
   debug3 "doceng_get_documentation: $*"
   typeset file_path repo_key repo_path
   file_path="${1}"
   repo_path="$(_docengReturnRepoPath "${file_path}")"
   repo_key="$(_docengReturnRepoKey "${file_path}")"
   cat "${repo_path}/${repo_key}.txt"
}

function _docengFileHasSomethingToDocument {
   # Return true if there appears to be documentation to parse in the file.
   # >>> _docengFileHasSomethingToDocument "file_path"
   ${arcRequireBoundVariables}
   typeset file_path 
   file_path="${1}"
   if grep "^ *# >>>" "${file_path}" 1> /dev/null; then
      ${returnTrue}
   else
      ${returnFalse} 
   fi
}

function doceng_do_markdown {
   # Generates the main .md file for a libary.
   # >>> doceng_do_markdown "file_path"
   ${arcRequireBoundVariables}
   typeset dir_name root_name file_path 
   file_path="${1}"
   file_raise_is_not_full_path "${file_path}" && ${returnFalse} 
   dir_name="$(dirname "${file_path}")" 
   root_name="$(file_get_file_root_name "${file_path}")"
   _docengFileHasSomethingToDocument "${file_path}" || ${returnFalse} 
   (
   cat <<EOF
$(_docengReturnReadme "${file_path}")

$(doceng_return_examples "${file_path}")

## Reference

$(_docengReturnMarkdownPublic "${file_path}")

EOF
   ) > "${arcHome}/docs/${root_name}.md"
   ${returnTrue} 
}

function _docengReturnPublicSynopses {
   # Returns synopses for public functions.
   # >>> _docengReturnPublicSynopses "file_path"
   ${arcRequireBoundVariables}
   typeset file_path  
   file_path="${1}"
   ${arcAwkProg} -v includePrivateFunctions=0 \
      -v synopsisOnly=1 \
      -v includePublicFunctions=1 \
      -f "${arcHome}/sh/core/_doceng.awk" \
      "${file_path}"
}

function _docengReturnPrivateSynopses {
   # Returns synopses for private functions..
   # >>> _docengReturnPrivateSynopses "file_path"
   ${arcRequireBoundVariables}
   typeset file_path 
   file_path="${1}"
   ${arcAwkProg} -v includePrivateFunctions=1 \
      -v synopsisOnly=1 \
      -v includePublicFunctions=0 \
      -f "${arcHome}/sh/core/_doceng.awk" \
      "${file_path}"
}

function _docengReturnText {
   # Returns text documentation for all functions.
   # >>> _docengReturnText "file_path"
   ${arcRequireBoundVariables}
   typeset file_path 
   file_path="${1}"
   _docengReturnReadme "${file_path}"
   ${arcAwkProg} -v includePrivateFunctions=0 \
      -v includePublicFunctions=1 \
      -v synopsisOnly=0 \
      -f "${arcHome}/sh/core/_doceng.awk" \
      "${file_path}" 
   ${arcAwkProg} -v includePrivateFunctions=1 \
      -v includePublicFunctions=0 \
      -v synopsisOnly=0 \
      -f "${arcHome}/sh/core/_doceng.awk" \
      "${file_path}" 
}

function _docengReturnMarkdown {
   # Returns Markdown documentation for public functions..
   # >>> _docengReturnMarkdown "file_path"
   ${arcRequireBoundVariables}
   typeset file_path
   file_path="${1}"
   _docengReturnReadme "${file_path}"
   _docengReturnMarkdownPublic "${file_path}"
   _docengReturnMarkdownPrivate "${file_path}"
}

function _docengReturnMarkdownPublic {
   # Return docs in Markdown for public functions.
   # >>> _docengReturnMarkdownPublic "file_path"
   ${arcRequireBoundVariables}
   typeset file_path 
   file_path="${1}"
   ${arcAwkProg} -v includePrivateFunctions=0 \
      -v synopsisOnly=0 \
      -v vType="markdown" \
      -v includePublicFunctions=1 \
      -f "${arcHome}/sh/core/_doceng.awk" \
      "${file_path}" 
}

function _docengReturnMarkdownPrivate {
   # Return docs in Markdown for private functions.
   # >>> _docengReturnMarkdownPrivate "file_path"
   ${arcRequireBoundVariables}
   typeset file_path 
   file_path="${1}"
   ${arcAwkProg} -v includePrivateFunctions=1 \
      -v synopsisOnly=0 \
      -v vType="markdown" \
      -v includePublicFunctions=0 \
      -f "${arcHome}/sh/core/_doceng.awk" \
      "${file_path}" 
}

function _docengDeleteRepo {
   #
   #
   ${arcRequireBoundVariables}
   typeset directory repo_path
   directory="${1}"
   repo_path="$(_docengReturnRepoPath "${directory}")"
   if [[ -d "${repo_path}" ]]; then
      find "${repo_path}" -type f -exec rm {} \;
   fi
}

function doceng_document_dir {
   # Document the files in a directory.
   # >>> doceng_document_dir "directory"
   ${arcRequireBoundVariables}
   debug2 "doceng_document_dir: $*"
   typeset directory file_path 
   directory="${1}"
   file_raise_dir_not_found "${directory}" && ${returnFalse} 
   debug0 "Building documentation for '${directory}'."
   _docengDeleteRepo "${directory}"
   while read file_path; do
      if ! basename "${file_path}" | grep "^_" 1> /dev/null; then
         _docengDocumentFile "${file_path}"
      fi
   done < <(find "${directory}" -type f -name "*.sh")
}

function doceng_load_help_file {
   # Return the string used to load the *_help functions for a directory.
   # >>> doceng_load_help_file "directory"
   ${arcRequireBoundVariables}
   typeset directory repo_path target_dir
   directory="${1}"
   file_raise_dir_not_found "${directory}" && ${returnFalse} 
   repo_path="$(_docengReturnRepoPath "${directory}")"
   echo ". "${repo_path}/_.Help""
}

function _docengDocumentFile {
   # Generate the help files for a file.
   # >>> _docengDocumentFile "file_path"
   ${arcRequireBoundVariables}
   debug2 "_docengDocumentFile: $*"
   typeset file_path repo_key repo_path  
   file_path="${1}"
   file_raise_is_not_full_path "${file_path}" && ${returnFalse} 
   _docengFileHasSomethingToDocument "${file_path}" || ${returnFalse} 
   repo_path="$(_docengReturnRepoPath "${file_path}")"
   mkdir -p "${repo_path}"
   repo_key="$(_docengReturnRepoKey "${file_path}")"
   _docengReturnPublicSynopses "${file_path}" > "${repo_path}/${repo_key}.PublicSynopsis"
   _docengReturnPrivateSynopses "${file_path}" > "${repo_path}/${repo_key}.PrivateSynopsis"
   _docengReturnText "${file_path}" > "${repo_path}/${repo_key}.txt"
   _docengReturnMarkdown "${file_path}" > "${repo_path}/${repo_key}.md"
   _docengReturnHelpFunction "${file_path}" >> "${repo_path}/_.Help"
   doceng_do_markdown "${file_path}"
}


function _docengReturnHelpFunction {
   # Creates the file which contains the dynamically generated help *_help function.
   # >>> _docengReturnHelpFunction "file_path" 
   typeset file_path file_name 
   file_path="${1}"
   file_name="$(file_get_file_root_name "${file_path}")"
   # This prevents the 'arcshell_compiler.sh' from seeing below as a real function.
   echo "function ${file_name}_help {"
   cat <<EOF
   typeset allOpt 
   allOpt=
   if [[ "\${1:-}" == "-a" ]]; then
      allOpt="-a"
      shift
   elif [[ "\${1:-}" == "-aa" ]]; then
      allOpt="-aa"
      shift
   fi
   doceng_get_synopsis \${allOpt} "${file_path}" 
}
EOF
}

function _docengThrowError {
   # Returns an error string to standard error.
   # >>> _docengThrowError "errorText"
   ${arcRequireBoundVariables}
   throw_error "arcshell_doceng.sh" "${1}"
}

