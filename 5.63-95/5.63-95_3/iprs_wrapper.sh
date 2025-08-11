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
    v) verbose=true;;
    x) check_argument 'x' ${OPTARG}; taxon=${OPTARG};;
    y) check_argument 'y' ${OPTARG}; type=${OPTARG};;
    \?) echo "No legal parameters were passed. Please run with -h parameter to see help"; exit 1;;
esac
done



#####################################################################################################
if [[ "$help" = "true" ]] ; then
  echo "Options:
 -a  <ANALYSES>			            Optional, comma separated list of analyses.  If this option
                                            is not set, ALL analyses will be run.

 -b <OUTPUT-FILE-BASE>   		    Optional, base output filename (relative or absolute path).
                                            Note that this option, the output directory (-d) option and
                                            the output file name (-o) option are mutually exclusive.  The
                                            appropriate file extension for the output format(s) will be
                                            appended automatically. By default the input file
                                            path/name will be used.

 -d <OUTPUT-DIR>              		    Optional, output directory. Note that this option, the
                                            output file name (-o) option and the output file base (-b) option
                                            are mutually exclusive. The output filename(s) are the
                                            same as the input filename, with the appropriate file
                                            extension(s) for the output format(s) appended automatically .

 -c		                            Optional.  Disables use of the precalculated match lookup
                                            service.  All match calculations will be run locally.

 -C					    Optional. Supply the number of cpus to use.

 -e               			    Optional, excludes sites from the XML, JSON output

 -f <OUTPUT-FORMATS>             	    Optional, case-insensitive, comma separated list of output
                                            formats. Supported formats are TSV, XML, JSON, GFF3. Default 
					    for protein sequences are TSV, XML and
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

 -p                             	    Optional, switch on lookup of corresponding Pathway
                                            annotation (IMPLIES -l lookup option)
 -t <SEQUENCE-TYPE>              	    Optional, the type of the input sequences (dna/rna (n)
                                            or protein (p)).  The default sequence type is protein.

 -T <TEMP-DIR>                  	    Optional, specify temporary file directory (relative or
                                            absolute path). The default location is temp/.

 -v                       		    Optional, verbose log output

-r					    Optional. 'Mode' required ( -r 'cluster') to run in cluster mode. These options
					    are provided but have not been tested with this wrapper script. For
					    more information on running InterProScan in cluster mode: 
					    https://github.com/ebi-pf-team/interproscan/wiki/ClusterMode

-R					    Optional. Clusterrunid (crid) required when using cluster mode.
					    -R unique_id 
Available analyses:
		      TIGRFAM (XX.X) : TIGRFAMs are protein families based on hidden Markov models (HMMs).
                         SFLD (X) : SFLD is a database of protein families based on hidden Markov models (HMMs).
                  SUPERFAMILY (X.XX) : SUPERFAMILY is a database of structural and functional annotations for all proteins and genomes.
                      PANTHER (XX.X) : The PANTHER (Protein ANalysis THrough Evolutionary Relationships) Classification System is a unique resource that classifies genes by their functions, using published scientific experimental evidence and evolutionary relationships to predict function even in the absence of direct experimental evidence.
                       Gene3D (X.X.X) : Structural assignment for whole genes and genomes using the CATH domain structure database.
                        Hamap (XXXX_XX) : High-quality Automated and Manual Annotation of Microbial Proteomes.
              ProSiteProfiles (XXX_XX) : PROSITE consists of documentation entries describing protein domains, families and functional sites as well as associated patterns and profiles to identify them.
                        Coils (X.X.X) : Prediction of coiled coil regions in proteins.
                        SMART (X.X) : SMART allows the identification and analysis of domain architectures based on hidden Markov models (HMMs).
                          CDD (X.XX) : CDD predicts protein domains and families based on a collection of well-annotated multiple sequence alignment models.
                       PRINTS (XX.X) : A compendium of protein fingerprints - a fingerprint is a group of conserved motifs used to characterise a protein family.
                        PIRSR (XXXX_XX) : PIRSR is a database of protein families based on hidden Markov models (HMMs) and Site Rules.
              ProSitePatterns (XXXX_XX) : PROSITE consists of documentation entries describing protein domains, families and functional sites as well as associated patterns and profiles to identify them.
                      AntiFam (X.X) : AntiFam is a resource of profile-HMMs designed to identify spurious protein predictions.
                         Pfam (XX.X) : A large collection of protein families, each represented by multiple sequence alignments and hidden Markov models (HMMs).
                   MobiDBLite (X.X) : Prediction of intrinsically disordered regions in proteins.
                        PIRSF (X.XX) : The PIRSF concept is used as a guiding principle to provide comprehensive and non-overlapping clustering of UniProtKB sequences into a hierarchical order to reflect their evolutionary relationships.

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
if [ -n "${outdir}" ]; then ARGS="$ARGS -d $outdir"; fi
if [ -n "${outformats}" ]; then ARGS="$ARGS -f $outformats"; fi
if [ -n "${minsize}" ]; then ARGS="$ARGS -ms $minsize"; fi
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
if [[ "$verbose" = "true" ]]; then ARGS="$ARGS -verbose"; fi

