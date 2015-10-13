#!/usr/bin/env perl
use strict;
use warnings;

use Module::Build::Pluggable ( 'CPANfile' );

my $builder = Module::Build::Pluggable->new(
    module_name => 'Bio::RefBuild',
    license     => 'apache',
    dist_author => 'David Richardson <davidr@ebi.ac.uk>',
);
$builder->create_build_script();