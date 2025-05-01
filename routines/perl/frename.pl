#!/usr/bin/env perl
# @abcdam
use v5.36.0;
use Getopt::Long;
use File::Basename qw(fileparse basename);
use Carp;
use Cwd 'abs_path';

###
## section SETUP
#
my $USAGE = sprintf '%s %s %s'
  , "Usage: $0"
  , '[--apply] [--verbose] [-i /re/] [-r /re/] [-s /re/=/substitution/ [-s ..]]'
  , '<dir>';
my(%opt, @substitutions);
GetOptions(
    'v|verbose'        => \$opt{verbose},
    'a|apply'          => \$opt{no_dryrun},    # dry-run is default behavior
    'i|ignore-files=s' => sub {handle_regex_option(@_, 'ignore_re')},
    'r|remove=s'       => sub {handle_regex_option(@_, 'remove_re')},
    's|substitute=s'   => sub {handle_substitute_option(@_, 'substs')}
) or die "$USAGE";

$opt{substs} = \@substitutions;
$opt{dir}    = validate_dir(shift @ARGV || croak 'Directory required as arg');
### end section SETUP


###
## section MAIN
#
my @mappings = build_transformations(
    \%opt, get_skipped_printer($opt{verbose})
);

my $rename_file = get_configured_rename_op($opt{no_dryrun}, $opt{verbose});
for (@mappings) {
    die "Failed to rename $_->{old}: $!"
      unless $rename_file->($_);
}
say 'done.';
### end section MAIN

###
## section FUN
#
sub handle_regex_option {
    my($flag_id, $flag_value, $opt_key) = @_;
    croak "Flag '$flag_id' must be set once" if exists $opt{$opt_key};
    my $pattern = extract_value({
        value => $flag_value,
        flag  => $flag_id,
        kind  => "$flag_id pattern"
    });
    $opt{$opt_key} = qr/$pattern/;
}


sub handle_substitute_option {
    my($flag_id, $flag_value, $opt_key) = @_;
    my($replace_part, $subs_part) = split(/=/, $flag_value, 2);
    croak "Invalid substitution format for $flag_id"
      unless defined $subs_part;


    my $pattern = extract_value({
        value => $replace_part,
        flag  => $flag_id,
        kind  => 'replace pattern'
    });
    my $subs_str = extract_value({
        value => $subs_part,
        flag  => $flag_id,
        kind  => 'substitution'
    });

    croak "Duplicate replacement pattern '$pattern' in $flag_id"
      if exists $opt{$opt_key}{$pattern};

    $opt{$opt_key}{$pattern} = 1;    # only for input validation
    push @substitutions, {
        subs_re  => qr/$pattern/,
        subs_str => $subs_str,
    };
} ## end sub handle_substitute_option


sub extract_value {
    my $in = shift;
    $in->{value} =~ m{^/(.*)/$}
      or croak "Invalid $in->{kind} in $in->{flag}: must be /.../ format";
    return $1;
}


sub validate_dir {
    my($path) = @_;
    return abs_path($path) if -d $path;
    croak "Not a directory: '$path'";
}


sub build_transformations {
    my($conf, $printer) = @_;

    return grep {defined} map {
        my($new_path, $why_skip);
        if (! -f $_) {
            $why_skip = 'not a file';
        }
        elsif ($conf->{ignore_re} && /$conf->{ignore_re}/) {
            $why_skip = 'matched ignore-pattern';
        } else {
            $new_path = transform_filepath($_, $conf);
            $why_skip = 'filename did not change' if $new_path eq $_;
        }
        $why_skip
          ? $printer->({ skip => $_, why => $why_skip })
          : { old => $_, new => $new_path }
    } glob "$conf->{dir}/{.,}*";
}


sub transform_filepath {
    my($path, $conf) = @_;

    my($name, $dir, $ext) = fileparse($path, qr/(\.[^.]+)+$/);
    my $mod = $name;
    $mod =~ s/$conf->{remove_re}//g if $conf->{remove_re};
    $mod =~ s/$_->{subs_re}/$_->{subs_str}/g for @{ $conf->{substs} };
    $mod =~ s/^\s+|\s+$//g;
    $mod =~ s/\s+/_/g;
    return "${dir}${mod}${ext}";
}


