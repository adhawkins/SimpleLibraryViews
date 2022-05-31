#!/usr/bin/perl -w

use strict;

use Digest::SHA;
use File::Spec::Functions;
use File::Slurp;
use LWP::Simple;
use XML::LibXML;

use constant DEFAULT_REPO => 'repo';

my $dir = shift @ARGV;
my $repoName = shift @ARGV;

if (! length $repoName) {
 $repoName = DEFAULT_REPO;
}

my $REPO_URL = "http://adhawkins.github.io/SimpleLibraryViews/$repoName.xml";

print "Dir: '$dir', repo: '" . $REPO_URL . "'\n";

if (-d $dir) {
	my $manifest = catfile($dir, 'install.xml');

	if (-f $manifest) {
		my $xml = XML::LibXML->load_xml(location => $manifest);
		if ($xml) {
			my $version = $xml->find('/extension/version')->to_literal();
			my $minTarget = $xml->find('/extension/targetApplication/minVersion')->to_literal();
			my $maxTarget = $xml->find('/extension/targetApplication/maxVersion')->to_literal();
			my $homepageURL = $xml->find('/extension/homepageURL')->to_literal();
			my $creator = $xml->find('/extension/creator')->to_literal();
			print("Version: '$version', min: '$minTarget', max: '$maxTarget'\n");
			my $file = "$dir-$version.zip";

			print "\nCompressing '$dir' to '$file'...\n\n";
			my @exclude = qw(
				--exclude=*.git*
				--exclude=*.DS_Store
				--exclude=*.svn*
				--exclude=*/.*
			);

			if (-e "$dir/exclude.lst") {
				push @exclude, "--exclude=$dir/exclude.lst", "--exclude=\@$dir/exclude.lst";
			}

			system('zip', '-q', '-r9', @exclude, $file, $dir);

			if ($?) {
				warn "Something went wrong: $?\n";
			}
			else {
				print "\nCalculating SHA checksum...\n";
				my $sha = Digest::SHA->new(1)->addfile($file)->hexdigest;
				print "$sha\t$file\n";

				my $repo = XML::LibXML->load_xml(location => $REPO_URL);

				my $pluginNode = $repo->find('/extensions/plugins/plugin')->get_node(1);
				$pluginNode->setAttribute('name', $dir);
				$pluginNode->setAttribute('version', $version);
				$pluginNode->setAttribute('minTarget', $minTarget);
				$pluginNode->setAttribute('maxTarget', $maxTarget);

				my $pluginURLNode = $repo->find('/extensions/plugins/plugin/url')->get_node(1);
				$pluginURLNode->removeChildNodes();
				$pluginURLNode->appendText("http://adhawkins.github.io/SimpleLibraryViews/$file");

				my $pluginLinkNode = $repo->find('/extensions/plugins/plugin/link')->get_node(1);
				$pluginLinkNode->removeChildNodes();
				$pluginLinkNode->appendText($homepageURL);

				my $pluginCreatorNode = $repo->find('/extensions/plugins/plugin/creator')->get_node(1);
				$pluginCreatorNode->removeChildNodes();
				$pluginCreatorNode->appendText($creator);

				my $pluginSHANode = $repo->find('/extensions/plugins/plugin/sha')->get_node(1);
				$pluginSHANode->removeChildNodes();
				$pluginSHANode->appendText($sha);

				$repo->toFile("$repoName.xml", 2);
				print $repo->toString(2);
			}
		} else {
			warn "Error loading manifest: '$manifest'\n";
		}
	} else {
		warn "No manifest found in '$dir'\n";
	}
}
else {
	warn "No '$dir' folder found\n";
}
