# PROJECT_STATE.md  (resume file: read this instead of re-reading the repo)
Project: CO2 cement emissions forecasting, 166 Indian plants x 67 months (Climate TRACE v5.11.0)
Last updated: 12 Oct 2026 (chat 2: step 1 of NEXT ACTION done). Working branch: `improve-benchmark` (local commits only; NOTHING pushed to GitHub).
Repo: https://github.com/Satyam-ptl/CO2-Emission-Prediction-using-ML (cloned; single commit 9fd5c90).

## Phase status
- P1 audit: DONE for code/data/manuscript. Repo vs ZIP: EQUIVALENT (only CRLF vs LF in data CSV; 0 differing cells).
- P2 reproducibility: PARTIAL. Dir bug FIXED + verified from clean dir. Full end-to-end run_all.sh NOT yet executed (needs ~15 min; run in foreground in pieces or on own machine). Original T1-T4 + holdout preds reproduced exactly (1e-9) earlier.
- P3 baselines/benchmark: DONE (stage3). P4 longer rolling origin: DONE (43 origins). P5 dependence-aware inference: DONE (stage3b).
- P6 external (ICI full history) + literature audit: TODO. P7 feature importance: TODO. P8 adaptive conformal: TODO.
- P9 tests: DONE (3 tests pass). P10 manuscript rewrite: TODO.

## What changed in code (branch improve-benchmark)
- stage1/1b/2: output dirs auto-created; dead code removed in stage2 line 11.
- NEW code/stage3_benchmark.py, code/stage3b_inference.py, tests/test_integrity.py; run_all.sh runs tests + stage3/3b; README extended; .gitignore.
- NEW results: results/tables/T20-T25*.csv, results/preds/s3/origin_*.csv (43 files).

## VERIFIED RESULTS (all executed; sklearn 1.8.0, pandas 3.0.2, numpy 2.4.4, statsmodels 0.15.0)
Data facts: complete panel, no gaps/dupes; capacity = daily capacity x days (CV 0.1%); emission factor ~constant per plant; flag other10 changes over time for 124 plants.
Benchmark = 43 origins (Dec 2022..Jun 2026), 7,138 plant-months, expanding window, fixed hyper-params, refit each origin.
MAE (t), all 43 origins: RF(daily rate) 10,057 | CalAdj persistence 10,153 | RF(tonnes) 10,248 | HGB(daily) 10,510 | Theta 10,794 | SES 11,124 | CalAdj 3-mo mean rate 11,987 | Persistence 12,302 | CalAdj seasonal naive 12,520 | Seasonal naive 12,551.
Paper's 13-origin window reproduced by new code: Persistence 12,207, CalAdj 10,192, Seasonal naive 12,760.
Inference vs CalAdj persistence (delta = model - ref; negative = model better; unit = origin/month; block bootstrap block=3; DM with HAC + Harvey; Holm):
- RF(daily): delta -95 t, 95% CI [-674, +431], DM p 0.69 (not significant). HGB +357 [-425,+1115]. RF(tonnes) +96 [-545,+694].
- CalAdj persistence significantly BEATS SES, Theta, seasonal naive, 3-mo mean rate, ordinary persistence (Holm p<=0.049).
- Plant-level Wilcoxon gives p~0 for many comparisons where month-block CI includes 0 (independence problem demonstrated).
- 13-origin window vs ordinary persistence with block=3: RF(daily) CI [-4212,+334] includes 0 (earlier block=1 CI excluded 0 narrowly): result is sensitive to block length.
Secondary / EXPLORATORY (examined after seeing RMSE gap): squared-error loss vs CalAdj persistence, all origins: RF(daily) delta MSE -100.9e6 t^2, CI [-163,-46], better in 36/43 origins, Holm p 0.005; RF(tonnes) Holm p 0.042; HGB ns. => ML reduces LARGE errors (RMSE 19.0k vs 21.5k) but not typical (MAE) errors.
Tests: tests/test_integrity.py 3 passed (panel integrity, leap-year factor, no-future-information scramble/truncate test).
External/refs verified earlier: PIB 22 Jun 2026 release exists; May 2026 cement +8.4% and April 8.2% consistent; other 11 ICI months NOT verified. Ref [2] arXiv:2511.19277 OK; [4] exists; [3] arXiv:2604.19903 exists but its description in manuscript NOT confirmed (possible conflation with arXiv:2412.11981); [5]+classics not individually verified.

