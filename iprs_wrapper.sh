#!/bin/bash

#######################################################################################################
##SET UP OPTIONS

while getopts a:b:cd:ef:ghi:lm:o:pt:T:v option
do
        case "${option}"
        in

                a) appl=${OPTARG};;
                b) outfilebase=${OPTARG};;
 		c) disableprecalc=true ;;
                d) outdir=${OPTARG};;
		e) disresanno=true ;;
                f) outformats=${OPTARG};;
                g) goterms=true ;;
		h) help=true ;;
		i) inputpath=${OPTARG};;
		l) lookup=true ;;
		m) minsize=${OPTARG};;
		o) outfilename=${OPTARG};;
		p) pathways=true ;;
		t) seqtype=${OPTARG} ;;
		T) tempdir=${OPTARG};;
		v) version=true;;
        esac
done
#####################################################################################################
if [[ "$help" = "true" ]] ; then
  echo "Options:
 -a  <ANALYSES>			            Optional, comma separated list of analyses.  If this option
                                            is not set, ALL analyses will be run.

 -b, <OUTPUT-FILE-BASE>   		    Optional, base output filename (relative or absolute path).
                                            Note that this option, the output directory (-d) option and
                                            the output file name (-o) option are mutually exclusive.  The
                                            appropriate file extension for the output format(s) will be
                                            appended automatically. By default the input file
                                            path/name will be used.

 -d,<OUTPUT-DIR>              		    Optional, output directory. Note that this option, the
                                            output file name (-o) option and the output file base (-b) option
                                            are mutually exclusive. The output filename(s) are the
                                            same as the input filename, with the appropriate file
                                            extension(s) for the output format(s) appended automatically .

 -c		                            Optional.  Disables use of the precalculated match lookup
                                            service.  All match calculations will be run locally.

 -e               			    Optional, excludes sites from the XML, JSON output

 -f <OUTPUT-FORMATS>             	    Optional, case-insensitive, comma separated list of output
                                            formats. Supported formats are TSV, XML, JSON, GFF3, HTML and
                                            SVG. Default for protein sequences are TSV, XML and
                                            GFF3, or for nucleotide sequences GFF3 and XML.

 -g		                            Optional, switch on lookup of corresponding Gene Ontology
                                            annotation (IMPLIES -l lookup option)

 -h	                                    Optional, display help information

 -i <INPUT-FILE-PATH>               	    Optional, path to fasta file that should be loaded on
                                            Master startup. Alternatively, in CONVERT mode, the
                                            InterProScan 5 XML file to convert.

 -l                     		    Also include lookup of corresponding InterPro
                                            annotation in the TSV and GFF3 output formats.

 -m <MINIMUM-SIZE>               	    Optional, minimum nucleotide size of ORF to report. Will
                                            only be considered if n is specified as a sequence type.
                                            Please be aware of the fact that if you specify a too
                                            short value it might be that the analysis takes a very long
                                            time!

 -o <EXPLICIT_OUTPUT_FILENAME>    	    Optional explicit output file name (relative or absolute
                                            path).  Note that this option, the output directory -d option
                                            and the output file basename -b option are mutually
                                            exclusive. If this option is given, you MUST specify a
                                            single output format using the -f option.  The output file
                                            name will not be modified. Note that specifying an output
                                            file name using this option OVERWRITES ANY EXISTING FILE.

 -p                             	    Optional, switch on lookup of corresponding Pathway
                                            annotation (IMPLIES -l lookup option)
 -t <SEQUENCE-TYPE>              	    Optional, the type of the input sequences (dna/rna (n)
                                            or protein (p)).  The default sequence type is protein.

 -T <TEMP-DIR>                  	    Optional, specify temporary file directory (relative or
                                            absolute path). The default location is temp/.
 -v                       		    Optional, display version number

