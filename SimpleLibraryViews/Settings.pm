# Simple Library Views plugin for Logitech Media Server
# Copyright (C) 2016 Andy Hawkins
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

package Plugins::SimpleLibraryViews::Settings;

use strict;
use warnings;

use base qw(Slim::Web::Settings);

use Slim::Utils::Log;
use Slim::Utils::Prefs;

my $log = logger('plugin.simplelibraryviews');
my $prefs = preferences('plugin.simplelibraryviews');

sub new {
	my $class = shift;

	$class->SUPER::new;
}

sub name {
	return Slim::Web::HTTP::CSRF->protectName('PLUGIN_SIMPLE_LIBRARY_VIEWS');
}

sub page {
	return Slim::Web::HTTP::CSRF->protectURI('plugins/SimpleLibraryViews/settings/basic.html');
}

sub prefs {
	return ($prefs, 'libraries');
}

sub handler {
	my ($class, $client, $params, $callback, @args) = @_;

	if ( $params->{'saveSettings'} ) {
		my $new = $params->{'pref_libraries'};
		@$new = grep { $_ ne '' } @$new;

		my %new     = map { $_ => 1 } @$new;
		my %current = map { $_ => 1 } @{ $prefs->get('libraries') || [] };

		for my $library (keys %new) {
			if (!$current{$library}) {
				Plugins::SimpleLibraryViews::Plugin::addLibraryView($library);
			}
		}

		for my $library (keys %current) {
			if ($library ne "") {
				if (!$new{$library}) {
					Plugins::SimpleLibraryViews::Plugin::removeLibraryView($library);
				}
			}
		}

		$prefs->set('libraries', @$new);
	}

	return $class->SUPER::handler($client, $params);
}

1;

__END__