## CHAT 2 RESULT: where RF's large-error reduction comes from (code/stage3c_error_sources.py, tables T26-T29c; all 43 origins, 7,138 rows)
- Gain is CONCENTRATED: top 1% of rows (72) account for ~100% of the total squared-error gain; top 0.1% (7 rows) for ~30%. One plant (source_id 1897133, ~0.75-1.0 Mt/month, oscillating level) gives 21% of total gain; next 9 plants add ~35%.
- By size: gain share rises with plant size (Q4 large 46%, Q1 small 6%); RF is WORSE than CalAdj persistence on MAE for the smallest quartile (5,246 vs 4,868) and in Jan-Mar, Jul-Aug.
- By regime: restart/stop rows (target zero xor reference zero; 283 rows): RF MAE 20.5k vs 33.7k on non-zero-target restarts (RF better in 85%), but RF worse where both are zero (predicts ~4.3k when truth is 0). Excluding all zero/restart rows (n=6,511): RMSE 20.4k -> 18.0k still favours RF, MAE ~equal (9,784 vs 9,687).
- Robustness (caveat: trimming on outcomes is selection, so exploratory): dropping top 1% gain rows -> RMSE equal (18,094 vs 18,117), MAE RF worse (9,699 vs 9,149); dropping plant 1897133 -> RMSE 19,959 vs 17,837, MAE equal.
- Interpretation: RF improves a few large, hard-to-predict plant-months (stoppage/restart recoveries, one oscillating mega-plant), not typical errors. Manuscript wording: "ML helps on rare large deviations; no reliable gain for typical plants; hurts on small plants/zero months".
- NEXT: step 2 (ICI history), then adaptive conformal, full run_all.sh, manuscript rewrite.

## CHAT 2 RESULT (step 2 DONE): ICI external history (data/external_ici.csv, from owner-supplied official xlsx)
- Sources: Core_Industries_2011_12_20260720.xlsx (old series, base 2011-12, cement monthly Apr-2011..May-2026, DISCONTINUED) and Core_Industries_2022_23_20260921.xlsx (new series, base 2022-23, Apr-2023..Aug-2026), both from https://eaindustry.nic.in/ici_download_data.asp. YoY computed from index within each series; never splice index levels. Earlier hand-collected PIB values match the xlsx (only May-26 old series differs, 0.7 index pts: provisional vs revised).
- Panel (166 plants, total emissions) vs ICI cement YoY, same months: 
  old series 2022-01..2026-05 (n=53): corr 0.16, mean gap -8.0 pp (SD 6.9); new series 2024-04..2026-07 (n=28): corr 0.35, mean gap -8.1 pp (SD 4.3).
  Calendar-year growth, panel vs ICI(old): 2022 0.5% vs 10.3%; 2023 2.1% vs 7.9%; 2024 -0.6% vs 4.9%; 2025 0.2% vs 9.8%.
- CORRECTION: the 0.65 YoY correlation reported mid-chat came from only 14 months (Jun-25..Jul-26) and was misleading. Over the full history the panel does NOT track ICI growth month-to-month, and understates annual growth by 6-10 pp every year. Manuscript must say the Climate TRACE panel is not a validated proxy for national cement production growth (coverage 166 plants; modelled activity).

