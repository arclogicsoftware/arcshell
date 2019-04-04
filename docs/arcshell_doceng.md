> Make it correct, make it clear, make it concise, make it fast. In that order. -- Wes Dyer

# Documentation Engine

**Generate documentation and help commands from source files.**

The documentation engine is used primarily to generate the documentation located in the docs folder from the files in the ```${arcHome}/sh/core``` directory.

It also generates the built in ```help_*``` functions which are used to quickly reference the help for a module from the command line.



## Reference


### doceng_generate_page_modules_index
Builds the 'README.md' file in the 'docs' folder.
```bash
> doceng_generate_page_modules_index
```

### doceng_load_source_file_header
Builds a loadable file containing header variables and returns the string to load it.
```bash
> eval "$(doceng_load_source_file_header "source_file")"
```

### doceng_return_examples
Returns the body of the special '__example*' function if it exists.
```bash
> doceng_return_examples "file_path"
```

### doceng_return_links
Runs the __links* function if it exists which returns a list of links.
```bash
> doceng_return_links "source_file"
```

### doceng_delete_all
Deletes most of the files created by doceng.
```bash
> doceng_delete_all
```

### doceng_get_synopsis
Returns the list of functions and the synopsis from a file. The automatically generated *_help functions call this.
```bash
> doceng_get_synopsis [ -a | -aa ] "file_path"
# -a: Include private functions.
# -aa: Return all documentation for the item.
```

### doceng_get_documentation
Returns help for a file.
```bash
> doceng_get_documentation "file_path"
```

### doceng_do_markdown
Generates the main .md file for a libary.
```bash
> doceng_do_markdown "file_path"
```

### doceng_document_dir
Document the files in a directory.
```bash
> doceng_document_dir "directory"
```

### doceng_load_help_file
Return the string used to load the *_help functions for a directory.
```bash
> doceng_load_help_file "directory"
```

