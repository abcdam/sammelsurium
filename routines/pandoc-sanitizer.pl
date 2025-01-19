#!/usr/bin/env perl
use v5.36.0;
use strict;
use warnings;


sub main {
    my $file_path = shift;
    die "Usage: $0 <file_path>" 
        unless -f $file_path;

    my $content = remove_images(
        sanitize_codeblocks(
            read_file($file_path)
            )
    );
    say $content;
}


sub read_file {
    my ($file_path) = @_;
    open my $fh, '<', $file_path 
        or die "Cannot open file: $file_path";
    local $/; # Slurp mode
    my $content = <$fh>;
    close $fh;
    return $content;
}

sub remove_images {
    my $content = shift;
    $content =~ s{
                    !\[].*?=\)                  # remove base64 encoded blocks
                }{''}gmsex;
    return $content;
}
sub sanitize_codeblocks {
    my ($content) = @_;
    my @bold_strings;

    $content =~ s{
        (?:
            \*\*(.*?)\*\*                       # Track all bold strings to determine title
        )
        |
        (?:
            ^\s+<div\sclass="md-code-block">    # anchor
            .*?infostring">\s+(.*?)             # language extraction
            \s+</div>
            \s+<div\sclass(?:.*?</div>){4}      # match everything up to the code
            \s+(.*?)                            # extract full code block
            \s+</div>
        )
    }{
        if ($1) {
            push @bold_strings, $1;
            $1;
        } else {
            my $last_title = pop @bold_strings || '';   # code block descriptor
            my $lang = $2;                              # syntax highlighter
            my $code = $3;                              # actual content

            # replace html/css boilerplate with proper markdown/shiki styling
            "```$lang showLineNumbers title=\"$last_title\"\n$code\n```";
        }
    
    }gmsex;
    return $content;
}

main(@ARGV);

