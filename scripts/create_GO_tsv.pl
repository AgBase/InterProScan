#!/usr/bin/perl -w
# Solgenomics@BTI // ACBS@UoA
# Surya Saha June 10, 2020
# Purpose: Create a TSV with protein name and list of GO terms from GOanna and IPRS


unless (@ARGV == 1){
	print "USAGE: $0 <sorted combined GAF>\n";
	exit;
}

use strict;
use warnings;

my ($ifname,$protein,$GOterms);

$ifname=$ARGV[0];
unless(open(IN,$ifname)){print "not able to open ".$ifname."\n\n";exit;}
unless(open(OUT,">$ifname.GOterms.tsv")){print "not able to open ".$ifname.".GOterms.tsv\n\n";exit;}


while (my $rec = <IN>){
	if ( $rec =~ /^!/){ next; }								#ignore comment

	my @rec_arr = split ("\t", $rec);
	if ( !defined $protein ){								#values for first protein
		$protein = $rec_arr[1];
		$GOterms = $rec_arr[4];
	}
	elsif ( defined $protein && $protein ne $rec_arr[1] ){	#new protein
		print OUT "$protein\t$GOterms\n";					#values for prev protein
		$protein = $rec_arr[1];
		$GOterms = $rec_arr[4];
	}
	else{
		$GOterms = $GOterms . ',' . $rec_arr[4]
	}
}


close (IN);
close (OUT);