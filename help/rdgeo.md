# Method notes: Geographic / Two-Score Boundary

With two running variables (coordinates, or two scores), treatment switches on across a boundary. The analysis reduces the problem to one dimension: the signed distance from each observation to the boundary (positive on the treated side), then an ordinary RD at zero.

- Polyline: boundary given by ordered vertices in two columns; needs a treatment indicator for the sign.
- Two scores: treated if both scores reach their cutoffs, or if either does; the boundary is the corresponding corner.
- The estimate averages the effect over boundary points. Effects can differ along the boundary; map the sample and check balance.
- Use metric coordinates: distance is Euclidean. Keep spatial dependence in mind and use a cluster variable if needed. Estimation options as in the main RD analysis.
