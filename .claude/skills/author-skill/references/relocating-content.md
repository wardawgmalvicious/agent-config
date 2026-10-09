# Relocating content out of a skill body

**If you are *relocating* content out of an existing body rather than
writing new, verify nothing was lost before committing.** Moving prose
between files is where silent content loss happens — it happened twice
during the 2026-08-31 body-slimming pass, once from a substring heading
match that dropped a whole section. Match headings **exactly**, with an
assertion, never by substring, and diff the result against `HEAD`:

```python
n = lambda s: re.sub(r'\s+', ' ', s).strip()
u = lambda s: set(re.findall(r'https?://[^\s\)\|]+', s))
print("URLs lost:", u(orig) - u(new_skill_plus_all_references))
missing = [l for l in orig.split('\n') if len(n(l)) > 45 and n(l) not in n(new)]
```

Every surviving entry in `missing` must be explainable as an intentional
rewrite. An empty `missing` and an empty URL set is the pass condition.
