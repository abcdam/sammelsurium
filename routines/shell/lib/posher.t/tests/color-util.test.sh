load_posher color
# set -x
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
        got_outval=$("$parser" "$input" 2>&1) && got_excode=$? || got_excode=$?
        assert_equal "$got_outval" "$got_excode" "$exp_pattern" "$exp_excode" "$test_id"
      done
}


####################
###  Test Cases  ###
####################
test_parse_ANSI_style_opt() {

  run_tests '_parse_ANSI_style_opt' <<'TESTS'
#####
####
### TABLE ROW DEF:
##   < test id >|<test input>|< expected output pattern/substring >|< expected exit code >
#


# expected errors
no ANSI_style option||_parse_hue_opt(): requires param to be set|64
non-existent ANSI_style option|stereospace|(expected: one of 'bfuni' - got: 'stereospace')|64

# happy paths
(n)ormal ANSI_style option|n|0|0
normal ANSI_style option|normal|0|0

(b)old ANSI_style option|b|1|0
bold ANSI_style option|bold|1|0

(f)aint ANSI_style option|f|2|0
faint ANSI_style option|faint|2|0

(i)talic ANSI_style option|i|3|0
italic ANSI_style option|italic|3|0

(u)nderline ANSI_style option|u|4|0
underline ANSI_style option|underline|4|0

TESTS
} ## END test_parse_ANSI_style_opt()



test_parse_ANSI_color() {

  run_tests '_parse_ANSI_color' <<'TESTS'
#####
####
### TABLE ROW DEF:
##   < test id >|<test input>|< expected output pattern/substring >|< expected exit code >
#


# expected errors
no ANSI_color option||_parse_ANSI_color(): requires param to be set|64
non-existent ANSI_color option|ultraviolent|(expected: valid 4-bit color key - got: 'ultraviolent')|64

(w)hite ANSI_color option|w|37|0
white ANSI_color option|white|37|0

(r)ed ANSI_color option|r|31|0
red ANSI_color option|red|31|0

(g)reen ANSI_color option|g|32|0
green ANSI_color option|green|32|0

(y)ellow ANSI_color option|y|33|0
yellow ANSI_color option|yellow|33|0

(b)lue ANSI_color option|b|34|0
blue ANSI_color option|blue|34|0

(m)agenta ANSI_color option|m|35|0
magenta ANSI_color option|magenta|35|0
(p)urple ANSI_color option|p|35|0
purple ANSI_color option|purple|35|0

(c)yan ANSI_color option|c|36|0
cyan ANSI_color option|cyan|36|0

gray ANSI_color option|gray|90|0

(l)ight(r)red  ANSI_color option|lr|91|0
lightred  ANSI_color option|lightred|91|0


(l)ight(g)reen ANSI_color option|lg|92|0
lightgreen ANSI_color option|lightgreen|92|0


(l)ight(y)ellow ANSI_color option|ly|93|0
lightyellow ANSI_color option|lightyellow|93|0

(l)ight(b)lue ANSI_color option|lb|94|0
lightblue ANSI_color option|lightblue|94|0

(l)ight(m)agenta ANSI_color option|lm|95|0
lightmagenta ANSI_color option|lightmagenta|95|0
(l)ight(p)urple ANSI_color option|lp|95|0
lightpurple ANSI_color option|lightpurple|95|0

(l)ight(c)yan ANSI_color option|lc|96|0
lightcyan ANSI_color option|lightcyan|96|0

black ANSI_color option|black|30|0

(t)rue(w)hite ANSI_color option|tw|97|0
truewhite ANSI_color option|truewhite|97

TESTS
} ## END test_parse_ANSI_color()