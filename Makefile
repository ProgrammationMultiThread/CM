.DEFAULT_GOAL := all

# -------------------------------
# Configuration
# -------------------------------

SHELL       := bash
BUILDDIR    := build
DOCSDIR     := docs
COURSESDIR  := src/courses
ARCHIVESDIR := src/archives

PLOTDIR       := src/plot
PLOT_BUILDDIR := $(BUILDDIR)/plot

GNUPLOT ?= gnuplot

PLOTS     := $(basename $(notdir $(wildcard $(PLOTDIR)/*.gnuplot)))
PLOT_DATA := $(wildcard $(PLOTDIR)/*.dat)
PLOT_TEX  := $(PLOTS:%=$(PLOT_BUILDDIR)/%.tex)

# Discover current and archived courses.
COURSE_DIRS  := $(wildcard $(COURSESDIR)/*/)
ARCHIVE_DIRS := $(wildcard $(ARCHIVESDIR)/*/)

COURSES           := $(sort $(notdir $(patsubst %/,%,$(COURSE_DIRS))))
ARCHIVES          := $(sort $(notdir $(patsubst %/,%,$(ARCHIVE_DIRS))))
AVAILABLE_COURSES := $(sort $(COURSES) $(ARCHIVES))

# Persistent local selection, overridden with: make COURSE=xxx <target>
-include .current_course.mk
COURSE ?= $(or $(firstword $(COURSES)),$(firstword $(ARCHIVES)))
override COURSE := $(strip $(COURSE))

SRCDIR := $(firstword \
  $(wildcard $(COURSESDIR)/$(COURSE)) \
  $(wildcard $(ARCHIVESDIR)/$(COURSE)))

COURSE_BUILDDIR  := $(BUILDDIR)/$(COURSE)
HANDOUT_BUILDDIR := $(COURSE_BUILDDIR)/handout
COURSE_DOCSDIR   := $(DOCSDIR)/$(COURSE)
HANDOUT_DOCSDIR  := $(COURSE_DOCSDIR)/handout

PDFLATEX ?= pdflatex
_PASSES  := 2
PDFLATEX_FLAGS := -halt-on-error -interaction=nonstopmode

ifeq ($(OS),Windows_NT)
  PATHSEP := ;
else
  PATHSEP := :
endif

LATEX_LIBS_DIR       := latex-libs
LATEX_LIBS_SSH_URL   := git@github.com:MatthieuPerrin/Latex-libs.git
LATEX_LIBS_HTTPS_URL := https://github.com/MatthieuPerrin/Latex-libs.git

export TEXINPUTS := $(CURDIR)/$(SRCDIR)//$(PATHSEP)$(CURDIR)/src/frames//$(PATHSEP)$(CURDIR)/src/$(PATHSEP)$(CURDIR)/$(PLOT_BUILDDIR)//$(PATHSEP)$(CURDIR)/$(LATEX_LIBS_DIR)//$(PATHSEP)$(TEXINPUTS)

# -------------------------------
# Documents to generate
# -------------------------------

# Every .tex file directly inside the selected course directory is a driver.
DOCUMENTS    := $(basename $(notdir $(wildcard $(SRCDIR)/*.tex)))
SLIDE_ONCE   := $(DOCUMENTS:%=%-slide)
HANDOUT_ONCE := $(DOCUMENTS:%=%-handout)

SLIDE_PDFS   := $(DOCUMENTS:%=$(COURSE_DOCSDIR)/%.pdf)
HANDOUT_PDFS := $(DOCUMENTS:%=$(HANDOUT_DOCSDIR)/%.pdf)

# -------------------------------
# Public targets
# -------------------------------

.PHONY: all slide handout plot all-courses
.PHONY: configure list update clean cleanall help
.PHONY: $(DOCUMENTS) $(SLIDE_ONCE) $(HANDOUT_ONCE)

all: slide handout

slide: _check-course $(SLIDE_PDFS)

handout: _check-course $(HANDOUT_PDFS)

plot: $(PLOT_TEX)

# Archives are deliberately excluded from this target.
all-courses:
	@if [ -z "$(strip $(COURSES))" ]; then \
	  echo ">>> ERROR: no course found in $(COURSESDIR)"; \
	  exit 1; \
	fi
	@for course in $(COURSES); do \
	  echo ">>> Building course: $$course"; \
	  $(MAKE) --no-print-directory \
	    COURSE="$$course" \
	    all || exit $$?; \
	done

# A document alias builds both variants with two LaTeX passes.
$(DOCUMENTS): %: $(COURSE_DOCSDIR)/%.pdf $(HANDOUT_DOCSDIR)/%.pdf

# Variant-specific aliases use a single LaTeX pass.
$(SLIDE_ONCE): _PASSES := 1
$(SLIDE_ONCE): %-slide: $(COURSE_DOCSDIR)/%.pdf

$(HANDOUT_ONCE): _PASSES := 1
$(HANDOUT_ONCE): %-handout: $(HANDOUT_DOCSDIR)/%.pdf

# -------------------------------
# Plot generation
# -------------------------------

$(PLOT_BUILDDIR)/%.tex: $(PLOTDIR)/%.gnuplot $(PLOT_DATA) | _plot-directory
	$(GNUPLOT) \
	  -e "set loadpath '$(PLOTDIR)'; \
	      set terminal lua tikz color size 10cm,6cm; \
	      set output '$@'" \
	  "$<"

# -------------------------------
# Compilation rules
# -------------------------------

# Slides
$(COURSE_DOCSDIR)/%.pdf: $(SRCDIR)/%.tex $(PLOT_TEX) _force | _check-course _directories _deps
	$(PDFLATEX) $(PDFLATEX_FLAGS) \
	  -output-directory="$(COURSE_BUILDDIR)" \
	  -jobname="$*" \
	  "$<"
	@if [ "$(_PASSES)" -eq 2 ]; then \
	  $(PDFLATEX) $(PDFLATEX_FLAGS) \
	    -output-directory="$(COURSE_BUILDDIR)" \
	    -jobname="$*" \
	    "$<" || exit $$?; \
	fi
	@mv -f "$(COURSE_BUILDDIR)/$*.pdf" "$@"

# Handout
$(HANDOUT_DOCSDIR)/%.pdf: $(SRCDIR)/%.tex $(PLOT_TEX) _force | _check-course _directories _deps
	@printf '\\PassOptionsToClass{handout}{beamer}\\input{%s}\n' \
	  "$(SRCDIR)/$*.tex" \
	  > "$(HANDOUT_BUILDDIR)/$*.tex"
	$(PDFLATEX) $(PDFLATEX_FLAGS) \
	  -output-directory="$(HANDOUT_BUILDDIR)" \
	  -jobname="$*" \
	  "$(HANDOUT_BUILDDIR)/$*.tex"
	@if [ "$(_PASSES)" -eq 2 ]; then \
	  $(PDFLATEX) $(PDFLATEX_FLAGS) \
	    -output-directory="$(HANDOUT_BUILDDIR)" \
	    -jobname="$*" \
	    "$(HANDOUT_BUILDDIR)/$*.tex" || exit $$?; \
	fi
	@mv -f "$(HANDOUT_BUILDDIR)/$*.pdf" "$@"

# -------------------------------
# Internal targets
# -------------------------------

.PHONY: _check-course _directories _plot-directory _deps _force

_check-course:
	@if [ -z "$(COURSE)" ] || [ ! -d "$(SRCDIR)" ]; then \
	  echo ">>> ERROR: course '$(COURSE)' not found"; \
	  echo ">>> Use 'make list' or 'make configure COURSE=<name>'."; \
	  exit 1; \
	fi
	@if ! compgen -G "$(SRCDIR)/*.tex" >/dev/null; then \
	  echo ">>> ERROR: no .tex driver found in $(SRCDIR)"; \
	  exit 1; \
	fi

_directories:
	@mkdir -p \
	  "$(COURSE_BUILDDIR)" \
	  "$(HANDOUT_BUILDDIR)" \
	  "$(COURSE_DOCSDIR)" \
	  "$(HANDOUT_DOCSDIR)"

_plot-directory:
	@mkdir -p "$(PLOT_BUILDDIR)"

_deps:
	@if [ ! -d "$(LATEX_LIBS_DIR)/.git" ]; then \
	  echo ">>> Cloning latex-libs into $(LATEX_LIBS_DIR)"; \
	  git clone --depth 1 \
	    "$(LATEX_LIBS_SSH_URL)" \
	    "$(LATEX_LIBS_DIR)" 2>/dev/null \
	  || git clone --depth 1 \
	    "$(LATEX_LIBS_HTTPS_URL)" \
	    "$(LATEX_LIBS_DIR)"; \
	fi

_force:

# -------------------------------
# Course selection
# -------------------------------

configure:
	@c=$$(printf '%s' "$(COURSE)" | tr '[:upper:]' '[:lower:]'); \
	src="$(COURSESDIR)/$$c"; \
	if [ ! -d "$$src" ]; then src="$(ARCHIVESDIR)/$$c"; fi; \
	if [ ! -d "$$src" ]; then \
	  echo ">>> ERROR: course '$$c' not found"; \
	  echo ">>> Use 'make list' to list available courses."; \
	  exit 1; \
	fi; \
	if ! compgen -G "$$src/*.tex" >/dev/null; then \
	  echo ">>> ERROR: no .tex driver found in $$src"; \
	  exit 1; \
	fi; \
	printf 'COURSE := %s\n' "$$c" > .current_course.mk; \
	echo ">>> Current course: $$c"

list:
	@if [ -z "$(strip $(AVAILABLE_COURSES))" ]; then \
	  echo "Available courses:"; \
	  echo "   (none)"; \
	  exit 0; \
	fi; \
	echo "Current courses:"; \
	if [ -z "$(strip $(COURSES))" ]; then echo "   (none)"; fi; \
	for d in $(COURSE_DIRS); do \
	  course=$${d%/}; \
	  course=$${course##*/}; \
	  if [ "$$course" = "$(COURSE)" ]; then \
	    printf " * %s (current)\n" "$$course"; \
	  else \
	    printf " - %s\n" "$$course"; \
	  fi; \
	  for f in "$$d"*.tex; do \
	    [ -e "$$f" ] || continue; \
	    name=$${f##*/}; \
	    printf "     %s\n" "$${name%.tex}"; \
	  done; \
	done; \
	echo "Archived courses:"; \
	if [ -z "$(strip $(ARCHIVES))" ]; then echo "   (none)"; fi; \
	for d in $(ARCHIVE_DIRS); do \
	  course=$${d%/}; \
	  course=$${course##*/}; \
	  if [ "$$course" = "$(COURSE)" ]; then \
	    printf " * %s (current)\n" "$$course"; \
	  else \
	    printf " - %s\n" "$$course"; \
	  fi; \
	  for f in "$$d"*.tex; do \
	    [ -e "$$f" ] || continue; \
	    name=$${f##*/}; \
	    printf "     %s\n" "$${name%.tex}"; \
	  done; \
	done

# -------------------------------
# Updates and cleaning
# -------------------------------

update:
	@echo ">>> Updating main repository"; \
	git pull --ff-only \
	  || echo ">>> Skipping main repository update (offline or non-fast-forward)."; \
	if [ -d "$(LATEX_LIBS_DIR)/.git" ]; then \
	  echo ">>> Updating $(LATEX_LIBS_DIR)"; \
	  git -C "$(LATEX_LIBS_DIR)" pull --ff-only \
	    || echo ">>> Skipping latex-libs update (offline or non-fast-forward)."; \
	else \
	  echo ">>> latex-libs not present; it will be cloned during the next build."; \
	fi

clean:
	@rm -rf "$(BUILDDIR)"
	@echo ">>> Removed build artifacts"

cleanall: clean
	@for course in $(AVAILABLE_COURSES); do \
	  rm -rf "$(DOCSDIR)/$$course"; \
	done
	@echo ">>> Removed generated PDFs"

# -------------------------------
# Help
# -------------------------------

help:
	@echo "Usage:"
	@echo "  make | make all               – Build every slide deck and handout for the current course."
	@echo "  make slide                    – Build every slide deck for the current course with two LaTeX passes."
	@echo "  make handout                  – Build every handout for the current course with two LaTeX passes."
	@echo "  make plot                     – Generate the plots used by the slides."
	@echo "  make all-courses              – Build every slide deck and handout for every current course."
	@echo "  make cours                    – Build the slides and handout for cours with two LaTeX passes."
	@echo "  make cours-slide              – Build $(COURSE_DOCSDIR)/cours.pdf with one LaTeX pass."
	@echo "  make cours-handout            – Build $(HANDOUT_DOCSDIR)/cours.pdf with one LaTeX pass."
	@echo "  make COURSE=<name> <target>   – Build a course without changing the persistent selection."
	@echo "  make configure COURSE=<name>  – Persistently select a current or archived course."
	@echo "  make list                     – List current and archived courses and their document drivers."
	@echo "  make update                   – Update the main repository and latex-libs."
	@echo "  make clean                    – Remove LaTeX intermediate files and generated plots."
	@echo "  make cleanall                 – Also remove every generated course directory from docs/."
