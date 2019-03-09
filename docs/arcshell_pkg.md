# arcshell_pkg.sh

## Reference


### pkg_show
Returns the working file and connection details if they have been set.
```bash
> pkg_show
```

### pkg_set
Sets the file you will be working with.
```bash
> pkg_set "package_file"
# package_file: (tar, tar.gz, or tar.Z) file which contains a single top level directory and contents.
```

### pkg_unset
Unset the ssh connection and file you are working with.
```bash
> pkg_unset
```

### pkg_dir
Create a compressed archive file of a directory.
```bash
> pkg_dir [-exclude "X"] [-saveto "X"] [package_dir=$(pwd)]
# -exclude: A list of directories to exclude from the package.
# -saveto: Directory to write the file to.
# package_dir: Path to top level directory that you want to package.
```

### pkg_ssh_mount
Mount a tar.gz or tar.Z file "as" a directory on one or more SSH end points.
```bash
> pkg_ssh_mount [-force,-f] [-target,-t "X"] [-ssh,-s "X"] ["package_file"]
# -force: 0 or 1. Force mount even if target directory already exists when 1.
# -target: Directory to mount the file "as" not "to". Note, this may change the top level directory name in the file being mounted!
# -ssh: SSH user@hostname, alias, tag, or group.
# package_file: (tar, tar.gz, or tar.Z) file which contains a single top level directory and contents.
```

### pkg_sync
Sync a package to a directory on remote nodes.
```bash
> pkg_sync [-ssh "X"] [-delete,-d] [-package,-p "X"] "target_directory"
# -ssh: SSH user@hostname, alias, tag, or group.
# -delete: Delete non-matching files from the remote nots.
# -package: (tar, tar.gz, or tar.Z) file which contains a single top level directory and contents.
# target_directory: Directory to mount the package "as".
```

### pkg_list
Return the list of known packages.
```bash
> pkg_list ["regex"]
# regex: Filter results to those matching regular expression.
```

