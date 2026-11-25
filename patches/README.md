# Patch order

Apply all files in `upstream/` in filename order, then all files in `local/` in
filename order. Do not sort the combined list as one directory: the two local
patches are numbered independently and must come after the whole upstream
series.

The upstream series is 210 files numbered `0001` through `0223`; upstream
intentionally omits `0115`. See `../SOURCE.md` for the base commit and exact
application procedure.
