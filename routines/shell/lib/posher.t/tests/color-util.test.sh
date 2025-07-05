load_posher color
# set -x
assert_equal() {
    got_ov="$1"
    got_ec="$2"
    exp_ov_pattern="$3"
    exp_ec="${4:-0}"
    src_id="$5"

    excode_info="error code: got: $got_ec, expected: $exp_ec)"
    diff_substr_expansion=${got_ov#*$exp_ov_pattern}
    if [ $got_ec -eq $exp_ec ] && [ "$diff_substr_expansion" != "$got_ov" ]; then
        printf '%s\n' "PASS: $src_id"
        unset got_ov got_ec exp_ov_pattern exp_ec src_id
        return 0
    else
      retval=1
printf '%s\n' '--------------------------------------------------------------------------------'
printf "\033[0;31mFAIL\033[0m: %s\n" "$src_id"
printf "Expected: " >&2; printf '%s' "$exp_ov_pattern" | od -t x1 >&2
printf "Actual  : " >&2; printf '%s' "$got_ov" | od -t x1 >&2
printf '%s\n' "$excode_info" >&2
printf '%s\n' '--------------------------------------------------------------------------------'
    fi
    exit 1
    
}
####################
###  Test Cases    #
####################
test_parse_hue_opt() {

# Each line is: <test input> | <expected exit code> | 
#               <expected output pattern/substring> | <test id>
  cat <<'EOF' | while IFS='|' read -r input exp_excode exp_pattern test_id; do
|2|_parse_hue_opt requires param to be set|no option
n|0|0|(n)ormal option
b|0|1|(b)old option
f|0|2|(f)aint option
i|0|3|(i)talics option
u|0|4|(u)nderline option
invalid|0|0|non-existent option
EOF

got_outval=$( _parse_hue_opt "$input" 2>&1 ) && got_excode=$? || got_excode=$?
    assert_equal "$got_outval" "$got_excode" "$exp_pattern" "$exp_excode" "$test_id"
    done
    unset IFS got_outval got_excode exp_pattern exp_excode test_id
}