Available analyses:
                      TIGRFAM (XX.X) : TIGRFAMs are protein families based on Hidden Markov Models or HMMs
                         SFLD (X.X) : SFLDs are protein families based on Hidden Markov Models or HMMs
                        ProDom (XXXX.X) : ProDom is a comprehensive set of protein domain families automatically generated from the UniProt Knowledge Database.
                        Hamap (XXXXXX.XX) : High-quality Automated and Manual Annotation of Microbial Proteomes
                        SMART (X.X) : SMART allows the identification and analysis of domain architectures based on Hidden Markov Models or HMMs
                          CDD (X.XX) : Prediction of CDD domains in Proteins
              ProSiteProfiles (XX.XXX) : PROSITE consists of documentation entries describing protein domains, families and functional sites as well as associated patterns and profiles to identify them
              ProSitePatterns (XX.XXX) : PROSITE consists of documentation entries describing protein domains, families and functional sites as well as associated patterns and profiles to identify them
                  SUPERFAMILY (X.XX) : SUPERFAMILY is a database of structural and functional annotation for all proteins and genomes.
                       PRINTS (XX.X) : A fingerprint is a group of conserved motifs used to characterise a protein family
                      PANTHER (X.X) : The PANTHER (Protein ANalysis THrough Evolutionary Relationships) Classification System is a unique resource that classifies genes by their functions, using published scientific experimental evidence and evolutionary relationships to predict function even in the absence of direct experimental evidence.
                       Gene3D (X.X.X) : Structural assignment for whole genes and genomes using the CATH domain structure database
                        PIRSF (X.XX) : The PIRSF concept is being used as a guiding principle to provide comprehensive and non-overlapping clustering of UniProtKB sequences into a hierarchical order to reflect their evolutionary relationships.
                         Pfam (XX.X) : A large collection of protein families, each represented by multiple sequence alignments and hidden Markov models (HMMs)
                        Coils (X.X) : Prediction of Coiled Coil Regions in Proteins
                   MobiDBLite (X.X) : Prediction of disordered domains Regions in Proteins"
  exit 0
fi
#####################################################################################################

ARGS=''

#IF STATEMENTS EXIST FOR EACH PARAMETER
if [ -n "${appl}" ]; then ARGS="$ARGS -appl $appl"; fi
if [ -n "${outfilebase}" ]; then ARGS="$ARGS -b $outfilebase"; fi
if [ -n "${outdir}" ]; then ARGS="$ARGS -d $outdir"; fi
if [ -n "${outformats}" ]; then ARGS="$ARGS -f $outformats"; fi
if [ -n "${inputpath}" ]; then ARGS="$ARGS -i $inputpath"; fi
if [ -n "${minsize}" ]; then ARGS="$ARGS -ms $minsize"; fi
if [ -n "${outfilename}" ]; then ARGS="$ARGS -o $outfilename"; fi
if [ -n "${seqtype}" ]; then ARGS="$ARGS -t $seqtype"; fi
if [ -n "${tempdir}" ]; then ARGS="$ARGS -T $tempdir"; fi
if [[ "$disableprecalc" = "true" ]]; then ARGS="$ARGS -c"; fi
if [[ "$disresanno" = "true" ]]; then ARGS="$ARGS -dra"; fi
if [[ "$goterms" = "true" ]]; then ARGS="$ARGS -goterms"; fi
if [[ "$help" = "true" ]]; then ARGS="$ARGS -help"; fi
if [[ "$lookup" = "true" ]]; then ARGS="$ARGS -iprlookup"; fi
if [[ "$pathways" = "true" ]]; then ARGS="$ARGS -pa"; fi
if [[ "$version" = "true" ]]; then ARGS="$ARGS -version"; fi

##EVERYTHING BELOW HERE IS GOANNA AND NEEDS TO BE CHANGED

######################################################################################################

##SPLIT FASTA INTO BLOCKS OF 1000

/usr/bin/splitfasta.pl $inputpath





