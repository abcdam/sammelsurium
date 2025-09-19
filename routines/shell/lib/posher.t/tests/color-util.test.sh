load_posher color

# $4: if expected exit code is not set, it is assumed to be zero
assert_equal() {
    got_ov="$1"
    exp_ov_pattern="$3"
    exp_ec="${4:-0}"
    src_id="${5:?'assert_equal(): no test id given'}"
    got_ec="${2:?"assert_equal(): requires exit code of executed cmd in test '$src_id'"}"

    excode_info="(Error Code: expected/$exp_ec - got/$got_ec)"
    diff_substr_expansion=${got_ov#*$exp_ov_pattern}
    if [ $got_ec -eq $exp_ec ] && [ "$diff_substr_expansion" != "$got_ov" ]; then
        printf '%s\n' "PASS: $src_id"
        unset got_ov got_ec exp_ov_pattern exp_ec src_id
        return 0
    else
      retval=1
printf '%s\n' '--------------------------------------------------------------------------------'
printf "\033[0;31mFAIL\033[0m: test id: '%s'\n" "$src_id"         >&2
printf "Expected: '%s'\n"                       "$exp_ov_pattern" >&2
printf "Actual  : '%s'\n"                       "$got_ov"         >&2
printf '%s\n'                                   "$excode_info"    >&2
printf '%s\n' '--------------------------------------------------------------------------------'
    fi
    exit 1
}

run_tests() {
  parser="${1:?'run_tests(): missing parser'}"; shift

  grep -v -E '^\s*(#|$)'  \
    | while IFS='|'       \
        read -r test_id input exp_pattern exp_excode; do
        got_outval="$(eval "set -- $input"; "$parser" "$@" 2>&1)" && got_excode=$? || got_excode=$?
        assert_equal "$got_outval" "$got_excode" "$exp_pattern" "$exp_excode" "$test_id"
      done
}


####################
###  Test Cases  ###
####################
test_parse_ANSI_style() {

  run_tests '_parse_ANSI_style' <<'TESTS'
#####
####
### TABLE ROW DEF:
##   < test id >|<test input>|< expected output pattern/substring >|< expected exit code >
#


# expected errors
no ANSI_style id||_parse_ANSI_style(): requires param to be set|64
non-existent ANSI_style id|stereospace|(expected: one of 'bfuni' - got: 'stereospace')|64

# happy paths
(n)ormal ANSI_style id|n|0
normal ANSI_style id|normal|0

(b)old ANSI_style id|b|1
bold ANSI_style id|bold|1

(f)aint ANSI_style id|f|2
faint ANSI_style id|faint|2

(i)talic ANSI_style id|i|3
italic ANSI_style id|italic|3

(u)nderline ANSI_style id|u|4
underline ANSI_style id|underline|4

TESTS
} ## END test_parse_ANSI_style()



test_parse_ANSI_color() {

  run_tests '_parse_ANSI_color' <<'TESTS'
#####
####
### TABLE ROW DEF:
##   < test id >|<test input>|< expected output pattern/substring >|< expected exit code >
#


# expected errors
no ANSI_color id||_parse_ANSI_color(): requires param to be set|64
non-existent ANSI_color id|ultraviolent|(expected: valid 4-bit color key - got: 'ultraviolent')|64


# happy paths
(w)hite ANSI_color id|w|37
white ANSI_color id|white|37

(r)ed ANSI_color id|r|31
red ANSI_color id|red|31

(g)reen ANSI_color id|g|32
green ANSI_color id|green|32

(y)ellow ANSI_color id|y|33
yellow ANSI_color id|yellow|33

(b)lue ANSI_color id|b|34
blue ANSI_color id|blue|34

(m)agenta ANSI_color id|m|35
magenta ANSI_color id|magenta|35
(p)urple ANSI_color id|p|35
purple ANSI_color id|purple|35

(c)yan ANSI_color id|c|36
cyan ANSI_color id|cyan|36

gray ANSI_color id|gray|90

(l)ight(r)red  ANSI_color id|lr|91
lightred  ANSI_color id|lightred|91

(l)ight(g)reen ANSI_color id|lg|92
lightgreen ANSI_color id|lightgreen|92

(l)ight(y)ellow ANSI_color id|ly|93
lightyellow ANSI_color id|lightyellow|93

(l)ight(b)lue ANSI_color id|lb|94
lightblue ANSI_color id|lightblue|94

(l)ight(m)agenta ANSI_color id|lm|95
lightmagenta ANSI_color id|lightmagenta|95
(l)ight(p)urple ANSI_color id|lp|95
lightpurple ANSI_color id|lightpurple|95

(l)ight(c)yan ANSI_color id|lc|96
lightcyan ANSI_color id|lightcyan|96

black ANSI_color id|black|30

(t)rue(w)hite ANSI_color id|tw|97
truewhite ANSI_color id|truewhite|97

TESTS
} ## END test_parse_ANSI_color()

test_hue() {
  run_tests 'hue' <<TESTS
#####
####
### TABLE ROW DEF:
##   < test id >|<test input>|< expected output pattern/substring >|< expected exit code >
#

no params hue()||hue(): requires input_txt param to be set|64
input text + wrong color hue()|"input text" "ultraviolent"|(expected: valid 4-bit color key - got: 'ultraviolent')|64
TESTS
}
