#!/usr/bin/perl -w

use strict;

use Data::Dump;
use Digest::SHA;
use File::Spec::Functions;
use File::Slurp;
use LWP::Simple;
use XML::Simple;

use constant REPO => 'repo.xml';
use constant REPO_URL => 'http://adhawkins.github.io/SimpleLibraryViews/' . REPO;

my $dir = shift @ARGV;

if (-d $dir) {
	my $file = "$dir.zip";
	my $manifest = catfile($dir, 'install.xml');
	my $version = '';

	if (-f $manifest) {
		my $xml = XMLin($manifest);
		if ($xml && ($version = $xml->{version})) {
			$file = "$dir-$version.zip";
		}
	}

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

	system('zip', '-r9', @exclude, $file, $dir);

	if ($?) {
		warn "Something went wrong: $?\n";
	}
	else {
		print "\nCalculating SHA checksum...\n";
		my $sha = Digest::SHA->new(1)->addfile($file)->hexdigest;
		print "$sha\t$file\n";

		if ( my $repo = get(REPO_URL) ) {
			print "\nWriting new repository file...";
			$repo =~ s/(plugin name="$dir".*?sha>)[\da-f]+/$1$sha/si;
			$repo =~ s/(plugin name="$dir".*?version=")[\d\.]+/$1$version/si;
			$repo =~ s/($dir-?[\d\.]*\.zip)/$file/sig;
			write_file(REPO, {binmode => ':utf8'}, $repo);

			my ($newRepo) = $repo =~ /(\s*<plugin name="$dir.*?\/plugin>)/si;
			print $newRepo;
		}
		print "\nDone!\n";
	}
}
else {
	warn "No '$dir' folder found\n";
}