#if [[ "$experimental" = "yes" ]]; then database="$database"'_exponly'; fi
#if [[ -z "$experimental" ]]; then database="$database"'_exponly'; fi
#name="$database"
#database='agbase_database/'"$database"'.fa'
#Dbase="$name"'.fa'


##MAKE BLAST INDEX
#test -f "/agbase_database/$Dbase" && makeblastdb -in /agbase_database/$Dbase -dbtype prot -parse_seqids -out $name
#test -f "agbase_database/$Dbase" && makeblastdb -in agbase_database/$Dbase -dbtype prot -parse_seqids -out $name
    
##RUN BLASTP
#blastp  -query $transcript_peps -db $name -out $out.asn -outfmt 11 $ARGS


##MAKE BLAST OUTPUT FORMATS 1 AND 6
#blast_formatter -archive $out.asn -out $out.html -outfmt 1 -html
#blast_formatter -archive $out.asn -out $out.tsv -outfmt '6 qseqid qstart qend sseqid sstart send evalue pident qcovs ppos gapopen gaps bitscore score'
#################################################################################################################

##FILTER BALST OUTPUT 6 (OPTIONALLY) BY %ID, QUERY COVERAGE, % POSITIVE ID, BITSCORE, TOTAL GAPS, GAP OPENINGS
#if [ -z "${perc_ID}" ]; then perc_ID="0"; fi
#if [ -z "${qcovs}" ]; then qcovs="0"; fi
#if [ -z "${perc_pos}" ]; then perc_pos="0"; fi
#if [ -z "${bitscore}" ]; then bitscore="0"; fi
#if [ -z "${gaps}" ]; then gaps="1000"; fi
#if [ -z "${gapopen}" ]; then gapopen="100"; fi
#awk -v x=$percID -v y=$qcovs -v z=$perc_pos -v w=$bitscore -v v=$gaps -v u=$gapopen '{ if(($8 > x) && ($9 > y) && ($10 > z) && ($13 > w) && ($12 < v) && ($11 < u)) { print }}' $out.tsv > tmp.tsv

##CALCULATE QUERY AND SUBJECT LENGTH COLUMNS AND ADD THEM TO OUTPUT 6
#awk 'BEGIN { OFS = "\t" } {print $1, $3-$2, $2, $3, $4, $6-$5, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14}' tmp.tsv > tmp2.tsv

##APPEND HEADER LINE TO OUTPUT 6
#echo -e "Query_ID\tQuery_length\tQuery_start\tQuery_end\tSubject_ID\tSubject_length\tSubject_start\tSubject_end\tE_value\tPercent_ID\tQuery_coverage\tPercent_positive_ID\tGap_openings\tTotal_gaps\tBitscore\tRaw_score" | cat - tmp2.tsv > temp && mv temp $out.tsv

##################################################################################################################
##PULL COLUMNS 1 AND 5 (QUERY ID AND SUBJECT ID) FOR ALL LINES EXCEPT HEADER
#tail --lines=+2 $out.tsv | awk -F "\t" '{print $1, $5}' > "blstmp.txt"

##REMOVE THE _ AND EVERYTHING AFTER FROM THE SUBJECT ID SO THAT IT WILL MATCH THE GOA FILE
#awk 'BEGIN {OFS = "\t"} {sub(/_.*/, "", $2); print $1, $2}'  blstmp.txt > blastids.txt

##MAKE KOABAS ANNOATATE INPUT FILE
#awk 'BEGIN {OFS = "\t"} {print $2}' blastids.txt | uniq > $out'_KOBAS_annotate_input.txt'

##SPLIT GOA DATABASE INTO SEVERAL TEMP FILES BASED ON THE NUMBER OF ENTRIES
#if [ ! -d ./splitgoa ]; then mkdir "splitgoa"; fi

