
# Help functions are generated from the file names. For core files we don't
# want to include the work 'arcshell_' in every help function so we strip 
# it out and rename the function which returns help.

# We also have file names with dashes in them which is not allowed in function
# names, so we need to replace those with underscores.

BEGIN {
   FS=" ";
   foo=0;
}

{
   if ( $0 ~ /^function arcshell_/ ) {
      gsub("arcshell_", "", $2)
      print $0
   }
   else if ( $1 == "function") {
      gsub("-", "_", $0)
      print $0
   }
   else {
      print $0
   }
}

END {
   foo=1
}