if [[ -n "${outdir}"  ]]; then innopath=$(basename ${inputpath}) && inname="${innopath%.*}";  fi
if [[ -n "${outfilebase}" ]]; then outdir=""; fi
if [[ -n "${outfilebase}" ]]; then inname="$outfilebase" && outfilebase="query" ; fi
#THIS LINE WOULD BE ABOVE IN 'ARGS' BUT SINCE I NEED TO RESET IT TO 'QUERY' FIRST IT IS HERE
if [ -n "${outfilebase}" ]; then ARGS="$ARGS -b $outfilebase"; fi

echo "Arguments for InterProScan: ${ARGS}"

######################################################################################################

#echo "outdir is:" $outdir
#echo "outfilebase is:" $outfilebase
#echo "inname is:" $inname
#echo "innopath is:" $innopath

##REMOVE BAD CHARACTERS * - _ . FROM SEQS

grep -E "(^>|A|R|N|O|B|C|E|Q|C|G|H|I|L|K|M|F|P|S|T|W|Y|V)" /data/$inputpath > /data/inputnostar.fasta
awk 'BEGIN {RS = ">" ; FS = "\n" ; ORS = ""} $2 {print ">"$0}' /data/inputnostar.fasta > /data/output.fasta
while read LINE; do if echo $LINE| grep -q '>'; then echo $LINE; else echo $LINE| sed -e 's/\*//g' -e 's/\-//g' -e 's/\_//g' -e 's/\.//g'; fi;  done < /data/output.fasta > /data/inputnostar.fasta


##SPLIT FASTA INTO BLOCKS OF 1000
/usr/bin/splitfasta.pl -f /data/inputnostar.fasta -s query -o /data/split -r 1000

##PRINT NUMBER OF SEQS IN EACH SPLIT
echo "Number of sequences in each split fasta file"
grep -c '^>' /data/split/query*

##GETS THE NUMBER OF SPLIT FILES FOR USE BELOW
splits=$(find /data/split -type f -name query.*  2>/dev/null | wc -l)

##RUN IPRS
if [ ! -d /data/$outdir ]; then mkdir /data/$outdir; fi

parallel -j 100% --joblog iprs.log /opt/interproscan/interproscan.sh -i {} $ARGS ::: /data/split/query*

outcount=$(find /data/$outdir/ -type f -name 'query*xml'  2>/dev/null | wc -l)

#echo "outcount is:" $outcount
#echo "splits is:" $splits

