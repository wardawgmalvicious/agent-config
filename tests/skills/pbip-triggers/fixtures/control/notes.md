# Negative control

This file matches no `paths:` glob in the payload. Opening it should
activate **zero** conditional skills. Use it to confirm the test method
itself works — if a conditional skill appears while only this file is in
scope, the observation is measuring something other than glob matching.
