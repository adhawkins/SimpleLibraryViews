package Plugins::EasyVirtualLibrary::Plugin;

# Logitech Media Server Copyright 2001-2014 Logitech.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.

use strict;

use base qw(Slim::Plugin::Base);

use Slim::Menu::BrowseLibrary;
use Slim::Utils::Log;
use Slim::Utils::Misc;
use File::Basename;

my $log = Slim::Utils::Log->addLogCategory({
        'category'     => 'plugin.easyvirtuallibrary',
        'defaultLevel' => 'WARN',
        'description'  => 'PLUGIN_EASY_VIRTUAL_LIBRARY_DESC',
});

sub initPlugin {
	my $class = shift;

	$log->info("In initPlugin for EasyVirtualLibrary");

	Slim::Music::VirtualLibraries->registerLibrary( {
		id => 'Andy',
		name => 'Library based on some complex processing',
		scannerCB => sub {
			my $libraryId = shift;
			createLibrary($libraryId, 'Andy');
		}
	} );

	$class->SUPER::initPlugin(@_);
}

sub createLibrary {
	my $id = shift;
	my $libName = shift;

	$log->info("Building library id " . $id . " for name " . $libName);

	my $rs = Slim::Schema->resultset('Track')->search;
	my $obj;

	do {
		$obj = $rs->next;
		if ($obj) {
			my $trackid = $obj->get_column("id");
			my $url = $obj->get_column("url");
			my $dir = dirname(Slim::Utils::Misc::pathFromFileURL($url));

			#$log->info("ID: " . $trackid . ", URL: " . $url .	", path: " . $dir);

			my $libFile = $dir . "/easy-virtual-library-" . $libName;
			if (-f $libFile) {
				$log->info("Adding " . $url . " to library " . $libName);

				my $dbh = Slim::Schema->dbh;
				$dbh->do(
					sprintf(
							q{INSERT OR IGNORE INTO library_track (library, track) values ('%s','%s')},
							$id, $trackid
						)
					);
			}
		}
	} while ($obj);
}
