################## MultiStage build ######################

################## Core ######################

FROM busybox AS buildcore

ARG IPR=5
ENV IPR $IPR
ARG IPRSCAN=5.45-80.0
ENV IPRSCAN $IPRSCAN


# Latest version is 2.10.1 (https://www.ncbi.nlm.nih.gov/books/NBK131777/) but sticking to old but working version
RUN mkdir -p /opt/interproscan/bin/blast/ncbi-blast-2.9.0+
RUN mkdir -p /opt/interproscan/bin/interproscan


RUN wget -O /opt/interproscan-core-$IPRSCAN.tar.gz ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/$IPR/$IPRSCAN/alt/interproscan-core-$IPRSCAN.tar.gz
RUN wget -O /opt/interproscan-core-$IPRSCAN.tar.gz.md5 ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/$IPR/$IPRSCAN/alt/interproscan-core-$IPRSCAN.tar.gz.md5

WORKDIR /opt

RUN md5sum -c interproscan-core-$IPRSCAN.tar.gz.md5

RUN  tar -pxvzf interproscan-core-$IPRSCAN.tar.gz \
    -C /opt/interproscan --strip-components=1 \
    && rm -f interproscan-core-$IPRSCAN.tar.gz interproscan-core-$IPRSCAN.tar.gz.md5


# Workaround bin/blast/ncbi-blast-2.9.0+/rpsblast: error while loading shared
# libraries: libgnutls.so.28: cannot open shared object file: No such file or 
# directory
RUN wget -O /opt/ncbi-blast-2.9.0+-x64-linux.tar.gz ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.9.0/ncbi-blast-2.9.0+-x64-linux.tar.gz
RUN tar xvf ncbi-blast-2.9.0+-x64-linux.tar.gz

# copy the new version to the binary folder
RUN cp /opt/ncbi-blast-2.9.0+/bin/rpsblast /opt/interproscan/bin/blast/ncbi-blast-2.9.0+/rpsblast
#RUN cp /opt/interproscan/interproscan.sh /opt/interproscan/interproscan-5.jar /opt/interproscan/bin/interproscan

################## BASE IMAGE ######################

FROM ubuntu:22.04

LABEL  base_image="ubuntu:22.04" \
       software="interproscan" \
       software.version="5.45-80.0" \
       version="1" \
       about.summary="Scan sequences against the InterPro protein signature databases." \
       about.home="https://www.ebi.ac.uk/interpro/interproscan.html" \
       about.license="Apache-2.0" \
       about.license_file="https://github.com/ebi-pf-team/interproscan/blob/dev/LICENSE" \
       about.documentation="https://github.com/ebi-pf-team/interproscan/wiki" \
       about.tags="biology::nucleic, biology::protein, field::biology, field::biology:bioinformatics, interface::commandline, role::program,:biological-sequence" \
       extra.identifier.biotools="interproscan_5" \
       extra.binaries="interproscan.sh"

COPY --from=buildcore /opt/interproscan /opt/interproscan

RUN mkdir -p /opt/interproscan/data
RUN mkdir -p /data

RUN apt-get update && \
    apt-get upgrade -y

# needed for add-apt-repository
RUN apt-get install -y software-properties-common

RUN apt-get update

RUN apt-get install -y  \
        parallel        \
	openjdk-19-jre  \
        build-essential \
        pkg-config      \
        python3         \
        bzip2           \
	libdw1          \
        nano            \
	wget		\
       locales     \
        ca-certificates && \
    apt-get clean && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/*

RUN java -version

# fix error java.security.InvalidAlgorithmParameterException: the trustAnchors parameter must be non-empty

# 1. Save an empty JKS file with the default 'changeit' password for Java cacerts.
#    Use 'printf' instead of 'echo' for Dockerfile RUN compatibility.
RUN /usr/bin/printf '\xfe\xed\xfe\xed\x00\x00\x00\x02\x00\x00\x00\x00\xe2\x68\x6e\x45\xfb\x43\xdf\xa4\xd9\x92\xdd\x41\xce\xb6\xb2\x1c\x63\x30\xd7\x92' > /etc/ssl/certs/java/cacerts

#RUN locale-gen en_US.UTF-8
# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

# 2. Re-add all the CA certs into the previously empty file.
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

WORKDIR /opt/interproscan

ENV PATH=$PATH:/opt/interproscan/bin

ADD splitfasta.pl /usr/bin
ADD iprs_wrapper.sh /usr/bin
ADD cyverse_parse_ips_xml.pl /usr/bin
ADD protein-containing_complex_and_children.txt /opt/interproscan/

ENTRYPOINT ["/bin/bash", "iprs_wrapper.sh"]
##################### INSTALLATION END #####################
