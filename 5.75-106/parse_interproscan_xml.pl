#!/usr/bin/perl -w
#
# script: parse_interproscan_xml.pl
#
# 10/2013 CRG Modified for InterProScan5 XML output
#
# Parameters:
# -f output folder from interproscan (required)
# -d database (required) 
# -t taxon (required)
# -y type (transcript, protein) (required)
# -n biocurator name (required)
# -m mapping file (optional)
# -b bad_input_seq file (optional)
# -h help message (optional)
#
use strict;
use Getopt::Std;
use File::Basename;
use Text::ParseWords;
use File::Copy;
getopts('d:t:y:n:m:b:f:h');

our ($opt_d, $opt_t, $opt_y, $opt_n, $opt_f, $opt_m, $opt_b, $opt_i, $opt_h);

##########################
# global variables
##########################

my ($output_filename,%acc_interpro, %acc_go,%acc_pathway,%interpro_names,%go_names,
    %mapping_hash,%acc_hash,%acc_name_hash,$currDate);

opendir(DIR, "$opt_f");
my @files = grep(/\.xml$/,readdir(DIR));
closedir(DIR);

foreach my $file (@files) {
   $opt_i = $file;
}

##########################
# subroutine definitions
##########################
sub check_opts;
sub parse_xml($$$);
sub parse_mapping_file($);
sub trim_tag($$);
sub trim_space($);
sub parse_string($);
sub remap_bad_input($$);
sub generate_interpro_output($);
sub generate_go_output($);
sub generate_pathway_output($);
sub generate_gaf_output($$$$$);

##########################
# MAIN
##########################

&check_opts; 

&parse_xml ($opt_i,$output_filename, $opt_y);

&parse_mapping_file($opt_m);

&remap_bad_input($opt_b,$opt_y);

&generate_interpro_output($output_filename);
   undef(%acc_interpro);
   undef(%interpro_names);

&generate_go_output($output_filename);

&generate_pathway_output($output_filename);
    undef(%acc_pathway);

&generate_gaf_output($output_filename,$opt_y,$opt_t,$opt_d,$opt_n);
    undef(%acc_go);
    undef(%go_names);


###################
##  SUBROUTINES  ##
###################
                 ##########################################################
                 ##  parse_xml file                                      ##
                 ##  Returns hashes of interpro, go and pathway data     ##
                 ##########################################################
