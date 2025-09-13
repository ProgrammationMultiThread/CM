# -------------------------------
# Configuration
# -------------------------------

SHELL    := bash
SRCDIR   := src/drivers
BUILDDIR := build
DOCSDIR  := docs

# LaTeX drivers from $(SRCDIR)
TEXS    := slides handout
PDFS    := $(addsuffix .pdf,$(TEXS))

# Choose engine (override with: make PDFLATEX=xelatex)
PDFLATEX ?= pdflatex
PDFLATEX_FLAGS := -halt-on-error -interaction=nonstopmode -output-directory=$(BUILDDIR)

# Latex-libs library (local clone + TEXINPUTS)
LATEX_LIBS_DIR	 := latex-libs
LATEX_LIBS_SSH_URL   := git@github.com:MatthieuPerrin/Latex-libs.git
LATEX_LIBS_HTTPS_URL := https://github.com/MatthieuPerrin/Latex-libs.git

# Path separator (Windows vs Unix)
ifeq ($(OS),Windows_NT)
  PATHSEP := ;
else
  PATHSEP := :
endif

# Add latex-libs to TeX search path (recursive with //); keep default path via trailing sep
export TEXINPUTS := $(CURDIR)/$(LATEX_LIBS_DIR)//$(PATHSEP)

# -------------------------------
# Main targets
# -------------------------------

.PHONY: all slides handout update clean cleanall help

# By default: build everything
all: slides handout

# Aliases to build each PDF
slides: $(DOCSDIR)/slides.pdf
handout: $(DOCSDIR)/handout.pdf

# Generic rule: build docs/%.pdf from src/drivers/%.tex
$(DOCSDIR)/%.pdf: $(SRCDIR)/%.tex FORCE | $(BUILDDIR) $(DOCSDIR) deps
	$(PDFLATEX) $(PDFLATEX_FLAGS) $<
	$(PDFLATEX) $(PDFLATEX_FLAGS) $<   # second pass for cross-refs
	@mv $(BUILDDIR)/$*.pdf $@

FORCE:

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
	  git -C $(LATEX_LIBS_DIR) pull --ff-only || echo ">>> Skipping latex-libs update (offline or non-fast-forward)."; \
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
	@rm -f $(DOCSDIR)/*.pdf

# -------------------------------
# Help
# -------------------------------

help:
	@echo "Usage:"
	@echo "  make            – Build both slides and handout"
	@echo "  make slides     – Build docs/slides.pdf"
	@echo "  make handout    – Build docs/handout.pdf"
	@echo "  make update     – Update local project and LaTeX-libs (git pull)"
	@echo "  make clean      – Remove build artifacts"
	@echo "  make cleanall   – Also remove generated PDFs"
