#!/usr/bin/env perl
use v5.36;
use warnings;
use strict;
use Getopt::Long;

my $SYNOPSIS;
my $DESCRIPTION;
my $SEP = ';;'; # separator
my $RETVAL = {}; # end product

sub sprintf_description {
    my ($flags, $size) = @_;
    my $output = '';
    my $format = {
        triple => "%$size->{lpad}s%-$size->{lhs}s %-$size->{middle}s%s\n",
        tuple => "%$size->{lpad}s%-".($size->{middle}+$size->{lhs})."s %s\n",
        select_f=>'tuple'
        };
    for my $val (sort keys %$flags) {
        my @descr_prefix = @{$flags->{$val}}[0..@{$flags->{$val}}-2];
        my @descr = split /\s+/, $flags->{$val}->[-1];
        if (@descr_prefix == 2) {
            $format->{select_f}='triple';
        }
        my $line = '';
        foreach my $desc (@descr) {
            if (length($line."$desc ") < $size->{rhs}) {
                $line.= "$desc ";
            } else {
                $output.= sprintf $format->{$format->{select_f}}, ' ', @descr_prefix, $line;
                
                @descr_prefix = $format->{select_f} eq "tuple" ? (' ') :(' ',' ');
                $line = "$desc ";
            }
        }
        $output.= sprintf $format->{$format->{select_f}}, ' ', @descr_prefix, $line;
    }
    return $output;
}

sub sprintf_usage {
    my ($data, $real_length) = @_;
    my $line = sprintf "Usage: %s ", $data->{lhs};
    my $usage_length = length($line);
    my $format = "%-${usage_length}s\n";
    my $output='';
    foreach my $arg (@{$data->{rhs}}) {
        if(length($line." $arg") <= ($real_length)){
            $line.="$arg ";
            next;
        }
        $output .= sprintf $format, $line;
        $line = ' 'x $usage_length;
    }
    $output .= sprintf $format, $line unless $line =~/^\s+$/;
    $output .= "\n";
    my $intro = $data->{intro};
    while (length($intro)>$real_length){
        my $split_idx = rindex($intro, ' ', $real_length);
        if ($split_idx == -1) {
            $split_idx = $real_length;
        }
        my $sub = substr($intro, 0, $split_idx);
        $output .= $sub."\n";
        $intro = substr($intro, $split_idx);
        $intro =~ s/^\s+//; #trim
    }
    $output .= $intro."\n";
    return $output;
}

sub sprintf_string {
    my ($min_length,$max_length) = (64, 128);
    my $real_length = (split /\s/, qx(stty size))[1];
    my $length = $real_length > $min_length ? $real_length : $min_length;
    $length = $max_length if $length > $max_length;
    my ($lpad, $max_lhs, $max_middle) = (2, int($length/32), int($length/4));
    my $sep_line = '-' x $length;
    my $header_format = "$sep_line\n%*s\n$sep_line\n";
    my $output='';
    if ($RETVAL->{usage}{intro}) {
        $output = sprintf $header_format, int($length/2+4), "SYNOPSIS";
        $output .= sprintf_usage($RETVAL->{usage}, $length);
    }

    if ($RETVAL->{descr}) {
        # TODO: enable generation of flag/argument descriptions without section title
        if ($RETVAL->{descr}{title}) { 
            my $title = $RETVAL->{descr}{title};
            $output .= sprintf $header_format, int($length/2+length($title)/2), $title; 
        }
        my $max_rhs = $length-$lpad-$max_lhs-$max_middle;
        
        $output .= sprintf_description($RETVAL->{descr}{flags}, {
            lpad=>$lpad, 
            rhs=>$max_rhs,
            middle=>$max_middle, 
            lhs=>$max_lhs
            }
        );
    }
    print($output);
}

sub parse_description {
    if ($DESCRIPTION){
        my @desc = split /\s*$SEP\s*/,$DESCRIPTION;
        if ((split /;/, $desc[0]) == 1){
            $RETVAL->{descr}{title} = shift @desc;
            die "no flag description provided" if ! @desc;
        }
        foreach my $flag (@desc){
            my @flag_elements = split /;/,$flag;
            die "each flag description must have two or three substrings joined by ;" if (@flag_elements < 2 || @flag_elements >3 );
                $RETVAL->{descr}{flags}{$flag_elements[0]}= \@flag_elements;
        }
        return 1;
    }
    return 0;
}

sub parse_synopsis {
    if ($SYNOPSIS){
        my @synop = split /\s*$SEP\s*/, $SYNOPSIS;
        die "Synopsis must at least have a utility name and a synopsis text" if @synop < 2;
        $RETVAL->{usage}{intro} = $synop[-1]; # last element is always synopsis text
        $RETVAL->{usage}{lhs} = $synop[0];
        $RETVAL->{usage}{rhs} = [@synop[1..@synop-1]] if @synop > 3;
        return 1;
    }
    return 0;
}

GetOptions( 'synopsis=s' => \$SYNOPSIS, # --synopsis="<utility name>;;<flag_1>;;<flag_2=value_1>;;<ARG_1>;;<ARG_2 value_2>;;..;;<a few explanatory sentences>"
            'description=s' => \$DESCRIPTION,  # --description="<title of description>;;-<flag_1_short>;--<flag_1_long>;<description_flag_1>;;-flag_2_short;<description_flag_2>;;.."
          );
