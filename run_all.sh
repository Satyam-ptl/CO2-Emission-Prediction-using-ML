#!/usr/bin/env bash
# Reproduces every table and figure. Run from the package root.  (~5 min on one CPU core)
set -e
python3 -m pytest -q tests                                   # integrity + no-leakage tests (fail fast)
mkdir -p work && cp data/modeling_dataset_step1.csv work/ && cd work
cp ../code/*.py ../code/*.js . 
python3 stage1_pipeline.py modeling_dataset_step1.csv      # tables T1-T12, predictions
python3 stage1b_external_and_intervals.py                   # external check (T13) + size-stratified intervals (T10c)
python3 stage2_figures.py                                   # Figures 1-7
python3 stage3_benchmark.py modeling_dataset_step1.csv      # 43-origin benchmark incl. calendar-adjusted baselines (T20-T25 inputs)
python3 stage3b_inference.py                                # month-block bootstrap + Diebold-Mariano inference (T20-T25)
python3 stage3c_error_sources.py                         # where RF beats persistence (T26-T29c)
python3 stage3d_adaptive_conformal.py                     # pooled split conformal + ACI (T30-T32)
python3 stage3e_mondrian_conformal.py                     # size-conditional conformal (T33)
python3 stage3f_ici_comparison.py                         # panel vs official ICI cement growth (T34-T35)
python3 build_spec.py && node render_docx.js                # optional: rebuild the Word manuscript
