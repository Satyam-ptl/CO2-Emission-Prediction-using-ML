#!/usr/bin/env bash
# Reproduces every table and figure. Run from the package root.  (~5 min on one CPU core)
set -e
mkdir -p work && cp data/modeling_dataset_step1.csv work/ && cd work
cp ../code/*.py ../code/*.js . 
python3 stage1_pipeline.py modeling_dataset_step1.csv      # tables T1-T12, predictions
python3 stage1b_external_and_intervals.py                   # external check (T13) + size-stratified intervals (T10c)
python3 stage2_figures.py                                   # Figures 1-7
python3 build_spec.py && node render_docx.js                # optional: rebuild the Word manuscript
