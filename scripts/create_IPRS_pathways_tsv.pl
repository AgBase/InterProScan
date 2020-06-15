#!/usr/bin/perl -w
# Solgenomics@BTI // ACBS@UoA
# Surya Saha June 10, 2020
# Purpose: Create a TSV with protein name and list of Reactome pathways from IPRS


unless (@ARGV == 1){
	print "USAGE: $0 <IPRS acc_pathway_counts.txt>\n";
	exit;
}

use strict;
use warnings;

my ($ifname,$protein,$pathways);

$ifname=$ARGV[0];
unless(open(IN,$ifname)){print "not able to open ".$ifname."\n\n";exit;}
unless(open(OUT,">$ifname.IPRS.pathways.tsv")){print "not able to open ".$ifname.".IPRS.pathways.tsv\n\n";exit;}


while (my $rec = <IN>){
	if ( $rec =~ /^Accession/){ next; }								#ignore header

	my @rec_arr = split ("\t", $rec);
	$protein = $rec_arr[0];
	$pathways = $rec_arr[2];

	if ( $pathways =~ /\;/ ){										#multiple pathways
		$pathways =~ s/Reactome: /,/g;
		$pathways =~ s/^,//;
		$pathways =~ s/\;//g;
		print OUT "$protein\t$pathways\n";
	}
	else{
		$pathways =~ s/Reactome: //;
		print OUT "$protein\t$pathways\n";	
	}
}


close (IN);
close (OUT);