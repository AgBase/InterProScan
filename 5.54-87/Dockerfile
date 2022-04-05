################## MultiStage build ######################

################## Core ######################

FROM busybox AS buildcore

MAINTAINER Jawon Song <jawon@tacc.utexas.edu>
MAINTAINER Amanda Cooksey <amcooksey@arizona.edu>
MAINTAINER Surya Saha <suryasaha@arizona.edu>


ARG IPR=5
ENV IPR $IPR
ARG IPRSCAN=5.54-87.0
ENV IPRSCAN $IPRSCAN


# Latest version is 2.10.1 (https://www.ncbi.nlm.nih.gov/books/NBK131777/) but sticking to old but working version
RUN mkdir -p /opt/interproscan/bin/blast/ncbi-blast-2.9.0+
RUN mkdir -p /opt/interproscan/bin/interproscan

WORKDIR /opt

RUN wget ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/$IPR/$IPRSCAN/alt/interproscan-core-$IPRSCAN.tar.gz
RUN wget ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan/$IPR/$IPRSCAN/alt/interproscan-core-$IPRSCAN.tar.gz.md5


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

FROM ubuntu:focal-20220113

MAINTAINER Jawon Song <jawon@tacc.utexas.edu>
MAINTAINER Amanda Cooksey <amcooksey@arizona.edu>
MAINTAINER Surya Saha <suryasaha@arizona.edu>
LABEL  base_image="ubuntu:focal-20220113" \
       software="interproscan" \
       software.version="5.54-87.0" \
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

# repo for openjdk-11 as only 8 is available by default
RUN add-apt-repository ppa:openjdk-r/ppa && \
    apt-get update

RUN apt-get install -y  --no-install-recommends --fix-missing \
        parallel        \
        openjdk-11-jre  \
        build-essential \
        pkg-config      \
        bzip2           \
        libdw1          \
        libpcre3-dev    \
        nano            \
	wget		\
	git		\
	cmake		\
	gfortran        \
	gcc             \
	libdrm-dev	\	
        libgfortran5    \
        zlib1g-dev      \
        libpng-dev      \
        libfile-slurp-perl \
	locales \
        ca-certificates && \
    apt-get clean && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/*

#RUN locale-gen en_US.UTF-8
# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

#INSTALL PERL FROM SOURCE AND SET MALLOC TO SYSTEM ALLOC
WORKDIR /shared

RUN wget http://www.cpan.org/src/5.0/perl-5.30.3.tar.gz && \
    tar -xzf perl-5.30.3.tar.gz

WORKDIR /shared/perl-5.30.3
RUN ./Configure -des -Dprefix=/opt/perl-5.30.3/localperl -Uusemymalloc
RUN make
RUN make install

#DOWNLOAD AND COMPILE PFTOOLS 3.11.2 FROM GITHUB. Replace copies in /opt/interproscan/bin.
RUN rm -r /opt/interproscan/bin/prosite/pfscan /opt/interproscan/bin/prosite/pfsearch /opt/interproscan/bin/prosite/pfscanV3 /opt/interproscan/bin/prosite/pfsearchV3 && \
    cd /opt/interproscan/bin && \
    wget https://github.com/sib-swiss/pftools3/archive/refs/tags/v3.2.11.tar.gz && \
    tar -zxf v3.2.11.tar.gz && \
    mkdir pftools3-3.2.11/build && \
    cd /opt/interproscan/bin/pftools3-3.2.11/build && \
    cmake .. -DCMAKE_INSTALL_PREFIX:PATH=/opt/interproscan/bin/prosite -DCMAKE_BUILD_TYPE=Release -DUSE_GRAPHICS=OFF -DUSE_PDF=OFF && \
    make && \
    make install && \
    make test && \
    cd /opt/interproscan/bin/ && \
    rm -rf v3.2.11.tar.gz pftools3-3.2.11 && \
    mv /opt/interproscan/bin/prosite/bin/* /opt/interproscan/bin/prosite/

# INSTALL OLDER VERSION OF  HMMER TO MATCH .HMX FILES
WORKDIR /opt/interproscan/bin

RUN wget http://eddylab.org/software/hmmer/hmmer-3.1b2.tar.gz && \
    tar -xf hmmer-3.1b2.tar.gz && \
    cd hmmer-3.1b2 && \
    ./configure --prefix=/opt/interproscan/bin && \
    make && \
    make check && \
    make install 


# fix error java.security.InvalidAlgorithmParameterException: the trustAnchors parameter must be non-empty

# 1. Save an empty JKS file with the default 'changeit' password for Java cacerts.
#    Use 'printf' instead of 'echo' for Dockerfile RUN compatibility.
RUN /usr/bin/printf '\xfe\xed\xfe\xed\x00\x00\x00\x02\x00\x00\x00\x00\xe2\x68\x6e\x45\xfb\x43\xdf\xa4\xd9\x92\xdd\x41\xce\xb6\xb2\x1c\x63\x30\xd7\x92' > /etc/ssl/certs/java/cacerts

# 2. Re-add all the CA certs into the previously empty file.
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

WORKDIR /opt/interproscan

RUN python3 initial_setup.py

ENV PATH=$PATH:/opt/interproscan/bin
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

ADD interproscan.properties /opt/interproscan
ADD splitfasta.pl /usr/bin
ADD iprs_wrapper.sh /usr/bin
ADD parsexml_nopathinfo.pl /usr/bin

RUN chmod a+rwx /usr/bin/parsexml_nopathinfo.pl

ENTRYPOINT ["/bin/bash", "iprs_wrapper.sh"]
##################### INSTALLATION END #####################