sub parse_xml($$$) {
   my ($err_fh, $err_file, $input_file,$output_file,
    $results, $xref_id, $interpro_id, $type, @xref_array
   );

  $xref_id = $interpro_id = $type = '';
  @xref_array=();

   $input_file = shift;
   $output_file = shift;
   $type = shift;
  
  $err_file = $output_file . '.err';
  open($err_fh,">$err_file");
  open(INFILE, "<$opt_f\/$input_file");
  while (<INFILE>){
    my $line;
    $line = $_;
    next unless $line =~ m/(\<protein\>|\<xref|\<entry|\<go-xref|\<pathway-xref|\<\/protein\>)/;
    $line =~ s/\'/\\\'/g; 
     if ($line =~ m/\s*<protein>/) {
         $xref_id = $interpro_id = '';
         @xref_array=();
     }
     elsif ($line =~ m/\s*<\/protein>/) {
         $xref_id = $interpro_id = '';
         @xref_array=();
     }
     elsif ($line =~ m/\s*<xref(.*)/) {
        $xref_id= $interpro_id = ''; 
        $line = &trim_tag($line,'xref');
        my $hash = &parse_string($line);  
        if (exists ${$hash}{'id'}) { 
            $xref_id = ${$hash}{'id'}; 
                                      # for nt sequences remove the 'orf' extension
            if ($type eq 'transcript') { 
               if ($xref_id =~ m/^(.*?)\_(\d+)_(\d+)$/) {
                  $xref_id = $1; 
               } 
            }
                    #  print "xref tag id: $xref_id\n";
            $acc_hash{$xref_id} = undef; 
            push(@xref_array,$xref_id);
        }
        else { print $err_fh "$line\tUnable to parse xref_id\n"; }
     } # xref input line
     elsif ($line =~ m/\s*<entry(.*)/) {
        if (!defined $xref_id || $xref_id eq '') { print $err_fh "$line\txref_id undefined\n"; }
        else {
           my ($interpro_name, $interpro_type);
           $interpro_id = $interpro_type = $interpro_name =''; 
           $line = trim_tag($line,'entry');
           my $hash = parse_string($line);  
           if (exists ${$hash}{'ac'}) { $interpro_id= ${$hash}{'ac'}; }
           if (exists ${$hash}{'name'}) { $interpro_name= ${$hash}{'name'}; }
           if (exists ${$hash}{'type'}) { $interpro_type= ${$hash}{'type'}; }
           if (!defined $interpro_id || $interpro_id eq '') {
                 print $err_fh "$line\tUnable to parse interpro_id\n";
           }
           else {
              $interpro_names{$interpro_id} = "$interpro_type:$interpro_name";
              foreach my $a (@xref_array) {
                  $acc_interpro{$a}{$interpro_id} = undef;
                            # print "xref_id: $a interpro id: $interpro_id type: $interpro_type name: $interpro_name \n";
              }
           }
        } # have xref id
     } # interpro input line
     elsif ($line =~ m/\s*<go-xref(.*)/) {
        my $error_found=0; 
        if (!defined $xref_id || $xref_id eq '') { 
           print $err_fh "$line\txref_id undefined\n"; 
           $error_found=1;
        }
        if (!defined $interpro_id || $interpro_id eq '') { 
           print $err_fh "$line\tinterpro_id undefined\n"; 
           $error_found=1;
        }
        if (!$error_found) {
           $line = trim_tag($line,'go-xref');
           my ($go_id, $go_cat, $go_name);
           $go_id = $go_cat = $go_name =''; 
           my $hash = parse_string($line);  
           if (exists ${$hash}{'category'}) { $go_cat = ${$hash}{'category'}; }
           if (exists ${$hash}{'name'}) { $go_name= ${$hash}{'name'}; }
           if (exists ${$hash}{'id'}) { $go_id = ${$hash}{'id'}; }
           if (!defined $go_id|| $go_id eq '') { print $err_fh "$line\tUnable to parse go_id\n"; }
           else {
                                # ignore protein binding GO id
               if ($go_id eq 'GO:0005515') { ; } 
               else {
                  $go_names{$go_id} = "$go_cat|$go_name";
                  foreach my $a (@xref_array) {
                    $acc_go{$a}{$go_id}{$interpro_id} = undef;
                           # print "xref: $a interpro: $interpro_id go id: $go_id cat: $go_cat name: $go_name\n";
                  }
              }
           }
       } # no error found
     } # go input line
     elsif ($line =~ m/\s*<pathway-xref(.*)/) {
        my $error_found=0; 
        if (!defined $xref_id || $xref_id eq '') { 
           print $err_fh "$line\txref_id undefined\n"; 
           $error_found=1;
        }
        if (!defined $interpro_id || $interpro_id eq '') { 
           print $err_fh "$line\tinterpro_id undefined\n"; 
           $error_found=1;
        }
        if (!$error_found) {
           $line = trim_tag($line,'pathway-xref');
           my ($pathway_id,$pathway_db,$pathway_name);
           $pathway_id = $pathway_db = $pathway_name =''; 
           my $hash = parse_string($line);  
           if (exists ${$hash}{'db'}) { $pathway_db = ${$hash}{'db'}; }
           if (exists ${$hash}{'name'}) { $pathway_name= ${$hash}{'name'}; }
           if (exists ${$hash}{'id'}) { $pathway_id = ${$hash}{'id'}; }
           if (!defined $pathway_id || $pathway_id eq '' ||
               !defined $pathway_db || $pathway_db eq '') {
               print $err_fh "$line\tUnable to parse pathway db_id\n";
           }
           else {
                      #pathways for UniPathway have ID at pathway_level but names at sub-pathway level
                      #pathways for KEGG has IDs of kegg_pathways + enzyme_ids but name is KEGG pathway
               my $pathway_str = "$pathway_db: $pathway_id";
               foreach my $a (@xref_array) {
                     # print "pathway id: $pathway_id db: $pathway_db str: $pathway_str  name: $pathway_name a:$a \n";
                    $acc_pathway{$a}{$pathway_str}{$pathway_name} = undef;
               }
           }
       } # no error found
     } # pathway input line
   } # while xml line  parsed
 close $err_fh;
} # end of parse_xml subroutine

                 #############################
                 ##  trim_whitespace and    ##
                 ##   left/right brackets   ##
                 ##  Returns trimmed string ##
                 #############################
