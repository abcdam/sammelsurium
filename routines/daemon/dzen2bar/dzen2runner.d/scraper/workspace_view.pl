#!/usr/bin/env perl
use v5.36.0;
package Workspace_view;

BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}
use IPC::Run;
use JSON::XS;
use parent 'TaskRunner';

sub run {
    my $class = shift;
    $class->init->run_loop;
}

sub get_update {
    my ($self) = @_;

    my $workspace = $self->_get_active_workspace();
    return $self->colorify_entry(' workspace', $self->{color}{label}) . ': ' . $workspace;
}

sub _get_active_workspace {
    my $self = shift;
    my $output;
    IPC::Run::run ['i3-msg', '-t', 'get_workspaces'], \undef, \$output;

    my $workspaces = decode_json($output);
    my @formatted_workspaces;

    for my $ws (@$workspaces) {
        if ($ws->{focused}) {
            push @formatted_workspaces, $self->colorify_entry($ws->{name}, $self->{color}{value});
        } else {
            push @formatted_workspaces, $self->colorify_entry($ws->{name}, $self->{color}{label});
        }
    }

    return join ' ', @formatted_workspaces;
}

package main;
Workspace_view->run;