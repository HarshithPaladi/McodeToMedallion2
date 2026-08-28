# M-to-Medallion agent pipeline

Turns the Power Query (M) transformations in the **HydraReport** semantic model
into Spark SQL that [`nb_generic_layer_load`](../nb_generic_layer_load.Notebook/notebook-content.py)
can run via `spark.sql()`, then keeps that SQL correct.

| # | Agent | Kind | Input | Output |
|---|-------|------|-------|--------|
| 1 | Extract M | **deterministic** — [`../extract_mcode.py`](../extract_mcode.py) | any semantic model (TMDL folder or `.bim`) | `m_extract/<QueryName>.m` |
| 2 | M -> Spark SQL | LLM (Fabric notebook + Claude API) | `m_extract/` | `sql/silver/<Target>.sql` |
| 3 | Read log errors, fix SQL | LLM | `metadata.pipeline_control_log` + `sql/**` | patched `sql/**` |
| 4 | Validate M vs Spark SQL | LLM + Spark | M result vs `spark.sql()` result | validation report |

Runtime model: **hybrid** — Agent 1 is plain Python, no LLM; Agents 2-4 run as
Fabric notebooks calling the Anthropic API. Agents 2-4 are not built yet.

## Agent 1

```bash
python extract_mcode.py <model-path> [-o m_extract]
```

Model-agnostic. `<model-path>` = a `*.SemanticModel` folder, its `definition/`
folder, a `.bim` file, or any folder containing one. Writes one file per M
query, named after the query (`Stg_Product.m`, `FactSales.m`, …). Nothing else -
no manifest, no filtering.