## CHAT 2 RESULT (step 3): conformal intervals (code/stage3d_adaptive_conformal.py, stage3e_mondrian_conformal.py; T30-T33)
- Pooled split conformal (RF daily rate, alpha=0.10, normalised abs residual, WARM=8 origins, 5,810 rows): coverage 90.1%, but very uneven: Q1 small plants 72.9%, Q4 large 99.5%; zero-target rows 45%; 2023 86%.
- ACI (Gibbs-Candes, panel-level feedback, gamma 0.005-0.05): changes nothing (alpha_t stays 0.097-0.101, coverage 90.2-90.4%, width +2-5%) because pooled coverage is already on target. ACI is the wrong tool for a conditional-coverage problem.
- Size-conditional Mondrian conformal (causal size quartile + 'previous month zero' class): overall 89.0%, mean width 52.3k t vs 93.2k t (-44%); by size 83.9 / 91.4 / 89.6 / 91.2%; zero-target rows 64%; but worst-origin coverage 74% (vs 82%) and SD across origins 0.061 (vs 0.040).
- Recommended manuscript position: report Mondrian intervals as primary, pooled as baseline, state that ACI adds nothing here; do not claim guaranteed conditional coverage.
- NEXT: full run_all.sh on clean checkout, manuscript rewrite (tone down ML claim per step-1 concentration finding and ICI finding), push to GitHub.

## CHAT 2 RESULT (clean-checkout reproduction)
- Fresh copy (no results/, no work/) + `pip install -r requirements.txt` + `bash run_all.sh`: 3/3 integrity tests pass (incl. no-future-information test); stages 1-3b run (~13 min total on 1 core); new stages 3c-3f (error sources, pooled/ACI conformal, Mondrian conformal, ICI comparison) added to run_all.sh and reproduce T26, T30, T33 exactly.
- Fixed: pytest was missing from requirements.txt (added); new scripts originally read results/ only, so they failed in a clean run — now use work/out in pipeline mode, results/ in shipped mode (BASE variable).
- NOT yet verified: `node render_docx.js` / build_spec.py (manuscript rebuild) — build_spec.py still contains OLD claims (13-month ICI window, "8.7%", "RF reduced MAE ... robust", "80% nominal conformal") that must be rewritten.
- NEXT: manuscript rewrite in build_spec.py (use T26-T35), then GitHub push.

## KNOWN ISSUES STILL OPEN
- build_spec.py hard-coded prose numbers (0.92-0.97 correlations, 8.7% ICI, 6,972->4,814, n_ counts); abstract mixes hold-out (115/166) and rolling (118/166).
- Figure 4a legend overlap; Table 1 mode row meaningless; permutation importance ignores collinearity.
- ICI check: 13 hand-typed months, level-correlation p invalid, May25-Apr26 vs FY25-26 mismatch, only 2/13 values verified.
- Conformal: exchangeability violated; no adaptive conformal. "Leakage-safe" wording should become "chronologically separated".
- Stage-3 ARIMA not included (SES/Theta only); MASE uses fixed training-only scale (first origin).

## NEXT ACTION (in order)
1. DONE (see CHAT 2 RESULT).
2. (PARTIAL, see CHAT 2 RESULT step 2) Collect full ICI history (DPIIT/OEA/PIB) into data/external_ici.csv with source URL, release date, period, units; compare identical 12-month windows via growth rates + block bootstrap.
3. Adaptive conformal inference (Gibbs & Candes) on stage-3 predictions; coverage over time.
4. Run full run_all.sh end-to-end; confirm T5-T12 reproduce.
5. Rewrite manuscript around: data audit + "ML adds little beyond calendar-aware baselines on MAE, but reduces large errors" ; claim-audit table; code-generated numbers; verified references.

## DECISIONS
- Reference baseline = calendar-adjusted persistence. No tuning on any evaluation period. Do not modify data CSV. SEED=42.
- Headline inference = month-level (block bootstrap + DM); plant-level only secondary.
- Do not commit/push to GitHub without owner permission.
