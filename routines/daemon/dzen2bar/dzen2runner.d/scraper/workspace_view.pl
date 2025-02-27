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

my @CMD = qw(i3-msg -t get_workspaces);


sub run {
    my $class = shift;
    $class->init->run_loop;
}


sub fetch_update {
    my($self) = @_;
    $self->append_tokens([
        { label => 'workspace' },
        { sep   => ': ' },
        $self->_get_workspaces_state()
    ]);
}


sub _get_workspaces_state {
    my $self = shift;
    my $workspace_json;

    Carp::croak sprintf 'Failed to run IPC cmd: %s', join ' ', @CMD
      unless IPC::Run::run [@CMD], \undef, \$workspace_json;

    my @wspaces = @{ decode_json($workspace_json) };
    return
      (@wspaces > 1 || exists $wspaces[0]->{focused})
      ? map {{
        ($_->{focused} ? 'value' : 'label')
          => sprintf '%s ', $_->{name}
      }} @wspaces
      : undef;
}

package main;
Workspace_view->run;
