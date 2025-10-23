# -------------------------------
# Configuration
# -------------------------------

SHELL		:= bash
SRCDIR		:= src/main
BUILDDIR	:= build
DOCSDIR		:= docs
PLOTDIR		:= src/plot

# --- Generate plots ---
GNUPLOT := gnuplot
PLOTS := microprocessor-trend
PLOTGP  := $(addprefix $(PLOTDIR)/,$(addsuffix .gnuplot,$(PLOTS)))
PLOTTEX := $(addprefix $(BUILDDIR)/,$(addsuffix .tex,$(PLOTS)))

# Choose engine (override with: make PDFLATEX=xelatex)
PDFLATEX ?= pdflatex
PDFLATEX_FLAGS := -halt-on-error -interaction=nonstopmode -output-directory=$(BUILDDIR)

# Latex-libs library (local clone + TEXINPUTS)
LATEX_LIBS_DIR	     := latex-libs
LATEX_LIBS_SSH_URL   := git@github.com:MatthieuPerrin/Latex-libs.git
LATEX_LIBS_HTTPS_URL := https://github.com/MatthieuPerrin/Latex-libs.git

# Path separator (Windows vs Unix)
ifeq ($(OS),Windows_NT)
  PATHSEP := ;
else
  PATHSEP := :
endif

# Add latex-libs to TeX search path (recursive with //); keep default path via trailing sep
export TEXINPUTS := $(CURDIR)/$(LATEX_LIBS_DIR)//$(PATHSEP)$(CURDIR)/$(BUILDDIR)//$(PATHSEP)$(CURDIR)/src//$(PATHSEP)

# Select current course
-include .current_course.mk
COURSE ?= PCMT
SRCMAIN := $(SRCDIR)/$(COURSE).tex

# -------------------------------
# Main targets
# -------------------------------

.PHONY: both all slides handout update clean cleanall help configure list FORCE deps plot

# By default: build both
both: slides handout

slides: $(DOCSDIR)/$(COURSE).pdf
handout: $(DOCSDIR)/$(COURSE)-handout.pdf

all:
	@for f in $(SRCDIR)/*.tex; do \
	  base=$${f##*/}; name=$${base%.tex}; \
	  $(MAKE) --no-print-directory $(DOCSDIR)/$$name.pdf $(DOCSDIR)/$$name-handout.pdf || exit $$?; \
	done

$(BUILDDIR)/%.tex: $(PLOTDIR)/%.gnuplot $(wildcard $(PLOTDIR)/*.dat)
	@mkdir -p $(BUILDDIR)
	$(GNUPLOT) -e "set loadpath '$(PLOTDIR)'; \
	               set terminal lua tikz color size 10cm,6cm; \
	               set output '$@'" $<

$(DOCSDIR)/%.pdf: $(SRCDIR)/%.tex $(PLOTTEX) FORCE | $(BUILDDIR) $(DOCSDIR) deps
	$(PDFLATEX) $(PDFLATEX_FLAGS) -jobname=$* $<
	$(PDFLATEX) $(PDFLATEX_FLAGS) -jobname=$* $<
	mv "$(BUILDDIR)/$*.pdf" "$@"

$(DOCSDIR)/%-handout.pdf: $(SRCDIR)/%.tex $(PLOTTEX) FORCE | $(BUILDDIR) $(DOCSDIR) deps 
	echo "\def\HANDOUT{}\input{$(SRCDIR)/$*.tex}" > $(BUILDDIR)/$*-handout.tex;
	$(PDFLATEX) $(PDFLATEX_FLAGS) -jobname=$*-handout $(BUILDDIR)/$*-handout.tex
	$(PDFLATEX) $(PDFLATEX_FLAGS) -jobname=$*-handout $(BUILDDIR)/$*-handout.tex
	mv "$(BUILDDIR)/$*-handout.pdf" "$@"

FORCE:

# -------------------------------
# Course selection
# -------------------------------

configure:
	@if [ -z "$(COURSE)" ]; then \
	  echo "Usage: make configure COURSE=<nom>"; exit 1; \
	fi
	@echo "COURSE=$(COURSE)" > .current_course.mk
	@echo ">>> Cours courant: $(COURSE)"

list:
	@echo "Cours disponibles :"; \
	for f in $(SRCDIR)/*.tex; do b=$${f##*/}; echo " - $${b%.tex}"; done; \
	if [ -f .current_course.mk ]; then echo "Cours courant : $(COURSE)"; else echo "(aucun cours configuré, défaut: $(COURSE))"; fi

# -------------------------------
# Dependencies management (latex-libs)
# -------------------------------

# Ensure local clone exists (used as a prerequisite by build rules)
deps:
	@if [ ! -d "$(LATEX_LIBS_DIR)/.git" ]; then \
	  echo ">>> Cloning latex-libs into $(LATEX_LIBS_DIR)"; \
	  ( git clone --depth 1 "$(LATEX_LIBS_SSH_URL)"   "$(LATEX_LIBS_DIR)" 2>/dev/null \
	    || git clone --depth 1 "$(LATEX_LIBS_HTTPS_URL)" "$(LATEX_LIBS_DIR)" ); \
	fi

# Update both the main repo and the local dependency clone
update:
	@echo ">>> Updating main repository"; \
	git pull --ff-only || echo ">>> Skipping main repo update (offline or non-fast-forward)."; \
	if [ -d "$(LATEX_LIBS_DIR)/.git" ]; then \
	  echo ">>> Updating $(LATEX_LIBS_DIR)"; \
	  git -C "$(LATEX_LIBS_DIR)" pull --ff-only || echo ">>> Skipping latex-libs update (offline or non-fast-forward)."; \
	else \
	  echo ">>> latex-libs not present; run 'make deps' when online."; \
	fi

# -------------------------------
# Create folders
# -------------------------------

$(BUILDDIR):
	@mkdir -p $@

$(DOCSDIR):
	@mkdir -p $@

# -------------------------------
# Cleaning
# -------------------------------

clean:
	@rm -rf $(BUILDDIR)/*

cleanall: clean
	@rm -f $(DOCSDIR)/*.pdf .current_course.mk

# -------------------------------
# Help
# -------------------------------

help:
	@echo "Usage:"
	@echo "  make                       – Build docs/\$$COURSE.pdf and docs/\$$COURSE-handout.pdf"
	@echo "  make slides                – Build docs/\$$COURSE.pdf"
	@echo "  make handout               – Build docs/\$$COURSE-handout.pdf"
	@echo "  make configure COURSE=xxx  – Sets current course as src/main/xxx.tex (default: PCMT)"
	@echo "  make list                  – Lists available courses"
	@echo "  make update                – Update local project and LaTeX-libs (git pull)"
	@echo "  make clean                 – Remove build artifacts"
	@echo "  make cleanall              – Also remove generated PDFs"