if [ "$outcount" -ge "$splits" ]
then
	##MERGE SPLIT OUTPUTS
	##ASSUMING OUTPUT FORMATS--TSV, XML, JSON, GFF3
	if [[ -f query.tsv ]]
	then
		find /data/$outdir  -type f -name "query*tsv" -print0 | xargs -0 cat -- >> /data/$outdir/"$inname"'.tsv'
		#find . -type f -regextype posix-extended -regex /data/$outdir/query'[._][0-9]+\..tsv' -print0 | xargs -0 rm
		rm query*tsv
	elif [[ -f query.0.tsv ]]
	then
		find /data/$outdir  -type f -name "query*tsv" -print0 | xargs -0 cat -- >> /data/$outdir/"$inname"'.tsv'
		#find . -type f -regextype posix-extended -regex /data/$outdir/query'[._][0-9]+\..tsv' -print0 | xargs -0 rm
		rm query*tsv
	fi

	if [[ -f query.json ]]
	then
		find /data/$outdir  -type f -name "$query*json" -print0 | xargs -0 cat -- >> /data/$outdir/"$inname"'.json'
		#find . -type f -regextype posix-extended -regex /data/$outdir/query'[._][0-9]+\..json' -print0 | xargs -0 rm
		rm query*json
	elif [[ -f query.0.json ]]
	then
		find /data/$outdir  -type f -name "$query*json" -print0 | xargs -0 cat -- >> /data/$outdir/"$inname"'.json'
		#find . -type f -regextype posix-extended -regex /data/$outdir/query'[._][0-9]+\..json' -print0 | xargs -0 rm
		rm  query*json
	fi

	##REMOVE XML HEADERLINES TAILLINES AND CAT FILES TOGETHER
	if [[ -f query.xml ]]
	then
		xmlhead=$(head -n 1 /data/$outdir/query.xml)
		xmltail=$(tail -1 /data/$outdir/query.xml)
		find /data/$outdir  -type f -name "query*xml" -exec sed -i '1d' {} \;
		find /data/$outdir  -type f -name "query*xml" -exec sed -i '$d' {} \;
		find /data/$outdir  -type f -name "query*xml" -print0 | xargs -0 cat -- >> /data/$outdir/tmp.xml
		echo -e "$xmlhead" | cat - /data/$outdir/tmp.xml > /data/$outdir/"$inname"'.xml'
		echo -e "$xmltail" >>  /data/$outdir/"$inname"'.xml'
		#find . -type f -regextype posix-extended -regex /data/$outdir/query'[._][0-9]+\..xml' -print0 | xargs -0 rm
		rm query*xml
	elif [[ -f query.0.xml ]]
	then
		xmlhead=$(head -n 1 /data/$outdir/query.0.xml)
		xmltail=$(tail -1 /data/$outdir/query.0.xml)
		find /data/$outdir  -type f -name "query*xml" -exec sed -i '1d' {} \;
		find /data/$outdir  -type f -name "query*xml" -exec sed -i '$d' {} \;
		find /data/$outdir  -type f -name "query*xml" -print0 | xargs -0 cat -- >> /data/$outdir/tmp.xml
		echo -e "$xmlhead" | cat - /data/$outdir/tmp.xml > /data/$outdir/"$inname"'.xml'
		echo -e "$xmltail" >>  /data/$outdir/"$inname"'.xml'
		#find . -type f -regextype posix-extended -regex /data/$outdir/query'[._][0-9]+\..xml' -print0 | xargs -0 rm
		rm query*xml
	fi

	##REMOVE GFF# HEADERLINES AND FASTA LINES AND CAT FILES TOGETHER
	if [[ -f query.gff3 ]]
	then
		gff3head=$(head -n 3 /data/$outdir/query.gff3)
		find /data/$outdir  -type f -name "query*gff3" -exec sed -i '1,3d' {} \;
		ls /data/$outdir/*.gff3 > list.tmp
		readarray  -t gffarray < list.tmp

		for g in "${gffarray[@]}"
		do
	        	fanum=($(egrep -n -m 1 '##FASTA' $g))
	        	fanum=($(echo $fanum | sed 's/:\#\#FASTA//'))
	        	fanum=$((fanum-1))
	        	head -n $fanum $g > "$g".tmp
	        	mv "$g".tmp $g
		done
		find /data/$outdir  -type f -name "query*gff3" -print0 | xargs -0 cat -- >> /data/$outdir/tmp.gff3
		echo -e "$gff3head" | cat - /data/$outdir/tmp.gff3 > /data/$outdir/"$inname"'.gff3'
		#find . -type f -regextype posix-extended -regex /data/$outdir/query'[._][0-9]+\..gff3' -print0 | xargs -0 rm
		rm query*gff3
	elif [[ -f query.0.gff3 ]]
	then
		gff3head=$(head -n 3 /data/$outdir/query.0.gff3)
		find /data/$outdir  -type f -name "query*gff3" -exec sed -i '1,3d' {} \;
		ls /data/$outdir/*.gff3 > list.tmp
		readarray  -t gffarray < list.tmp

		for g in "${gffarray[@]}"
		do
	        	fanum=($(egrep -n -m 1 '##FASTA' $g))
	        	fanum=($(echo $fanum | sed 's/:\#\#FASTA//'))
	        	fanum=$((fanum-1))
	        	head -n $fanum $g > "$g".tmp
	        	mv "$g".tmp $g
		done
		find /data/$outdir  -type f -name "query*gff3" -print0 | xargs -0 cat -- >> /data/$outdir/tmp.gff3
		echo -e "$gff3head" | cat - /data/$outdir/tmp.gff3 > /data/$outdir/"$inname"'.gff3'
		#find . -type f -regextype posix-extended -regex /data/$outdir/query'[._][0-9]+\..gff3' -print0 | xargs -0 rm
		rm query*gff3
	fi

	#REMOVE TEMPORARY FILES
	rm /data/$outdir/tmp*
fi

##PARSE XML
outgaf12="protein"

#THESE ARE OPTIONALLY USER-SPECIFIED--DEFAULTS IN LIST ABOVE
if [ -n "${db}" ]; then outgaf1="$db"; else outgaf1="user_input_db"; fi
if [ -n "${biocurator}" ]; then outgaf15="$biocurator"; else outgaf15="user"; fi
if [ -n "${taxon}" ]; then outgaf13="$taxon"; else outgaf13="0000"; fi


echo "Parameters for cyverse_parse_ips_xml.pl: -f /data/${outdir} -d ${outgaf1} -t ${outgaf13} -n ${outgaf15} -y ${outgaf12}"
parse_interproscan_xml.pl -f /data/$outdir -d $outgaf1 -t $outgaf13 -n $outgaf15 -y $outgaf12

#GENERATE QUAL INFO
awk 'BEGIN {FS = "\t"}{OFS = "!"}{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17}' $inname'_gaf.txt' > addqual.tmp
cat addqual.tmp | while IFS="!" read -r db id symbol qual goacc pmid evid empty aspect name sym prot tax date assdb empty2 empty3
touch addqual2.tmp
do
        if [[ $aspect == P ]];
                then
                col4="involved_in"
                echo -e "$db\t$id\t$symbol\t$col4\t$goacc\t$pmid\t$evid\t$empty\t$aspect\t$name\t$sym\t$prot\t$tax\t$date\t$assdb\t$empty2\t$empty3" >> addqual2.tmp
        elif [[ $aspect == F ]];
                then
                col4="enables"
                echo -e "$db\t$id\t$symbol\t$col4\t$goacc\t$pmid\t$evid\t$empty\t$aspect\t$name\t$sym\t$prot\t$tax\t$date\t$assdb\t$empty2\t$empty3" >> addqual2.tmp
        elif [[ $aspect == C ]] && grep -q $goacc '/usr/GO0032991_and_children.json';
                then
                col4="part_of"
                echo -e "$db\t$id\t$symbol\t$col4\t$goacc\t$pmid\t$evid\t$empty\t$aspect\t$name\t$sym\t$prot\t$tax\t$date\t$assdb\t$empty2\t$empty3" >> addqual2.tmp
        elif [[ $aspect == C ]] && grep -v -q $goacc '/usr/GO0032991_and_children.json';
                then
                col4="located_in"
                echo -e "$db\t$id\t$symbol\t$col4\t$goacc\t$pmid\t$evid\t$empty\t$aspect\t$name\t$sym\t$prot\t$tax\t$date\t$assdb\t$empty2\t$empty3" >> addqual2.tmp
        else
		break
	fi
done

#MAKE OUTPUT GAF FILE AND ADD HEADER LINES
currentdate=$(date)
echo -e "!gaf-version: 2.2
!date-generated:$(date +'%Y-%m-%d')
!generated-by: AgBase

Database\tDB_Object_ID\tDB_Object_Symbol\tQualifier\tGO_ID\tDB_Reference\tEvidence_Code\tWith_From\tAspect\tDB_Object_Name\tDB_Object_Synonyms\tDB_Object_Type\tTaxon\tDate\tAssigned_By\tAnnotation_Extension\tGene_Product_Form_Id
$(cat addqual2.tmp)" > $inname'_gaf.txt'


##REMOVE TEMP FILES
rm -r /data/split
rm /data/inputnostar.fasta
rm -r temp
rm -r *.tmp
rm output.fasta

