# Simple Library Views plugin for Logitech Media Server
# Copyright (C) 2016-2022 Andy Hawkins
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Andy Hawkins - andy@gently.org.uk

package Plugins::SimpleLibraryViews::Plugin;

use strict;

use base qw(Slim::Plugin::Base);

use Slim::Menu::BrowseLibrary;
use Slim::Utils::Log;
use Slim::Utils::Misc;
use File::Basename;
use File::Spec::Functions qw(catfile);
use Slim::Utils::Prefs;
use Slim::Control::Request;
use Path::Class;
use Data::Dump qw(dump);

my $log = Slim::Utils::Log->addLogCategory({
        'category'     => 'plugin.simplelibraryviews',
        'defaultLevel' => 'WARN',
        'description'  => 'PLUGIN_SIMPLE_LIBRARY_VIEWS_DESC',
});

if ( main::WEBUI ) {
	require Plugins::SimpleLibraryViews::Settings;
}

my $prefs = preferences('plugin.simplelibraryviews');

my %matchingDirectories;

sub initPlugin {
	my $class = shift;

	$log->info("In initPlugin for SimpleLibraryViews");

	$prefs->init({
		libraries => '',
		recursive => 1,
	});

	if ( main::WEBUI ) {
		Plugins::SimpleLibraryViews::Settings->new;
	}

	registerLibraries();

	$class->SUPER::initPlugin(@_);
}

sub scheduleRegisterLibraries {
	$log->info("Scheduling library register, new: '" . $prefs->get('libraries') . "'");

	my @newLibraries = split(/;/, $prefs->get('libraries'));

	foreach my $library (@newLibraries) {
		$library =~ s/^\s+|\s+$//g;
	}

	my %newLibrariesHash = map { $_ => 1 } @newLibraries;

	my $libs = Slim::Music::VirtualLibraries->getLibraries();

	foreach my $libid (keys % {$libs}) {
		my $name = Slim::Music::VirtualLibraries->getNameForId($libid);

		$log->info("Found registered lib ID ". $libid . ", name '" . $name);

		$name =~ /^SimpleLibraryViews (.*)/ || next;

		my $slvLib = $1;
		$log->info("Found SLV lib: '" . $slvLib . "'");

		if (! exists($newLibrariesHash{$slvLib})) {
			$log->info("Unregistering lib '" . $name . "'");
			Slim::Music::VirtualLibraries->unregisterLibrary($libid);
		}
	}

	registerLibraries();
}

sub registerLibraries {
	$log->info("In registerLibraries: '" . $prefs->get('libraries') . "'");

	my @libraries = split(/;/, $prefs->get('libraries'));
	foreach my $library (@libraries) {
		$library =~ s/^\s+|\s+$//g;
		$log->info("Checking library '$library'");
		if ($library ne "" ) {
			$log->info("Processing library '$library'");

			my $newID = Slim::Music::VirtualLibraries->registerLibrary( {
				id => $library,
				name => "SimpleLibraryViews $library",
				scannerCB => sub {
					my $libraryId = shift;
					createLibrary($libraryId, $library);
				}
			} );

			$log->info("Registered library $newID");
		}
	}

	Slim::Control::Request::executeRequest( undef, [ 'rescan' ] );
}

sub getDisplayName {
	return 'PLUGIN_SIMPLE_LIBRARY_VIEWS';
}

sub createLibrary {
	my $id = shift;
	my $libName = shift;

	$log->info("Scanner callback Building library id " . $id . " for name " . $libName);

	if ( ! main::SCANNER )
	{
		$log->info("Scanner callback Not in scanner building library id " . $id . " for name " . $libName);
		return;
	}

	$log->info("Scanner callback continuing");

	my $dirs = Slim::Utils::Misc::getAudioDirs();
	if (ref $dirs ne 'ARRAY' || scalar @{$dirs} == 0) {
		$log->info("Skipping library build - no folders defined.");
		return;
	}

	# Have we done the file search before?

	if ( ! keys %matchingDirectories ) {
		$log->info("Doing file search");

		my %fileNames;
		my @libraries = split(/;/, $prefs->get('libraries'));

		foreach my $library (@libraries) {
			$library =~ s/^\s+|\s+$//g;

			$fileNames{ ".simple-library-views-$library" } = $library;
			$fileNames{ "simple-library-views-$library" } = $library;
		}

		main::DEBUGLOG && $log->is_debug && $log->debug("Search files: " . dump(%fileNames));

		foreach my $dir ( @{ $dirs } ) {
			my $iter = File::Next::files({
				file_filter => sub {
								defined $fileNames{$_};
						}
				},
				$dir);

			while ( defined ( my $file = $iter->() ) ) {
				my $fileOnly = basename($file);
				my $library = $fileNames{$fileOnly};
				my $dirOnly = dirname($file);

				if ( ! defined $matchingDirectories{$library} ) {
					$matchingDirectories{$library} = [ $dirOnly ];
				} else {
					push @ { $matchingDirectories{$library} }, $dirOnly;
				}
			}
		}

		main::DEBUGLOG && $log->is_debug && $log->debug("Matching dirs: " . dump(%matchingDirectories));
	}

	my $dbh = Slim::Schema->dbh;

	my $recursive = $prefs->get('recursive');
	$log->info("Recursive: '$recursive'");

	my $sth_recursive_insert;
	my $sth_select;
	my $sth_insert;

	if ($recursive) {
		$sth_recursive_insert = $dbh->prepare('
			INSERT OR IGNORE INTO library_track (library, track)
			SELECT ?, tracks.id
			FROM tracks
			WHERE url like ?
			AND content_type NOT IN ("cpl", "src", "ssp", "dir")
		');
	} else {
		$sth_select = $dbh->prepare('
			SELECT id, url FROM tracks
				WHERE url like ? AND content_type NOT IN ("cpl", "src", "ssp", "dir")
				ORDER BY url
		');

		$sth_insert = $dbh->prepare('
			INSERT OR IGNORE INTO library_track (library, track) values (?, ?)
		');
	}

	foreach my $dir ( @ { $matchingDirectories{ $libName } } ) {
		my $pathSearch = Slim::Utils::Misc::fileURLFromPath($dir) . "/%";
		main::DEBUGLOG && $log->is_debug && $log->debug("$libName: Including '$dir', pathSearch: '$pathSearch'");

		if ($recursive) {
			$sth_recursive_insert->execute($id, $pathSearch);
		} else {
			$sth_select->execute($pathSearch);

			while ( my ($trackid, $url) = $sth_select->fetchrow_array ) {
				my $trackDir = dirname(Slim::Utils::Misc::pathFromFileURL($url));

				main::DEBUGLOG && $log->is_debug && $log->debug("dir for '$url' is '$trackDir'");

				if ( $trackDir eq $dir ) {
					main::DEBUGLOG && $log->is_debug && $log->debug("Inserting");

					$sth_insert->execute($id, $trackid);
				}
			}
		}
	}
}

1;

__END__
