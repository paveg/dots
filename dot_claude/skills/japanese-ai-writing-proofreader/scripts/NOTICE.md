# Vendored files

`lint.py`, `textcore.py`, `fixtures/ai-smelly.md`, and `fixtures/natural.md` in
this directory are vendored **unmodified** from
[coji/natural-japanese](https://github.com/coji/natural-japanese)
(`skills/natural-japanese/scripts/`), commit
`c2ad5da4e4f9a29a84a0a9e74d93b6ce921d22d3` (2026-07-15), under the MIT license
reproduced below.

## Update procedure

1. Re-copy the four files above from the upstream repo at the new commit,
   byte-for-byte (no reformatting, no local patches).
2. Run `tests/skills/japanese-ai-writing-proofreader/run-tests.sh` from the
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
