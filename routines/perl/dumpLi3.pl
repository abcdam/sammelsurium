#!/usr/bin/env perl
# @abcdam
use v5.36.0;
use JSON::PP;
###
## section CONFIG
#
my $JSON     = JSON::PP->new->utf8->pretty->relaxed;
my @HANDLERS = ({
    pattern => {
        class => qr/^\^VSCodium\$$/i
      }
    ,
    handler => \&set_codium_title_pattern,
});
### end section CONFIG


###
## section MAIN
#
die "Usage: i3-save-tree --workspace <NUM> | $0 > /<filepath>.json\n"
  unless @ARGV == 0;

local $/;
my $piped_in_i3_tree = <STDIN>;

my $layout_dump = preprocess($piped_in_i3_tree);
my $node_set    = [ $JSON->incr_parse($layout_dump) ];

process_node_inplace($_) for @{$node_set};

say join "\n"
  , map {
    $JSON->encode($_)
  } @{$node_set};
### end section MAIN


###
## section FUN
#
sub preprocess {
    my($content) = @_;

    my $requires_window_role = qr|^Chromium|;

    my $shared_pattern = {
        leading  => qr(\s*//\s*),
        trailing => qr(\s*:\s*".+?"),
    };

    $content =~ s{
      ("swallows":\s*\[\s*\{\s)     # $1: everything up to swallows prop
      (^.*?)                        # $2: raw json "swallows" list
      (^\s*\}\s*\])                 # $3: anchor
    }{
      my ($pre_anchor, $list, $post_anchor) = ($1, $2, $3);

      $list =~ s{
        ^$shared_pattern->{leading}
        ( # class & instance will be uncommented by default
        "(?:class|instance)"
        $shared_pattern->{trailing}
        )
      }{$1}gmex;

      my ($class) = $list =~ /"class"\s*:\s*"\^([^"]+)\$"/;
      die "regex bug while parsing list: $list" unless $class;


      if($class =~ $requires_window_role){
        $list =~ s{
          ^$shared_pattern->{leading}
          (
          "window_role"
          $shared_pattern->{trailing}
          )
        }{$1}gmx;
      }

      sprintf '%s%s%s'
        , $pre_anchor
        , $list
        , $post_anchor;
    }gmsex;

    return $content
      =~ s/^\s*\/\/.*?\n//grm;   # delet all remaining comments before returning
} ## end sub preprocess


sub process_node_inplace {
    my($node) = @_;
    return process_window_leaf($node)
      unless $node->{nodes};
    process_node_inplace($_) for @{ $node->{nodes} };
}


sub process_window_leaf {
    my($window) = @_;
    my $swallows_href = $window->{swallows}[0];
    for (@HANDLERS) {
        $_->{handler}->($window, $swallows_href)
          if $swallows_href->{class} =~ $_->{pattern}{class};
    }
    return;
}


sub set_codium_title_pattern {
    my($codium_window, $swallows_href) = @_;
    ($swallows_href->{title})
      = quotemeta(    # extract everything after the name of last edited file
        ($codium_window->{name} =~ /.*?-(.*)/)[0]
      ) . '$' =~ s/\//\/\//gr;    # escape meta chars again to reduce ambiguity
    return;
}
### end section FUN
