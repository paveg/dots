# Vendored files

`lint.py`, `calques.py`, `textcore.py`, `paragraphs.py`, `fixtures/ai-smelly.md`, and
`fixtures/natural.md` in this directory are vendored **unmodified** from
[coji/natural-japanese](https://github.com/coji/natural-japanese)
(`skills/natural-japanese/scripts/`), commit
`1fb57128a2f0d160e61320154226fdc86343ee2a` (tag v2.0.0), under the MIT license
reproduced below.

## Update procedure

1. Re-copy the files above from the upstream repo at the new commit,
   byte-for-byte (no reformatting, no local patches). `lint.py` imports its
   siblings at runtime, so check its imports for new ones and vendor those too.
2. Run `tests/skills/writing-proofread/run-tests.sh` from the
   repo root; if the pinned finding counts no longer match, update the
   fixtures' expected counts in that script to the new output (cross-check
   against upstream's `dev/check-fixtures.sh` expectations first).
3. Update the commit SHA in this file to the new upstream commit.

## License

MIT License

Copyright (c) 2026 coji

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

# Fetched files (yomiyasu)

`yomiyasu/yomiyasu_lint.py`, `yomiyasu/yomiyasu_diff.py`,
`yomiyasu/markdown_visibility.py`, and `yomiyasu/slop-catalog.md` (from
`skills/yomiyasu/references/`) are not stored in this repository. chezmoi
fetches them unmodified at `apply` time from a pinned release of
[nanaism/yomiyasu](https://github.com/nanaism/yomiyasu)
(`skills/yomiyasu/scripts/`, plus the catalog above), as declared in `home/.chezmoiexternal.toml`,
under the MIT license reproduced below.

`yomiyasu_check.py` and `yomiyasu_hook.py` from the same upstream directory are
deliberately **not** fetched: they write state under `.yomiyasu/` and install
hooks, which this repo does not want deployed.

## Update procedure

The `update-yomiyasu` workflow opens a PR when upstream tags a newer release.
To bump by hand instead:

1. Change the tag in the `url` of `home/.chezmoiexternal.toml`.
2. Run `tests/skills/writing-proofread/run-yomiyasu-tests.sh` from the repo
   root; if the pinned counts changed on purpose, update them in that script
   in the same PR.

## License

MIT License

Copyright (c) 2026 nanaism

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
