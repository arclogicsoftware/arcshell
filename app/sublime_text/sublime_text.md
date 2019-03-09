## sublime_text.sh

## User Reference
----

### sublime_text_generate_snippet
Generates a new or updates an existing snippet.
```c
> sublime_text_generate_snippet "snippet" "trigger"
# snippet: Snippet text.
# trigger: String which triggers the snippet.
```

## Developer Reference
----

### _sublimeTextEscapeSnippetText
Add backslashes to the some characters, .[]()*$, and return string.
```c
> _sublimeTextEscapeSnippetText "snippet"
```

### _sublimeThrowError
Returns error message to standard error.
```c
> _sublimeThrowError "error_message"
```

