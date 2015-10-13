#!/usr/bin/env perl
use strict;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw/ tempdir /;
use File::Spec;

use lib "$Bin/../lib";
use Bio::RefBuild::Location qw(assembly_location);


my $root_dir = "$Bin/loc_test_root";
my $species_name = 'Bos_taurus';
my $assembly_name = 'UMD3.1';

#assemlbly
my $assembly_loc1 = assembly_location($root_dir,$species_name,$assembly_name);
my $expected_loc = "$root_dir/$species_name/$assembly_name";
is($assembly_loc1->location,$expected_loc,"Assembly location str");
is($assembly_loc1->manifest_location,$expected_loc."/files.manifest","File manifest location str");


my @assemblies = $assembly_loc1->species->list_assemblies();
is_deeply(\@assemblies,['Btau_4.0','UMD3.1'],'List assemblies');

my $assembly_loc2 = assembly_location($root_dir,$species_name,"Not_an_assembly");
ok(! $assembly_loc2->exists,"Fake dir does not exist");

is($assembly_loc1->location,$expected_loc,"Location as expected");
ok($assembly_loc1->exists,"Real dir does exist");

#annotation
my @annotations = $assembly_loc1->list_annotation();
is_deeply(\@annotations,['e80'],"Listed annotations");

my $annotation = $assembly_loc1->annotation('e80');
is($annotation->file_name_base,'UMD3.1_e80',"annotation filename base");


#mappability
my @mappbilities = $assembly_loc1->list_mappability();
is_deeply(\@mappbilities,['k42','k50'],"Listed mappability dirs");





done_testing();