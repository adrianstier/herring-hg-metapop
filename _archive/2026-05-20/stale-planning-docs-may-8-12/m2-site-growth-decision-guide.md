# M2 Site-Growth Decision Guide

This guide records the `m2_stier_site_growth` decision from May 9, 2026. It
also preserves the promotion/failure gates for future reruns.

## May 9, 2026 Decision

`m2_stier_site_growth` is held, not promoted.

What passed:

- sampler health was clean: `0` divergences, `0` treedepth hits, max R-hat
  `1.001`, minimum E-BFMI `0.836`.

What failed or did not help:

- PSIS-LOO was unstable: max Pareto k `0.842`, with `5` points above `0.7`;
- positive-spawn calibration did not improve over `m1_stier_11`:
  aggregate log10 RMSE `0.566` versus `0.565`, bias `0.234` versus `0.233`;
- section-productivity estimates were all tightly pooled
  (median `U[j]` from `0.027` to `0.037`) and did not explain the section
  scorecard.

Decision: do not spend exact-reLOO time on this branch unless a later question
specifically requires it.

Follow-up: the observation-method sensitivity branch was also run on May 9 and
held. `m1_stier_method_sensitivity` was sampler-clean, but it did not improve
positive-spawn calibration and retained unresolved Pareto-k instability. The
three-era q estimates are useful descriptive context, not a promoted baseline.

## Model Being Tested

`m2_stier_site_growth` keeps the promoted `m1_stier_11` observation layer:

- zero spawn records are ambiguous/missing,
- only positive spawn observations enter the spawn likelihood,
- survey scaling uses the Stier two-era surface versus SCUBA/dive split,
- all 11 sections are fit,
- age/size, predators, density dependence, and spatial covariance are held out.

The only added process component is hierarchical section-specific productivity
`U[j]`.

## Promotion Gates

Promote `m2_stier_site_growth` only if all of these hold:

1. Sampler health is clean:
   - 0 divergences,
   - 0 treedepth hits,
   - max R-hat <= 1.01,
   - minimum E-BFMI >= 0.3.
2. LOO is usable:
   - max Pareto k < 0.7, or
   - high-k points are resolved with exact re-LOO.
3. Positive-spawn calibration does not degrade:
   - aggregate log10 RMSE should remain near or below the `m1_stier_11`
     baseline,
   - aggregate log10 bias should remain small.
4. Catch fit remains calibrated.
5. Section productivity estimates are interpretable against the independent
   scorecard:
   - depleted / flat sections should not all require implausibly high `U[j]`,
   - rebounded sections should not be driven only by low-coverage posterior
     uncertainty,
   - Tasu and Naden should be interpreted as sensitivity sections because their
     recent uncertainty is high.

## If M2 Passes

This did not happen in the May 9 fit. If a future regularized `m2` rerun
passes all promotion gates, use that rerun as the next process baseline. The
next branch should then be one of:

1. `m3_stier_distance`: add distance-decay process covariance to the
   site-productivity model.
2. `m3_stier_pdo_site_growth`: keep site productivity and test whether the PDO
   effect remains useful under section heterogeneity.
3. `m1_stier_method_sensitivity`: if the fit suggests observation-scale issues,
   pause process complexity and compare two-era q with surface/mixed/dive q.
   This May 9 branch has now been completed and held.

Do not jump straight to predators unless the section-productivity branch is
clean and the driver-confounding caveats are carried into the model design.

## If M2 Fails

Do not add predators, density dependence, or spatial covariance on top of it.
Instead simplify or regularize:

1. tighten the `sigma_U` prior,
2. test partial pooling on only a smaller set of section groups,
3. consider site-specific process variance only if productivity itself is not
   identifiable,
4. revisit data scale or q-era assumptions only if a new data reconstruction
   changes the positive-spawn likelihood, because the May 9
   `m1_stier_method_sensitivity` branch did not improve fit.

## Files To Read After Completion

- `Output/diagnostics/latest_model_status.md`
- `Output/diagnostics/model_comparison.csv`
- `Output/diagnostics/m2_stier_site_growth_postfit.md`
- `Output/diagnostics/m2_stier_site_growth_u_by_section.csv`
- `Output/diagnostics/m2_stier_site_growth_u_section_context.csv`
- `Output/figures/m2_stier_site_growth_productivity_diagnostic.pdf`