sub get_skipped_printer {
    return sub { }
      unless shift;
    say sprintf '%s%13s - %s', 'SKIPPED', 'FILE', 'REASON';
    say '-' x 80;
    return sub {
        my($path, $reason) = @{ shift() }{qw(skip why)};
        say sprintf '%20s - %s', (basename $path), "[$reason]";
        return undef;
    }}


sub get_configured_rename_op {
    my($apply_rename, $is_verbose) = @_;
    my $should_print = ! $apply_rename || $is_verbose
      ? (
        (say 'Renaming (from -> to):'),
        sub {
            my($from, $to) = @_;
            ! $apply_rename && -e $to
              ? warn sprintf
              "warn: new target %-20s already exists and would be overwritten"
              , basename $to
              : say sprintf "%s\n ->  %s", (basename $from), (basename $to)
        }
      )
      : sub {1};
    my $maybe_rename =
      $apply_rename
      ? sub {rename(shift, shift)}
      : sub {1};
    return sub {
        my($from, $to) = @{ shift() }{qw(old new)};
        $should_print->($from, $to);
        $maybe_rename->($from, $to)
    }
} ## end sub get_configured_rename_op
###
## end section FUN
#


###
### brainstorming for a gen. purpose tabular data prettifier
###
#sub get_printer {
#    my $conf = shift;

#    # [ 'COL1_TEXT|[FMT]', 'COL2_TEXT|[FMT]...' ]
#    # FMT -> l|r/max-width/f|s|d
#    my @col_def = @{ $conf->{cols} };
#    my $title   = $conf->{title};
#    my $re      = qr{
#        ^
#        (?<title>.+?) \|\[
#        (?<jst>l|r)
#        (?:/(?<mxw>\d+))?
#        /(?<dtp>f|s|d)
#        \]$
#    }x;
#    my %config = map {
#        /$re/
#          ? ($_ => {
#            col_title => $+{title},
#            col_width => length $+{title},
#            fmt       => {
#                justify => $+{jst},
#                dtype   => $+{dtp},
#                ($+{mxw} ? (max_width => $+{mxw}) : ())
#            }
#          })
#          : do {warn "failed to parse $_, wrong structure"; ()}
#    } @col_def;
#    my $first_col_len_init = $config{ $col_def[0] }{col_width} + length($title);
#    my @entries;
#    return {
#        add_row => sub {
#            my @row = @_;
#            croak "wrong number "
#              . scalar @row
#              . " of args supplied. expected: "
#              . scalar @col_def unless 0 == @row - @col_def;

#            for (0 .. $#col_def) {
#                my($curr_len, $col)
#                  = (length $row[$_], $config{ $col_def[$_] });
#                $col->{col_width} = $curr_len if $col->{col_width} < $curr_len;
#            }
#            push @entries, \@row;
#        },
#        print => sub {
#            my $first_col = shift @col_def;
#            my $first_col_len_curr
#              = $config{$first_col}{col_width} + length $title;
#            $config{$first_col}{col_width} += 2
#              if $first_col_len_curr == $first_col_len_init;
#            my $col_sep = ' - ';
#            say $first_col_len_curr, $first_col_len_init;
#            my @fstr = (
#                '%s%' . ($config{$first_col}{col_width}) . 's'
#            );
#            $config{$first_col}{col_width} = $first_col_len_curr + 2;

#            for (@col_def) {
#                my $f = get_fstr($config{$_});
#                push @fstr, $f;
#            }
#            my $fstr_header = join $col_sep, @fstr;
#            $fstr[0] = get_fstr($config{$first_col});
#            my $fstr_rows = join $col_sep, @fstr;
#            say $fstr_header;
#            say $fstr_rows;
#            say sprintf $fstr_header
#              , (
#                $title,
#                map {$_->{col_title}} @config{ ($first_col, @col_def) }
#              );
#            say sprintf $fstr_rows
#              , (
#                map {@$_} @entries
#              );

#        } ## end sub
#    }

#} ## end sub get_printer


#sub get_fstr {
#    my $conf  = shift;
#    my $width = $conf->{fmt}{max_width};
#    if (defined $width) {
#        $width
#          = $conf->{col_width} > $width
#          ? $width
#          : $conf->{col_width};
#    } else {
#        $width = $conf->{col_width};
#    }
#    my $f
#      = '%'
#      . ($conf->{fmt}{justify} eq 'l' ? '-' : '')
#      . $width
#      . $conf->{fmt}{dtype};
#    return $f;
#}