parse_synopsis();
parse_description();
die("No arguments detected.") if ! ($RETVAL->{descr} || $RETVAL->{synop});
sprintf_string();




# Example
# [11:51:50] >> ./pretty_synopsis.pl --synopsis="test-util;;[-v | --version];; [-h | --help];; [-C <path>];; [-c <name>=<value>];; [--exec-path[=<path>]];; [--html-path];; [--man-path];; [--info-path];; [-p | --paginate | -P | --no-pager];; [--no-replace-objects];; [--bare];; [--git-dir=<path>];; [--work-tree=<path>];; [--namespace=<name>];; [--super-prefix=<path>];; [--config-env=<name>=<envvar>];; <command> [<args>];;Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book." --description="DESCRIPTION;;-f;--flag;this is an example flag asdkgvkysagdsakd kjhbfkuydfa khkbfdkuyfg ksdkuyf ds;;-d;kuyadkfuybekhfkv  ksaydgf kdfahv fdsakjhavdfkyu  kyuavdfk khy;;-s;--samsa;liuanbd fuliuabe lfjkba lkuiygfalk jherba lfuiyabdf87;;-h;--help;liaubsl ub alkdbvkuy vd k,auyvdk usadv kuy"
# --------------------------------------------------------------------------------------------------------------------------------
#                                                             SYNOPSIS
# --------------------------------------------------------------------------------------------------------------------------------
# Usage: test-util [-v | --version] [-h | --help] [-C <path>] [-c <name>=<value>] [--exec-path[=<path>]] [--html-path] 
#                  [--info-path] [-p | --paginate | -P | --no-pager] [--no-replace-objects] [--bare] [--git-dir=<path>] 
#                  [--namespace=<name>] [--super-prefix=<path>] [--config-env=<name>=<envvar>] <command> [<args>] 
# Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy
# text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.
# --------------------------------------------------------------------------------------------------------------------------------
#                                                           DESCRIPTION
# --------------------------------------------------------------------------------------------------------------------------------
#     -d                                 kuyadkfuybekhfkv ksaydgf kdfahv fdsakjhavdfkyu kyuavdfk khy 
#     -f --flag                          this is an example flag asdkgvkysagdsakd kjhbfkuydfa khkbfdkuyfg ksdkuyf ds 
#     -h --help                          liaubsl ub alkdbvkuy vd k,auyvdk usadv kuy 
#     -s --samsa                         liuanbd fuliuabe lfjkba lkuiygfalk jherba lfuiyabdf87 

##
## and the same output for a tight term format:
##

# [11:52:02] >> ./pretty_synopsis.pl --synopsis="test-util;;[-v | --version];; [-h | --help];; [-C <path>];; [-c <name>=<value>];; [--exec-path[=<path>]];; [--html-path];; [--man-path];; [--info-path];; [-p | --paginate | -P | --no-pager];; [--no-replace-objects];; [--bare];; [--git-dir=<path>];; [--work-tree=<path>];; [--namespace=<name>];; [--super-prefix=<path>];; [--config-env=<name>=<envvar>];; <command> [<args>];;Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book." --description="DESCRIPTION;;-f;--flag;this is an example flag asdkgvkysagdsakd kjhbfkuydfa khkbfdkuyfg ksdkuyf ds;;-d;kuyadkfuybekhfkv  ksaydgf kdfahv fdsakjhavdfkyu  kyuavdfk khy;;-s;--samsa;liuanbd fuliuabe lfjkba lkuiygfalk jherba lfuiyabdf87;;-h;--help;liaubsl ub alkdbvkuy vd k,auyvdk usadv kuy"
# ----------------------------------------------------------------------------
#                                   SYNOPSIS
# ----------------------------------------------------------------------------
# Usage: test-util [-v | --version] [-h | --help] [-C <path>] 
#                  [--exec-path[=<path>]] [--html-path] [--man-path] 
#                  [-p | --paginate | -P | --no-pager] [--no-replace-objects] 
#                  [--git-dir=<path>] [--work-tree=<path>] 
#                  [--super-prefix=<path>] [--config-env=<name>=<envvar>] 
                 
# Lorem Ipsum is simply dummy text of the printing and typesetting industry.
# Lorem Ipsum has been the industry's standard dummy text ever since the
# 1500s, when an unknown printer took a galley of type and scrambled it to
# make a type specimen book.
# ----------------------------------------------------------------------------
#                                 DESCRIPTION
# ----------------------------------------------------------------------------
#   -d                    kuyadkfuybekhfkv ksaydgf kdfahv fdsakjhavdfkyu 
#                         kyuavdfk khy 
#   -f --flag             this is an example flag asdkgvkysagdsakd 
#                         kjhbfkuydfa khkbfdkuyfg ksdkuyf ds 
#   -h --help             liaubsl ub alkdbvkuy vd k,auyvdk usadv kuy 
#   -s --samsa            liuanbd fuliuabe lfjkba lkuiygfalk jherba 
#                         lfuiyabdf87 
