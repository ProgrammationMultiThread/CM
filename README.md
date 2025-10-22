# Concurrent Multithreaded Programming - CM

This repository contains modular and reusable teaching materials used to build the slides for the Concurrent Multithreaded Programming course at Nantes University. 
See the [main organization](https://github.com/ProgrammationMultiThread/) for more information on the course and additional resources.


## Structure

```
├── LICENSE.md            # License CC-BY-SA 4.0  
├── Makefile              # Automatic compilation  
├── README.md             # This file  
├── build/                # Temporary files used during compilation  
├── latex-libs/           # Dependency from [latex-libs](https://github.com/MatthieuPerrin/latex-libs)  
├── docs/                 # Final PDF files (i.e. compiled course)  
├── src/                  # LaTeX source files  
│   ├── main/             # Main document files for the course  
│   ├── frame/            # Individual slides organized by topic (one file per slide)  
│   ├── img/              # Images used in the slides  
│   └── sty/              # Style files  
```

## Compilation

To build the course PDF:

```bash
make
```

This creates `docs/PCMT.pdf` and `docs/PCMT-handout.pdf`.

Build individually:

```bash
make slides     # Builds docs/PCMT.pdf
make handout    # Builds docs/PCMT-handout.pdf

make clean      # Remove temporary files in build/
make cleanall   # Also remove PDFs in docs/
```

## Customization

You can create your own course variant while reusing the provided slides.

- Create a new main file in `src/main/`, for example:
   ```bash
   cp src/main/PCMT.tex src/main/mycourse.tex
   ```
- Edit `src/main/mycourse.tex` to change the course metadata and the slides you want to include.
- Then configure the Makefile to compile your own course `docs/mycourse.pdf` and `docs/mycourse-handout.pdf`
   ```bash
   make configure COURSE=mycourse
   ```

## Dependencies

These slides rely on styles from the [latex-libs](https://github.com/MatthieuPerrin/latex-libs) project.
- On the first build, the Makefile automatically clones the library into `./latex-libs` (internet required).
- Subsequent builds work offline.
- Update both this repo and the library with:

```bash
make update
```


## Licensing

Content is available under the **Creative Commons Attribution-ShareAlike 4.0 International License** (CC BY-SA 4.0).

This means:
- You are free to reuse, modify, and redistribute the material.
- You must give appropriate credit.
- You must distribute derivatives under the same license.

See [`LICENSE.md`](LICENSE.md) for full terms.

## Contributions

Contributions are welcome!

Each slide is in a separate file, making it easy to reuse or improve specific parts. You can:
- Propose new slides
- Improve existing content or visuals
- Translate to other languages

Use pull requests to suggest changes.
For major changes, please open an issue first to discuss your ideas.
