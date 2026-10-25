# Brainfuck Interpreter Test Framework

A self-contained bash-based test framework for validating Brainfuck interpreters.

## Design Principle

Each `.bf` file in the `tests/` directory serves a **dual purpose**:

1. **Brainfuck source code** — the program to run through the interpreter
2. **Expected result parser** — a bash script that validates the interpreter's output

No separate "expected output" files are needed; each test is self-contained.

## How It Works

### The Tester (`tester`)

A single bash script that:
1. Validates the interpreter is executable
2. Iterates over all `tests/*.bf` files
3. For each file, runs it through the interpreter to produce `result.raw`
4. Runs the same file on `result.raw` to check if the result matches the expected output
5. Counts PASS/FAIL and exits with a summary (or fatal error if all tests fail)

### How to Identify Source vs. Input

The framework uses a filename pattern to determine whether a test needs external input:

| Filename Pattern | Meaning |
|---|---|
| `name.bf` | The Brainfuck source; **no** stdin input needed |
| `name-X.input.bf` | The Brainfuck source; stdin input comes from `X.input` |

All `.bf` files are treated as **expected result parsers** and **Brainfuck source code**.

## File Structure

```
bf-tests/
├── tester                      # The main test runner script
└── tests/
    ├── inc.bf            # Expected parser for "inc" (no input needed)
    ├── dec.bf            # Expected parser for "dec" (no input needed)
    ├── right.bf          # Expected parser for "right" (no input needed)
    ├── left.bf           # Expected parser for "left" (no input needed)
    ├── loop.bf           # Expected parser for "loop" (no input needed)
    ├── in.input          # INPUT file for the "in" test
    └── in-in.input.bf    # Brainfuck source that uses `,` (reads from "in.input")
```

## How to Run

```bash
./tester <path-to-your-brainfuck-interpreter>
```

If your interpreter needs a wrapper script, pass that as the argument:

```bash
./tester ./scripts/my-bf-interpreter
```

## Example Walkthrough

### Testing `+` (increment):
```bash
$ grep "# BrainFuck code:" tests/inc.bf | cut -d":" -f 2
+ .
```
The interpreter runs `+.`, producing tape `01` (cell 0 = 1).

```bash
$ grep "# BrainFuck code:" tests/inc.bf | cut -d":" -f 2
RESULT=$(cat $1 | xxd | awk '{print $2}')
if [[ $RESULT == "01" ]]; then
    exit 0   # PASS
else
    exit 1   # FAIL
fi
```

The framework:
1. Runs interpreter on `inc.bf` → `result.raw` contains hex byte `01`
2. Runs `inc.bf` on `result.raw` → bash script reads `01`, matches expected → **PASS**

### Testing input handling:
```bash
$ grep "# BrainFuck code:" tests/in-in.input.bf | cut -d":" -f 2
,.
$ ./interpreter tests/in-in.input.bf < tests/in.input > result.raw
$ ./tests/in-in.input.bf result.raw
# checks if result equals "A" → PASS or FAIL
```

### Testing `-` (u8 wrapping to 255):
```bash
$ grep "# BrainFuck code:" tests/dec.bf | cut -d":" -f 2       # decrement 0 -> 255
-.
```

The interpreter runs `-.` on a tape that wraps around (0 → 255), and the parser checks the final cell value is `ff`.

### Testing jump validation:
```bash
$ grep "# BrainFuck code:" tests/dec.bf | cut -d":" -f 2
+++[>+++<-]>.
```

The interpreter runs `+++[>+++<-]>.` which increments cell 0 by 3, then enters a loop that adds 3 and subtracts 1 from cell 0 until it wraps (9 iterations), then exits. Parser checks the result is `09`.

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Same file as source AND parser | Keeps the framework self-contained; no external expected-output files |
| Bash-based parser | Easy to write expected outputs as simple shell scripts |
| `xxd` + hex comparison | Simple, unambiguous comparison of tape state |
| Exit code 0 = pass | Standard convention, integrates with shell pipelines |

## How to Add a New Test

1. **Create the expected result parser** (`mytest.bf`):
   ```bash
   #!/usr/bin/env bash
   RESULT=$(cat $1 | xxd | awk '{print $2}')
   if [[ $RESULT == "00" ]]; then
       exit 0
   else
       exit 1
   fi
   ```

2. **Create the Brainfuck source** with a compatible name:
   - `mytest.bf` if the test takes no input (no `,` instruction)
   - `mytest-some.input.bf` if the test needs input from `some.input`

3. The framework automatically pairs them and runs the test.

## Limitations & Assumptions

- **Assumes all tests should pass** — if all tests fail, `tester` exits with a fatal error
- **Assumes jumps are valid** — parsers don't check `[`/`]` match; they only check the final tape state

## Debugging a Failing Test

If a test fails, the parser will print the mismatched result:

```
❌ tests/inc.bf FAILED
RESULT=05
```

This tells you the interpreter produced `05` instead of the expected `01`.
