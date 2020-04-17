---
title: File Utilities
layout: gem-single
name: dry-cli
---

File utilities are a set of useful methods to manipulate files and directories, which must be required manually. [API doc](http://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files)

```ruby
require 'dry/cli/utils/files'
```

## List of implemented commands

- [append](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#append-class_method) - adds a new line at the bottom of the file;
- [cp](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#cp-class_method) - copies source into destination;
- [delete](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#delete-class_method) - deletes given path (file);
- [delete_directory](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#delete_directory-class_method) - deletes given path (directory);
- [directory?](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#directory?-class_method) - checks if path is a directory;
- [exist?](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#exist?-class_method) - checks if `path` exist;
- [inject_line_after](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#inject_line_after-class_method) - inject `contents` in `path` after `target`;
- [inject_line_after_last](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#inject_line_after_last-class_method) - inject `contents` in `path` after last `target`;
- [inject_line_before](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#inject_line_before-class_method) - inject `contents` in `path` before `target`;
- [inject_line_before_last](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#inject_line_before_last-class_method) - inject `contents` in `path` after last `target`;
- [mkdir](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#mkdir-class_method) - creates a directory for the given path;
- [mkdir_p](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#mkdir_p-class_method) - creates a directory for the given path;
- [remove_block](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#remove_block-class_method) - removes `target` block from `path`;
- [remove_line](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#remove_ine-class_method) - removes line from `path`, matching `target`;
- [replace_first_line](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#replace_first_line-class_method) - replace first line in `path` that contains `target` with `replacement`;
- [replace_last_line](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#replace_last_line-class_method) - replace last line in `path` that contains `target` with `replacement`;
- [touch](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#touch-class_method) - creates an empty file for the given path;
- [unshift](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#unshift-class_method) - adds a new line at the top of the file;
- [write](https://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files#write-class_method) - creates a new file or rewrites the contents of an existing file for the given path and content All the intermediate directories are created;

You can find more information in [API doc](http://www.rubydoc.info/gems/dry-cli/Dry/CLI/Utils/Files).
