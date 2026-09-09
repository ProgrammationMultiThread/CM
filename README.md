# ProgrammationMultiThread/CM

> **This repository is archived and no longer maintained.**

The teaching materials for the **Distributed Programming** course at Nantes Université have moved to the [`DistributedComputing/CM`](https://github.com/DistributedComputing/CM) repository, under `src/courses/pcmt/`.

See the [DistributedComputing organization](https://github.com/DistributedComputing) for the current course materials and related resources.

## Repository structure

```text
├── LICENSE.txt               # CC BY-SA 4.0 legal text
├── Makefile                  # Build, configuration, and maintenance commands
├── README.md                 # This file
├── build/                    # Temporary LaTeX compilation files
├── docs/                     # Generated PDFs
├── latex-libs/               # Automatically downloaded LaTeX dependency
└── src/
    ├── courses/              # Course drivers
    ├── archives/             # Optional archived course drivers
    ├── frames/               # Reusable slides organized by topic
    ├── img/                  # Redistributable images used in the slides
    └── sty/                  # Repository-specific styles and configuration
```

Every `.tex` file directly inside a subdirectory of courses is treated as a document driver. Files in `src/frames/` can be included directly by name; other resources under `src/` can be addressed by their relative path, for example `sty/config` or `plots/example`.

## Requirements

Compilation requires:

- GNU Make;
- a LaTeX distribution providing `pdflatex` and the packages used by the slides;
- an internet connection for the first build.

## Compilation

Build every slide deck and its handout version for the current course:

```bash
make
```

For the selected course, this produces:

```text
docs/<course>/cours.pdf
docs/<course>/handout/cours.pdf
```

The main build targets are:

```bash
make slide           # Build all slide decks for the current course
make handout         # Build all handouts for the current course
make cours           # Build both variants of cours.tex
make cours-slide     # Build only the slides, with one LaTeX pass
make cours-handout   # Build only the handout, with one LaTeX pass
make all-courses     # Build all current courses, excluding archives
```

The aggregate targets use two LaTeX passes. The document-specific `-slide` and `-handout` targets use one pass for faster incremental work.

To remove generated files:

```bash
make clean           # Remove temporary compilation files
make cleanall        # Also remove generated PDFs
```

## Course selection and reuse

List the available courses and document drivers:

```bash
make list
```

Select a course persistently for local work:

```bash
make configure COURSE=course-name
```

For a one-off build without changing the persistent selection:

```bash
make COURSE=course-name cours
```

To create another course variant, copy an existing course directory and edit its drivers:

```bash
cp -r src/courses/existing-course src/courses/new-course
make configure COURSE=new-course
```

Course directories under `src/archives/` can be selected in exactly the same way. The `src/archives/` directory is optional, is never created automatically, and is excluded from `make all-courses`.

## Dependencies

The slides rely on styles from the [latex-libs](https://github.com/MatthieuPerrin/latex-libs) project. On the first build, the Makefile automatically clones this dependency into `latex-libs/`. Subsequent builds can run offline.

Update both this repository and the local dependency with:

```bash
make update
```

## License

Except where otherwise stated, the original LaTeX sources and teaching materials in this repository are distributed under the [Creative Commons Attribution–ShareAlike 4.0 International license](LICENSE.txt).

Third-party materials, images, code excerpts, attribution requirements, and exceptions are documented in the [organization-wide licensing notice](https://github.com/ProgrammationMultiThread/.github/blob/main/LICENSE.md).
