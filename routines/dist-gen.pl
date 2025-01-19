#!/usr/bin/env perl
use v5.36.0;
use strict;
use warnings;
use Getopt::Long;

sub usage {
    print <<"END_USAGE";
Usage: $0 -n <num_ranges> -t <top_range> -k <steepness> [-h(uman readable)]
    -n: Number of ranges to generate (integer, required).
    -t: Top range width (0 < t <= 40 )(integer, required).
    -k: Distribution modifier (float > 0).
END_USAGE
    exit 1;
}

# f: x \mapsto -\frac{a}{(b-1)^{\text{k}}} (x-1)^{\text{k}} + a
## $a given by 100 - t
## $b number of ranges
## $k shape modifier
sub f {
    my ($a, $b, $k) = @_;
    return map {-($a / ($b-1)**$k)*($_-1)**$k + $a} 1..$b;
}

my %opts;
GetOptions(
    'n=i'   => \$opts{amount},
    't=i'   => \$opts{top_range},
    'k=f'   => \$opts{dist_mod},
    'h'     => \$opts{human_readable},
) or usage();

# basic validation
usage() unless $opts{amount}    && $opts{top_range} && $opts{dist_mod};
usage() unless $opts{amount}    =~ /^\d+$/          && $opts{amount}    > 0;
usage() unless $opts{top_range} =~ /^\d{1,2}$/      && $opts{top_range} > 0 && $opts{top_range} <= 40;
usage() unless $opts{dist_mod}  =~ /^\d*\.?\d+$/    && $opts{dist_mod}  > 0;

my @values = map {int($_ + 0.5 )} f(100 - $opts{top_range}, $opts{amount}, $opts{dist_mod});

my $out = $opts{human_readable} ? sub { return 
                                            sprintf "%1d. floor: %2d%%\n", 1 + shift, shift @values
                                        } 
                                : sub { return 
                                            sprintf "%0.2f%s", 0.01 * shift @values, @values == 1 ? "\n" : ', '
        };

print $out->($_) for 0 .. $#values -1;
