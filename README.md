# Forecasting facility-level CO2 emissions of Indian cement plants — code and data package

**Environment used:** 3.12.3 sklearn 1.8.0 scipy 1.17.1 numpy 2.4.4 pandas 3.0.2 statsmodels 0.15.0 matplotlib 3.10.8

## Contents
- `data/modeling_dataset_step1.csv` — Climate TRACE v5.11.0 extract (India, manufacturing/cement, CO2, monthly; 166 facilities, Jan 2021–Jul 2026) with lag features.
- `data/T13_external_ICI_cement_PIB.csv` — official cement production index (Index of Eight Core Industries), transcribed from PIB Release ID 2276691 (22 Jun 2026), Annexure-II. May 2026 is provisional.
- `code/stage1_pipeline.py` — data audit, feature construction, validation-window selection, hold-out and rolling-origin evaluation, significance tests, robustness, multi-horizon, importance.
- `code/stage1b_external_and_intervals.py` — external validity check and size-stratified conformal intervals.
- `code/stage2_figures.py` — Figures 1–7. `code/build_spec.py` + `code/render_docx.js` — manuscript text/tables are generated from the result files.
- `results/` — all output tables (CSV), figures (PNG, 300 dpi) and predictions.
- `results/preds/stage3_adaptive_intervals.csv` and `results/preds/stage3_mondrian_intervals.csv` — row-level Stage 3 interval predictions, bounds, widths, calibration details, and empirical coverage indicators used to derive Tables 30–33.
- `run_all.sh` — reproduces everything.
- `package.json` — optional Node.js dependency for rendering the manuscript DOCX.

## Design in one paragraph
Forecast origin t, target y(t+1), features known at t only. Last 13 origins = test set; the 12 origins before = validation window used to choose the feature set and model; rolling-origin refits monthly. Seeds fixed (42).

## Notes
- The Climate TRACE data are public (https://climatetrace.org/explore); cite the inventory version and access date.
- Add a repository DOI (e.g. Zenodo) to the manuscript's code-availability statement before submission.

## Reproduction

From the repository root, install the Python dependencies and run:

```bash
python3 -m pip install -r requirements.txt
bash run_all.sh
```

On systems with multiple Python installations, set `PYTHON` to the interpreter
where the dependencies were installed, for example
`PYTHON=/path/to/python bash run_all.sh`.

The analysis is executed in `work/` so committed files under `results/` are not
overwritten. Recomputed tables, predictions, and figures are written to
`work/out/`. The integrity suite runs first and must pass before the analysis
continues.

The extended benchmark is resumable: existing `work/out/preds/s3/origin_*.csv`
files are reused. For a clean recomputation that removes only the generated
working directory, run `CLEAN_WORK=1 bash run_all.sh`.

The manuscript DOCX is optional. To enable it, install Node.js, run
`npm install` once from the repository root, and rerun `bash run_all.sh`.
Without the `docx` package, the analysis still runs and the DOCX step is
reported as skipped.

The supplied `results/` directory contains the checked-in reference outputs;
it is not updated automatically by `run_all.sh`.

Stage 3 aggregate summaries are computed from the row-level interval artifacts
written under `work/out/preds/`. The saved rows support independent checks of
coverage, interval ordering, widths, and the reported Stage 3 coverage and
width summaries. Coverage remains empirical rolling-origin coverage; these
files do not establish conditional coverage guarantees.


## Extended benchmark (stage 3)
- `code/stage3_benchmark.py`: 43 expanding-window rolling origins (Dec 2022 to Jun 2026), one-month-ahead, per plant. Baselines: persistence, **calendar-adjusted persistence** (y_t * days(t+1)/days(t)), seasonal naive (+calendar-adjusted), 3-month mean daily rate, SES, Theta. ML: RF/HGB on the daily-rate target, RF on tonnes. Fixed hyper-parameters, refit every origin, resumable (`out/preds/s3/`).
- `code/stage3b_inference.py`: metrics (MAE, RMSE, WAPE, MASE, bias), circular block bootstrap over months, Diebold-Mariano (HAC, Harvey correction), Holm correction. Convention: delta = loss(model) - loss(reference); negative = model better.
- `tests/`: panel integrity, leap-year calendar factor, and a no-future-information test.
- Fixed: output folders (`out/tables`, `out/preds`, `out/figures`) are now created automatically.
