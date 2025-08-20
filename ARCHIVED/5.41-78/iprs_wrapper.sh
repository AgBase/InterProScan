#!/usr/bin/bash
#######################################################################################################
##SET UP OPTIONS

##CHECK IF PARAMETER IS PASSED A CORRECT ARGUMENT OR THE NEXT PARAMETER DUE TO MISSING FILE NAME
check_argument(){
    # pass parameter and argument
    if [[ "$2" = -* ]] 
    then
        echo "Missing argument for parameter -$1"
        echo "$2 looks like another parameter and not the expected value. Please review help (run with -h) and do not use filenames starting with a '-' character"
        exit 1
    fi
}


## Exit if no params passed
if [ "$#" == 0 ]
then
  echo "No parameters were passed"
  echo "Please run with -h parameter to see help"
  exit 1
fi

## Exit if illegal parameter passed
if [[ "$@" != -* ]]
then
    echo "$@ looks like a illegal parameter. All parameters start with -"
    echo "Please run with -h parameter to see help"
    exit 1
fi

while getopts 'a:b:B:cC:d:D:ef:F:ghi:lm:M:n:o:pr:R:t:T:vx:y:' option
do
  case "${option}" in
    a) check_argument 'a' ${OPTARG}; appl=${OPTARG};;
    b) check_argument 'b' ${OPTARG}; outfilebase=${OPTARG};;
    B) check_argument 'B' ${OPTARG}; badseq=${OPTARG};;
    c) disableprecalc=true;;
    C) check_argument 'C' ${OPTARG}; cpus=${OPTARG};;
    d) check_argument 'd' ${OPTARG}; outdir=${OPTARG};;
    D) check_argument 'D' ${OPTARG}; db=${OPTARG};;
    e) disresanno=true ;;
    f) check_argument 'f' ${OPTARG}; outformats=${OPTARG};;
    F) check_argument 'F' ${OPTARG}; iprsoutdir=${OPTARG};;
    g) goterms=true;;
    h) help=true;;
    i) check_argument 'i' ${OPTARG}; inputpath=${OPTARG};;
    l) lookup=true;;
    m) check_argument 'm' ${OPTARG}; minsize=${OPTARG};;
    M) check_argument 'M' ${OPTARG}; mapfile=${OPTARG};;
    n) check_argument 'n' ${OPTARG}; biocurator=${OPTARG};;
    o) check_argument 'o' ${OPTARG}; outfilename=${OPTARG};;
    p) pathways=true;;
    r) check_argument 'r' ${OPTARG}; mode=${OPTARG};;
    R) check_argument 'R' ${OPTARG}; crid=${OPTARG};;
    t) check_argument 't' ${OPTARG}; seqtype=${OPTARG};;
    T) check_argument 'T' ${OPTARG}; tempdir=${OPTARG};;
    v) version=true;;
    x) check_argument 'x' ${OPTARG}; taxon=${OPTARG};;
    y) check_argument 'y' ${OPTARG}; type=${OPTARG};;
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

 -C					    Optional. Supply the number of cpus to use.

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

-r					    Optional. 'Mode' required ( -r 'cluster') to run in cluster mode. These options
					    are provided but have not been tested with this wrapper script. For
					    more information on running InterProScan in cluster mode: 
					    https://github.com/ebi-pf-team/interproscan/wiki/ClusterMode

-R					    Optional. Clusterrunid (crid) required when using cluster mode.
					    -R unique_id 
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
                   MobiDBLite (X.X) : Prediction of disordered domains Regions in Proteins

OPTIONS FOR XML PARSER OUTPUTS

-F <IPRS output directory> 		This is the output directory from InterProScan.
-D <database>				Supply the database responsible for these annotations.
-x <taxon>				NCBI taxon ID of the ID being annotated
-y <type>				Transcript or protein
-n <biocurator>				Name of the biocurator who made these annotations
-M <mapping file>			Optional. Mapping file.
-B <bad seq file>			Optional. Bad input sequence file." 				
  exit 0
fi
#####################################################################################################

ARGS=''

#IF STATEMENTS EXIST FOR EACH OPTIONAL PARAMETER
if [ -n "${appl}" ]; then ARGS="$ARGS -appl $appl"; fi
if [ -n "${outfilebase}" ]; then ARGS="$ARGS -b $outfilebase"; fi
if [ -n "${outdir}" ]; then ARGS="$ARGS -d $outdir"; fi
if [ -n "${outformats}" ]; then ARGS="$ARGS -f $outformats"; fi
if [ -n "${minsize}" ]; then ARGS="$ARGS -ms $minsize"; fi
if [ -n "${outfilename}" ]; then ARGS="$ARGS -o $outfilename"; fi
if [ -n "${seqtype}" ]; then ARGS="$ARGS -t $seqtype"; fi
if [ -n "${tempdir}" ]; then ARGS="$ARGS -T $tempdir"; fi
if [ -n "${cpus}" ]; then ARGS="$ARGS --cpu $cpus"; fi
if [ -n "${mode}" ]; then ARGS="$ARGS --mode $mode"; fi
if [ -n "${crid}" ]; then ARGS="$ARGS --crid $crid"; fi
if [[ "$disableprecalc" = "true" ]]; then ARGS="$ARGS --disable-precalc"; fi
if [[ "$disresanno" = "true" ]]; then ARGS="$ARGS -dra"; fi
if [[ "$goterms" = "true" ]]; then ARGS="$ARGS -goterms"; fi
if [[ "$help" = "true" ]]; then ARGS="$ARGS -help"; fi
if [[ "$lookup" = "true" ]]; then ARGS="$ARGS -iprlookup"; fi
if [[ "$pathways" = "true" ]]; then ARGS="$ARGS -pa"; fi
if [[ "$version" = "true" ]]; then ARGS="$ARGS -version"; fi

