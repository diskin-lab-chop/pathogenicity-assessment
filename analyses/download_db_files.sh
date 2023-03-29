#!/usr/bin/env bash

set -e
set -o pipefail

wget https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh38/archive_2.0/2023/clinvar_20230218.vcf.gz -P input/
wget https://ftp.ncbi.nlm.nih.gov/pub/clinvar/tab_delimited/submission_summary.txt.gz -P input/
wget https://ftp.ncbi.nlm.nih.gov/pub/clinvar/tab_delimited/variant_summary.txt.gz -P input/

## unzip summary files
gunzip input/submission_summary.txt.gz
gunzip input/variant_summary.txt.gz