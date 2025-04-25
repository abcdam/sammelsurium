#!/bin/env perl
use v5.36.0;
###
## section SETUP
#
use constant GiB_factor => (2**30)**-1;
my %PATTERN = (
    keys => qr/(\S+)=/,
    vals => qr/"(.*?)"/
);

# these entries, if present, will be casted to human readable fmt
my @RAW_BYTES_KEY_REG = qw(SIZE FSSIZE FSUSED);

# numeric strings aligned to the right
my %IS_RIGHT_JUSTIFIED = map {$_ => 1} (qw(FSUSE%), @RAW_BYTES_KEY_REG);
### end section SETUP


###
## section MAIN
#
chomp(my @raw_lsblk = <STDIN>);
my %state = (raw_input => \@raw_lsblk);

$state{header_titles}
  = [ $raw_lsblk[0] =~ /$PATTERN{keys}/g ];
$state{longest_strings}
  = { map {$_ => length $_} @{ $state{header_titles} } };
$state{is_available_bytes_key}
  = { %{ $state{longest_strings} }{@RAW_BYTES_KEY_REG} };
$state{available_bytes_keys}
  = [ keys %{ $state{is_available_bytes_key} } ];


my $content_rows = [ preproc_lsblk(\%state) ];
++$_ for    # each column width
  values %{ $state{longest_strings} };

$_ += 3 for    #each column width containing human readable byte values
  @{ $state{longest_strings} }{ @{ $state{available_bytes_keys} } };

print_fmt({
    headers => $state{header_titles},
    rows    => $content_rows,
    %state{qw(longest_strings is_available_bytes_key)}
});
### end section MAIN


###
## section FUN
#
sub preproc_lsblk {
    my $data          = shift;
    my $col_headers   = $data->{header_titles};
    my $strlen_maxima = $data->{longest_strings};
    return map {
        my %entry =
          $_ =~ /$PATTERN{keys}$PATTERN{vals}/g;
        my @valid_int_value_keys =
          grep {$entry{$_}} @{ $data->{available_bytes_keys} };

        @entry{@valid_int_value_keys} =
          map {sprintf '%.2f', $_ * GiB_factor}
          @entry{@valid_int_value_keys};

        my @new_maxima_found_keys =
          grep {length $entry{$_} > $strlen_maxima->{$_}}
          @{$col_headers};
        @{$strlen_maxima}{@new_maxima_found_keys} =
          map {length $_}
          @entry{@new_maxima_found_keys};

        \%entry
    } @{ $data->{raw_input} };
} ## end sub preproc_lsblk


sub print_fmt {
    my $data = shift;

    my $fstr = ' ';
    $fstr .= '%'
      . ($IS_RIGHT_JUSTIFIED{$_} ? '' : '-')
      . $data->{longest_strings}{$_}
      . 's'
      for @{ $data->{headers} };

    my $fstr_single_pass = join "\n"
      , ($fstr) x (1 + @{ $data->{rows} });

    say sprintf $fstr_single_pass
      , map {
        $data->{is_available_bytes_key}{$_}
          ? $_ . '[G]'
          : $_
      } @{ $data->{headers} }
      , map {
        @{$_}{ @{ $data->{headers} } }
      } @{ $data->{rows} };
} ## end sub print_fmt
### end section FUN