sub trim_tag($$){
   my $str = shift;
   my $tag_id = shift;
   $str =~ s/\s*<$tag_id(.*)/$1/;
   $str =~ s/(.*)\/>/$1/;  # remove ending tag brackets format \>
   $str =~ s/(.*)>/$1/;  # remove ending tag brackets format >
   $str = trim_space($str);
  return $str;
}

                 #############################
                 ##  trim_whitespace        ##
                 ##  Returns trimmed string ##
                 #############################
sub trim_space($){
   my $str = shift;
   $str =~ s/^\s+//; #remove leading spaces
   $str =~ s/\s+$//; #remove trailing spaces
  return $str;
}
                 #############################
                 ##  divide xml string into ##
                 ##  a hash                 ##
                 #############################
sub parse_string($) {
    my $str  = shift;
    my @arr = quotewords('\s+', 1, $str);   # split into pairs
    my %hash = quotewords('=', 0, @arr);   # split into key + value
    return \%hash;
}


               ###################################
               ##  build mapping hash
               ## (mapped_id to orig hdr lines)
               ###################################
sub parse_mapping_file($){
  my $input_mapping_file=shift;
  if (defined $input_mapping_file && $input_mapping_file ne '' 
     && -e $input_mapping_file && -s $input_mapping_file) {
     my ($map_fh);
     open($map_fh, "<$input_mapping_file") || die "Cannot open $input_mapping_file for reading.\n";
     while (my  $line = <$map_fh>) {
        chomp($line);
        my ($mapped_id, $generated_id, $acc_name );
        $mapped_id = $generated_id = $acc_name =  '';

        ($mapped_id, $generated_id)= split(/\t/,$line,2);

                    # a 'NCBI' formatted header?
     if (($mapped_id =~ m/^gi\|\d+\|(ref|gb|emb|embl|dbj|refseq)\|(.*?)\|\s*(.*)$/)  ) {
         my $new_id='';
        $new_id = $2;
        $acc_name = $3;
        if ($new_id =~ m/(.*?)\..*?/) { $new_id = $1; } # remove any release/version numbers
        $acc_name =~ s/^$new_id\s+(.*)/$1/g;  # remove accession id from the name_
        $mapped_id = $new_id;
     }
     else { $acc_name = $mapped_id; }

     $mapped_id = trim_space($mapped_id);
     $mapping_hash{$generated_id} = $mapped_id;

     $acc_name =~ s/(\r|\n>)//g;
     $acc_name =~ s/(\\|\/)/_/;  # replace slashes (forward and backward) with _
     if ($acc_name =~ /\|$/) { $acc_name =~ s/\|$//; }  # REMOVE TRAILING | chars
     if ($acc_name =~ /^(.*)\|(.*)$/) { $acc_name = $2; } # get name if follows |
     $acc_name = trim_space($acc_name);

     $acc_name_hash{$generated_id} = $acc_name ;
  } # while input lines
 close $map_fh;
} # have a mapping file
else {
    # generate 'fake' mapping based on results...
    #  fyi: interproscan used something like
    # EMBOSS Seqret to extract ids from fasta hdrs
    # therefore should not have a 'ncbi formatted' result line
    #
     foreach my $k (keys %acc_hash) {
        $mapping_hash{$k} = $k;
        $acc_name_hash{$k} = $k;
      } # while results records
} # else generate mapping from results
} # end of mapping_hash subroutine

                 #########################################
                 ##  Remap the input bad file
                 ##  with the mapping ids to get
                 ##  back to original fasta header ids
                 ##
                 ## for transcripts (ORF _ extensions)
                 ## add back the _ extension
                 #########################################
sub remap_bad_input($$) {
   my ( $input_bad_file, $temp_bad_file,$bad_fh, $temp_fh,$type);

   $input_bad_file=shift;
   $type=shift;

  if (defined $input_bad_file && -e $input_bad_file && -s $input_bad_file) {
      $temp_bad_file = $input_bad_file . 'new';
      open ($bad_fh,"<$input_bad_file") || die "Cannot open $input_bad_file for reading.\n";;
      open ($temp_fh,">$temp_bad_file") || die "cannot open $temp_bad_file for writing.\n";
      while (my $line = <$bad_fh>) {
         chomp($line);
         if ($line =~ m/^>/) {
              my $new_id='';
              my $orf_ext = '';

              $line =~ s/>//;
              $line = trim_space($line);

                     # for nt sequences break out the 'orf' extension
              if ($type  eq 'transcript') {
               if ($line =~ m/^(.*?)\_(\d+)_(\d+)$/) {
                     $line  = $1;
                     $orf_ext=$2 . '_' .  $3;
                }
              }
              if (exists $mapping_hash{$line}) { 
                $new_id = $mapping_hash{$line}; 
              }
              else { $new_id = $line; }
              if ($type  eq 'transcript' && $orf_ext ne '') { 
                       $new_id = $new_id . '_' . $orf_ext; 
              }
              print $temp_fh ">$new_id\n";
         } # fasta header line
         else { print $temp_fh "$line\n"; }
     }
     close $bad_fh;
     close $temp_fh;
     move $temp_bad_file, $input_bad_file;
  } # have an input bad file
} # end of remap_bad_input 

                 #############################################################
                 ##  generate_interpro_output                               ##
                 ##  outputs interpro counts by input_acc and interpro_id   ##
                 #############################################################
sub generate_interpro_output($) {
   my ($oname, $interpro_fh, $output_interpro_file, $output_interpro_file2, $interpro_fh2,
   %iea_cnt_hash);
   %iea_cnt_hash=();

  $oname=shift;
  $output_interpro_file = $oname . '_acc_interpro_counts.txt';
  open($interpro_fh, ">$output_interpro_file") || die "Cannot open $output_interpro_file for writing.\n";
  print $interpro_fh "Accession_ID\tInterPro_Count\tInterPro_IDs\tInterPro_Types_and_Names\n";
  foreach my $acc (keys %acc_interpro) {
       my ($interpro_str, $int_count, $interpro_name_str, $mapped_id);
       $interpro_str =  $interpro_name_str = $mapped_id = '';
       $mapped_id = $mapping_hash{$acc};
       $int_count = keys %{$acc_interpro{$acc}};
       while (my ($ipr) = each %{$acc_interpro{$acc}}) {
              if ($interpro_str ne '') { $interpro_str .= ';'; }
              $interpro_str .= $ipr;

              $iea_cnt_hash{$ipr}{$mapped_id}=undef;

              my $iname = $interpro_names{$ipr};
              if ($interpro_name_str ne '') { $interpro_name_str .= ';'; }
              $interpro_name_str .= '"' . $iname . '"';
          
      } # while
      print $interpro_fh "$mapped_id\t$int_count\t$interpro_str\t$interpro_name_str\n";
 } # foreach acc_interpro
 close $interpro_fh;

 $output_interpro_file2 = $oname . '_interpro_counts.txt';
 open($interpro_fh2, ">$output_interpro_file2") || die "Cannot open $output_interpro_file2 for writing.\n";
 print $interpro_fh2 "InterPro_ID\tInterPro_Type_and_Name\tAccession_Count\tAccession_IDs\n";
 foreach my $ipr (keys %iea_cnt_hash) {
   my ($acc_str, $acc_count, $interpro_name);
   $acc_str =  $interpro_name = '';
   $acc_count=0;
   $interpro_name = $interpro_names{$ipr};
   $acc_count = keys %{$iea_cnt_hash{$ipr}};
   while (my ($acc) = each %{$iea_cnt_hash{$ipr}}) {
          if ($acc_str ne '') { $acc_str .= ';'; }
          $acc =~ s/\;/\./g;  # just in case someone has a ; in the id line
          $acc_str .=  $acc ;
   } # while
   print $interpro_fh2 "$ipr\t$interpro_name\t$acc_count\t$acc_str\n";
} #while each interpro id
undef(%iea_cnt_hash);
close $interpro_fh2;

} # end of generate_interpro_output

                 #############################################################
                 ##  generate_go output                                     ##
                 ##  outputs go counts by input_acc and go_id               ##
                 #############################################################
sub generate_go_output($) {
   my ($oname, $go_fh, $output_go_file, $output_go_file2, $go_fh2,
   %go_cnt_hash);
   %go_cnt_hash=();

  $oname=shift;
  $output_go_file = $oname . '_acc_go_counts.txt';
  open($go_fh, ">$output_go_file") || die "Cannot open $output_go_file for writing.\n";
  print $go_fh "Accession_ID\tGO_Count\tBP_GO_IDs\tBP_GO_Names\tMF_GO_IDs\tMF_GO_Names\tCC_GO_IDs\tCC_GO_Names\n";
  foreach my $acc (keys %acc_go) {
     my ($go_count, $bp_str, $bp_name_str, $aspect, $mf_str, $mf_name_str,
      $cc_str, $cc_name_str, $go_name, $mapped_id,$go_str, );
     $mapped_id = $aspect = $go_str = $bp_str = $mf_str = $cc_str = '';
     $go_name= $bp_name_str = $mf_name_str = $cc_name_str = '';
     $mapped_id = $mapping_hash{$acc};
     $go_count = keys %{$acc_go{$acc}};

     while (my ($go) = each %{$acc_go{$acc}}) {
           $go_str = $go_names{$go};
          ($aspect,$go_name) = split(/\|/,$go_str,2);
          $go_cnt_hash{$go}{$mapped_id}=undef;
  
          if (uc($aspect) eq 'BIOLOGICAL_PROCESS') {
                 if ($bp_str ne '') { $bp_str .= ';'; }
              $bp_str .= $go;
                 if ($bp_name_str ne '') { $bp_name_str .= ';'; }
              $bp_name_str .= '"' . $go_name . '"';
         }
         elsif (uc($aspect) eq 'MOLECULAR_FUNCTION') {
                 if ($mf_str ne '') { $mf_str .= ';'; }
              $mf_str .= $go;
                 if ($mf_name_str ne '') { $mf_name_str .= ';'; }
              $mf_name_str .= '"' . $go_name . '"';
         }
         elsif (uc($aspect) eq 'CELLULAR_COMPONENT') {
                 if ($cc_str ne '') { $cc_str .= ';'; }
              $cc_str .= $go;
                 if ($cc_name_str ne '') { $cc_name_str .= ';'; }
              $cc_name_str .= '"' . $go_name . '"';
         }
     } # while
     print $go_fh "$mapped_id\t$go_count\t$bp_str\t$bp_name_str\t$mf_str\t$mf_name_str\t$cc_str\t$cc_name_str\n";
  }
  close $go_fh;

  $output_go_file2 = $oname . '_go_counts.txt';
  open($go_fh2, ">$output_go_file2") || die "Cannot open $output_go_file2 for writing.\n";
  print $go_fh2 "GO_ID\tGO_Name\tAspect\tAccession_Count\tAccessions\n";
  foreach my $go (keys %go_cnt_hash) {
     my ($acc_str, $go_str, $acc_count, $aspect, $rest,$go_name);
     $acc_str =  $go_name = $aspect = '';
     $acc_count=0;
     $acc_count = keys %{$go_cnt_hash{$go}};

     $go_str = $go_names{$go};
     ($aspect,$go_name) = split(/\|/,$go_str,2);
     $aspect = join '', map { ucfirst lc } split /(_)/, $aspect;

     while (my ($acc) = each %{$go_cnt_hash{$go}}) {
       if ($acc_str ne '') { $acc_str .= ';'; }
          $acc =~ s/\;/\./g;  # just in case someone has a ; in the id line
          $acc_str .=  $acc ;
    } # while
    print $go_fh2 "$go\t$go_name\t$aspect\t$acc_count\t$acc_str\n";
} # foreach record
undef(%go_cnt_hash);
close $go_fh2;
} # end of generate_go_output routine 

                 #############################################################
                 ##  generate_pathway output                                ##
                 ##  outputs pathway counts by input_acc and pathway_id     ##
                 #############################################################
sub generate_pathway_output($) {
   my ($oname, $pathway_fh, $output_pathway_file, $output_pathway_file2, $pathway_fh2,
   %pathway_cnt_hash, );
   %pathway_cnt_hash=();

  $oname=shift;
  $output_pathway_file = $oname . '_acc_pathway_counts.txt';
  open($pathway_fh, ">$output_pathway_file") || die "Cannot open $output_pathway_file for writing.\n";
  print $pathway_fh "Accession_ID\tPathway_Count\tPathway_IDs\tPathway_Names\n"; 
  foreach my $acc (keys %acc_pathway) {
     my ($pathway_str, $pathway_name_str, $mapped_id, $pathway_count,%seen_data);
     $pathway_str = $pathway_name_str = $mapped_id =  '';
      %seen_data=();
     $pathway_count=0;
     $mapped_id = $mapping_hash{$acc};
     while ((my $path = each %{ $acc_pathway{$acc} } )) {
           while ((my $path_name = each %{ $acc_pathway{$acc}{$path} } )) { 
                my $seen_str=$acc .  $path . $path_name;
                if (not exists $seen_data{$seen_str}) { 
                    $seen_data{$seen_str}=undef;
                    $pathway_count++;
                    if ($pathway_str ne '') { $pathway_str .= ';'; }
                        $pathway_str .= $path;
                    if ($pathway_name_str ne '') { $pathway_name_str .= ';'; }
                        $pathway_name_str .= '"' . $path_name . '"';
                    my $pstr = "$path|$path_name";
                   $pathway_cnt_hash{$pstr}{$mapped_id}=undef;
               } # unique values 
           } # path_name loop
     } # path loop 
     print $pathway_fh "$mapped_id\t$pathway_count\t$pathway_str\t$pathway_name_str\n";
  } # foreach acc - pathway hash entry
  close $pathway_fh;

  $output_pathway_file2 = $oname . '_pathway_counts.txt';
  open($pathway_fh2, ">$output_pathway_file2") || die "Cannot open $output_pathway_file2 for writing.\n";
  print $pathway_fh2 "Pathway_ID\tPathway_Name\tAccession_Count\tAccessions\n";
  foreach my $path (keys %pathway_cnt_hash) {
     my ($pathway_name, $pathway_id, $pathway_count,$acc_str);
     $pathway_name = $pathway_id = $acc_str = '';
     $pathway_count=0;

     $pathway_count = keys %{$pathway_cnt_hash{$path}};

     ($pathway_id, $pathway_name) = split(/\|/,$path,2); 

     while ((my $acc = each %{ $pathway_cnt_hash{$path} } )) {
          if ($acc_str ne '') { $acc_str .= ';'; }
          $acc =~ s/\;/\./g;  # just in case someone has a ; in the id line
          $acc_str .=  $acc ;
    } # while acc
    print $pathway_fh2 "$pathway_id\t$pathway_name\t$pathway_count\t$acc_str\n";
 } # foreach  pathway hash entry
 undef(%pathway_cnt_hash);
 close $pathway_fh2;

} # end of generate_pathway_output routine 


                 #############################################################
                 ##  generate_gaf output                                    ##
                 ##  outputs gaf(gene association file)                     ##
                 #############################################################
sub generate_gaf_output($$$$$) {

   my ($oname, $gaf_fh, $output_gaf_file, $date, $obj_type,$taxon,$db,$assigned); 
   $date=$obj_type=$taxon=$db=$assigned='';

   $date = get_date();

  $oname=shift;
  $obj_type = shift;
  $taxon = shift;
  $db = shift;
  $assigned = shift;

  $output_gaf_file = $oname . '_gaf.txt';

  open($gaf_fh, ">$output_gaf_file") || die "Cannot open $output_gaf_file for writing.\n";
#  print $gaf_fh "Database\tDB_Object_ID\tDB_Object_Symbol\tQualifier\tGO_ID\tDB_Reference\tEvidence_Code\tWith_From\tAspect\tDB_Object_Name\tDB_Object_Synonyms\tDB_Object_Type\tTaxon\tDate\tAssigned_By\tAnnotation_Extension\tGene_Product_Form_Id\n";

  foreach my $acc (sort keys %acc_go) {
     if ($acc eq '0' || $acc eq '') { next; }
  
     my ($db_object_id, $db_object_name);
     $db_object_id = $db_object_name = '';
  
     $db_object_id = $mapping_hash{$acc};
     $db_object_id = trim_space($db_object_id);
  
     if (exists $acc_name_hash{$acc}) { $db_object_name = $acc_name_hash{$acc}; }
     else { $db_object_name = $acc; }
     $db_object_name = trim_space($db_object_name);

     foreach my $go_id (keys %{$acc_go{$acc}}) {
          my ($go_name, $aspect, $with_from);
          $go_name= $aspect=$with_from='';
          if (exists $go_names{$go_id}) {
              my $tfld = $go_names{$go_id};
              ($aspect,$go_name) = split(/\|/,$tfld,2);
           } # have the go_name and aspect
    
         if (uc($aspect) eq 'BIOLOGICAL_PROCESS') { $aspect = 'P'; }
         elsif (uc($aspect) eq 'MOLECULAR_FUNCTION') { $aspect = 'F'; }
         elsif (uc($aspect) eq 'CELLULAR_COMPONENT') { $aspect = 'C'; }
          
         my %seen_data=();
         foreach my $interpro_id (keys %{$acc_go{$acc}{$go_id}}) {
            if (not exists $seen_data{$interpro_id}) {
                 $seen_data{$interpro_id}=undef; 
                 if ($with_from ne '') { $with_from .= '|'; }
                 $with_from .= "InterPro:$interpro_id";
            }
         }
         print $gaf_fh "$db\t$db_object_id\t$db_object_id\t\t$go_id\tGO_REF:0000002\tIEA\t$with_from\t$aspect\t$db_object_name\t\t$obj_type\ttaxon:$taxon\t$date\t$assigned\t\t\n";
   } # foreach go_ids
} # foreach acc
close $gaf_fh;

 `sort -i $output_gaf_file -o $output_gaf_file`;

} # end of generate_gaf_output routine

                 ###########################
                 ##  get_date             ##
                 ##  Returns current date ##
                 ###########################
sub get_date {
     my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
        $year += 1900;
        $mon++;
        if($mon < 10) {   $mon = '0'.$mon; }
        if($mday < 10) { $mday = '0'.$mday; }
        $currDate = $year.$mon.$mday;
        return $currDate;
}
                ##############################
                ## validate user arguments ##
                ##############################
sub check_opts {
  if (defined $opt_h) {
     print STDERR <<END;

Usage:  perl $0 [-h] -f interproscan_folder -d database(GenBank|Private) -t taxon -y protein|transcript -n "biocurator name" [-m mapping_file] [-b input_bad_file]

Required parameters:
        -f interproscan results folder
        -d database (GenBank|Private)
        -t taxon (9913|9031)
        -y protein|transcript (type of sequence)
        -n biocurator name (e.g. "Cathy Gresham" use double quotes)

Optional parameters:
    -h displays this message
    -m mapping file (mapping between original fasta header id and S*oneup ids)
    -b input_bad_file (if sent input fasta thru validation process and kicked out some sequences
              this will map them back to original fasta headers)

Examples:
        % perl $0 -f iprs_results folder -d Private -t 9031 -y protein -n "Cathy Gresham"

    Print Help message
        % perl $0 -h
END
    exit;
  }
  if (!defined $opt_i || !$opt_i) { die "Invalid inteprroscan xml file. parameter -i .\n  Exiting now\n\n"; }
#  if ((!-f $opt_i) || (-z $opt_i ) || (!-r $opt_i)) { die "Input filename $opt_i must exist, be readable and contain records.\nExiting now.\n\n"; }

  if (!defined $opt_d || !$opt_d) { die "Invalid database. parameter -d .\n  Exiting now\n\n"; }

  if (!defined $opt_t || !$opt_t) { die "Invalid taxon. parameter -t .\n  Exiting now\n\n"; }
  if ($opt_t =~ m/^\d$/) { die "taxon parameter -t x${opt_t}x must be all numeric.\n\n"; } 

  if (!defined $opt_y || !$opt_y) { die "Invalid sequence type. Must be transcript or protein. parameter -y .\n  Exiting now\n\n"; }
  if ($opt_y ne 'transcript' && $opt_y ne 'protein') { die "Invalid sequence type. Must be transcript or protein. parameter -y \n Exiting now\n\n"; }

  if (!defined $opt_n || !$opt_n) { die "Invalid biocurator name.  use double quotes around the name. parameter -n .\n  Exiting now\n\n"; }

my @suffixes = (".txt", ".tsv", ".xml", ".csv");
my ($path,$suffix);
($output_filename,$path,$suffix) = fileparse($opt_i,@suffixes);


} #end of subroutine

exit;

