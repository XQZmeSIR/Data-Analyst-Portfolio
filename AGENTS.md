# AGENTS.md — Data Analyst Portfolio

## Quick start

- **Python**: `uv sync` installs all deps from `pyproject.toml` + `uv.lock`
- **Run a notebook**: `uv run jupyter notebook` from repo root
- **Python version**: 3.13 (`.python-version`, `pyproject.toml`)
- **No test/lint/typecheck/formatter/CI config exists** — do not add or assume one
- **Package manager**: `uv` (not pip/poetry/pdm)

## Structure

Top-level dirs are organized by **tool/domain**, not by project:

| Directory | Content |
|---|---|
| `Python/` | Jupyter notebooks (EDA, cleaning, tutorials) |
| `SQL/` | Standalone `.sql` scripts + `coffee-shop.csv` dataset |
| `Tableau/` | Dashboard screenshots + processed data; **workbook in separate repo** (`XQZmeSIR/Tableau-Portfolio-London-Bike-Sharing`) |
| `Excel/` | `.xlsx` files (ABC analysis, retention, DAU/WAU/MAU, etc.) |
| `Product & business metrics/` | TSV flashcard Q&A on KPIs |
| `Interview/` | Empty placeholder |
| `Diagrams/` | Empty placeholder |

## Language

Content is mixed **English and Russian**. The statistics cards (`statistics_interview_cards.tsv`) and the pandas-simulative readme are in Russian. Root README, SQL README, Tableau README are in English. Do not assume either. Preserve the original language of any file you edit.

## Tableau

The actual Tableau workbook is in a **separate repo**. This repo only holds processed CSVs and dashboard screenshots. The preprocessing pipeline uses `uv run python script/main.py` (documented in that external repo, not here).

## What not to do

- Do not add build/test/lint/CI tooling — this is a static portfolio
- Do not touch `pyproject.toml` description field (placeholder by design)
- Do not rewrite `README.md` Excel links — those placeholders are intentional
