#!/usr/bin/env raku
my $read-from-repo   = CompUnit::Repository::FileSystem.new(prefix => "./myRNG");
my $install-to-repo  = CompUnit::RepositoryRegistry.repository-for-name("site");
my $some-module-name = "myRNG"; # needed to get at the Distribution object in the next step
say my $preinstall-dist  = $read-from-repo.candidates($some-module-name).head;
$install-to-repo.install($preinstall-dist);