#if [[ "$experimental" = "no" ]]
#then
#    test -f /go_info/gene_association.goa_uniprot && splitB.pl  "/go_info/gene_association.goa_uniprot" "splitgoa"
#    test -f ./go_info/gene_association.goa_uniprot && splitB.pl  "/go_info/gene_association.goa_uniprot" "splitgoa"
#elif [[ "$experimental" != "no" ]]
#then
#    test -f /go_info/gene_association_exponly.goa_uniprot && splitB.pl  "/go_info/gene_association_exponly.goa_uniprot" "splitgoa"
#    test -f ./go_info/gene_association_exponly.goa_uniprot && splitB.pl  "./go_info/gene_association_exponly.goa_uniprot" "splitgoa"
#fi

###PULL SUBSET OF GOA LINES THAT MATCHED BLAST RESULTS INTO GOA_ENTRIES.TXT
#cyverse_blast2GO.pl "blastids.txt" "splitgoa"

#OUTGAF VARIABLES COUNT FROM 1 TO CORRESPOND TO THE GAF FILE SPEC
#THESE WILL ALWAYS BE THE SAME AND CAN BE DECLARED OUTSIDE THE AWK STATEMENT

#outgaf1="user_input_db"
#outgaf15="user"
#outgaf13="taxon:0000"
#outgaf14=$(date +"%Y%m%d")
#outgaf6="GO_REF:0000024"
#outgaf7="ECO:0000247"
#outgaf12="protein"
#outgaf4=""
#outgaf11=""
#outgaf17=""
#prefix="UniprotKB:"

#THESE ARE OPTIONALLY USER-SPECIFIED DEFAULTS IN LIST ABOVE
#if [ -n "${gaf_db}" ]; then outgaf1="$gaf_db"; fi
#if [ -n "${assignedby}" ]; then outgaf15="$assignedby"; fi
#if [ -n "${gaf_taxid}" ]; then outgaf13="taxon:""$gaf_taxid"; fi

#PULLING COLUMNS FROM BLASTIDS.TXT AND GOA_ENTRIES.TXT AND  PRINTING TO NEW COMBINED FILE GOCOMBO; PULL INFO FROM GOCOMBO_TMP.TXT  AND DECLARED VARIABLES ABOVE TO MAKE GAF OUTPUT
#awk 'BEGIN {FS = "\t"}{OFS = "\t"} FNR==NR{a[$2]=$1;next}{ print a[$2], $0}' blastids.txt goa_entries.txt > gocombo_tmp.txt
#awk  -v a="$outgaf1" -v b="$outgaf15" -v c="$outgaf13" -v d="$outgaf14" -v e="$outgaf6" -v f="$outgaf7" -v g="$outgaf12" -v h="$outgaf4" -v i="$outgaf11" -v j="$outgaf17" -v k="$prefix" 'BEGIN {FS = "\t"}{OFS = "\t"}{print a,$1,$1,h,$6,e,f,(k$3),$10,$1,i,g,c,d,b,$18,j}' gocombo_tmp.txt > $out'_goanna_gaf.tsv'

##APPEND HEADER TO GAF OUTPUT
#sed -i '1 i\!gaf-version: 2.0' $out'_goanna_gaf.tsv'

##PULL COLUMNS FOR GO SLIM FILE
#awk 'BEGIN {FS ="\t"}{OFS = "\t"} {print $2,$5,$9}' $out'_goanna_gaf.tsv' > $out'_slim_input.txt'



##REMOVE FILES THAT ARE NO LONGER NECESSARY
#if [ -s $out'_slim_input.txt' ]
#then
#    rm goa_entries.txt
#    rm -r splitgoa
#    rm gocombo_tmp.txt
#    rm blstmp.txt
#    rm blastids.txt 
#    rm tmp.tsv
#    rm tmp2.tsv
#    rm *.phr
#    rm *.pin
#    rm *.pog
#   rm *.psd
#    rm *.psi
#    rm *.psq
#fi