echo "Arguments for InterProScan: ${ARGS}"


######################################################################################################
inname=$(basename ${inputpath}| awk -F"." '{print $1}') ## does not assume any fixed extension

##REMOVE BAD CHARACTERS * - _ . FROM SEQS
# sed 's/\*//g' /data/$inputpath > /data/inputnostar.fasta
# sed -i 's/\-//g' /data/inputnostar.fasta 
# sed -i  's/\_//g' /data/inputnostar.fasta
# sed -i 's/\.//g' /data/inputnostar.fasta
while read LINE; do if echo $LINE| grep -q '>'; then echo $LINE; else echo $LINE| sed -e 's/\*//g' -e 's/\-//g' -e 's/\_//g' -e 's/\.//g'; fi;  done < /data/$inputpath > /data/inputnostar.fasta


##SPLIT FASTA INTO BLOCKS OF 1000
/usr/bin/splitfasta.pl -f /data/inputnostar.fasta -s query -o /data/split -r 1000

##PRINT NUMBER OF SEQS IN EACH SPLIT
echo "Number of sequences in each split fasta file"
grep -c '^>' /data/split/query*

##RUN IPRS
if [ ! -d /data/$outdir ]; then mkdir /data/$outdir; fi

parallel -j 100% /opt/interproscan/interproscan.sh -i {} -d /data/$outdir $ARGS ::: /data/split/query*


##MERGE SPLIT OUTPUTS
##ASSUMING OUTPUT FORMATS--TSV, XML, JSON, GFF3, HTML and SVG
find /data/$outdir  -type f -name "query.*.tsv" -print0 | xargs -0 cat -- >> /data/$outdir/"$inname"'.tsv'
find /data/$outdir  -type f -name "query.*.json" -print0 | xargs -0 cat -- >> /data/$outdir/"$inname"'.json'


##REMOVE XML HEADERLINES AND CAT FILES TOGETHER
xmlhead=$(head -n 1 /data/$outdir/query.0.xml)
find /data/$outdir  -type f -name "query.*.xml" -exec sed -i '1d' {} \;
find /data/$outdir  -type f -name "query.*.xml" -print0 | xargs -0 cat -- >> /data/$outdir/tmp.xml
echo -e "$xmlhead" | cat - /data/$outdir/tmp.xml > /data/$outdir/"$inname"'.xml'


##REMOVE GFF# HEADERLINES AND CAT FILES TOGETHER
gff3head=$(head -n 3 /data/$outdir/query.0.gff3)
find /data/$outdir  -type f -name "query.*.gff3" -exec sed -i '1,3d' {} \;
find /data/$outdir  -type f -name "query.*.gff3" -print0 | xargs -0 cat -- >> /data/$outdir/tmp.gff3
echo -e "$gff3head" | cat - /data/$outdir/tmp.gff3 > /data/$outdir/"$inname"'.gff3'


##CAT TOGETHER HTML AND SVG FILES
find /data/$outdir  -type f -name "query.*.html.tar.gz" -print0 | xargs -0 cat -- >> /data/$outdir/"$inname"'.html.tar.gz'
find /data/$outdir  -type f -name "query.*.svg.tar.gz" -print0 | xargs -0 cat -- >> /data/$outdir/"$inname"'.svg.tar.gz'


#REMOVE TEMPORARY FILES
rm /data/$outdir/query*
rm /data/$outdir/tmp*

##PARSE XML
outgaf12="protein"

#THESE ARE OPTIONALLY USER-SPECIFIED--DEFAULTS IN LIST ABOVE
if [ -n "${db}" ]; then outgaf1="$db"; else outgaf1="user_input_db"; fi
if [ -n "${biocurator}" ]; then outgaf15="$biocurator"; else outgaf15="user"; fi
if [ -n "${taxon}" ]; then outgaf13="$taxon"; else outgaf13="0000"; fi


echo "Parameters for cyverse_parse_ips_xml.pl: -f /data/${outdir} -d ${outgaf1} -t ${outgaf13} -n ${outgaf15} -y ${outgaf12}"
cyverse_parse_ips_xml.pl -f /data/$outdir -d $outgaf1 -t $outgaf13 -n $outgaf15 -y $outgaf12 

mv $inname'_acc_go_counts.txt' /data/$outdir
mv $inname'_acc_interpro_counts.txt' /data/$outdir
mv $inname'_acc_pathway_counts.txt' /data/$outdir
mv $inname'.err' /data/$outdir
mv $inname'_gaf.txt' /data/$outdir
mv $inname'_go_counts.txt' /data/$outdir
mv $inname'_interpro_counts.txt' /data/$outdir
mv $inname'_pathway_counts.txt' /data/$outdir

##REMOVE TEMP FILES
rm -r /data/split
rm /data/inputnostar.fasta
rm -r temp

