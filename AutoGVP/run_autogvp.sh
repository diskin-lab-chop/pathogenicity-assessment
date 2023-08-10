#!/usr/bin/env bash

set -e

## default files
variant_summary_file="input/ClinVar-selected-submissions.tsv"

if [[ ! -f $variant_summary_file ]] ; then
    echo "ERROR: ClinVar-selected-submissions.tsv file not found. Please run select-clinvar-submissions.R script before running AutoGVP"
fi


while [ $# -gt 0 ]; do
  case "$1" in
    --workflow*|-w*)
      if [[ "$1" != *=* ]]; then shift; fi # Value is next arg if no `=`
      workflow="${1#*=}"
      ;;
    --vcf*|-v*)
      if [[ "$1" != *=* ]]; then shift; fi
      vcf_file="${1#*=}"
      ;;
    --filter_criteria*|-f*)
      if [[ "$1" != *=* ]]; then shift; fi
      filtering_criteria="${1#*=}"
      ;;
    --clinvar*|-c*)
      if [[ "$1" != *=* ]]; then shift; fi
      clinvar_file="${1#*=}"
      ;;
    --intervar*|-i*)
      if [[ "$1" != *=* ]]; then shift; fi
      intervar_file="${1#*=}"
      ;;
    --multianno*|-m*)
      if [[ "$1" != *=* ]]; then shift; fi
      multianno_file="${1#*=}"
      ;;
    --autopvs1*|-a*)
      if [[ "$1" != *=* ]]; then shift; fi
      autopvs1_file="${1#*=}"
      ;;
    --outdir*|-O*)
      if [[ "$1" != *=* ]]; then shift; fi
      out_dir="${1#*=}"
      ;;
    --out*|-o*)
      if [[ "$1" != *=* ]]; then shift; fi
      out_file="${1#*=}"
      ;;
    --help|-h)
        echo "Usage: $0 [-w/--workflow] [-v/--vcf <*.vcf*>] [-f/--filter_criteria=<criteria>] [-c/--clinvar <*.vcf>] [-i/--intervar <*.txt.intervar>] [-a/--autopvs1 <*autopvs1*>] [-m/--multianno <*multianno*>] [-o/--out <output>]"
        echo ""
        echo "Options:"
        echo "  -w/--workflow           workflow"
        echo "  -v/--vcf                VCF file"
        echo "  -f/--filter_criteria    VCF filtering criteria"
        echo "  -c/--clinvar            clinvar file"
        echo "  -i/--intervar           intervar results file"
        echo "  -a/--autopvs1           autopvs1 results file"
        echo "  -m/--multianno          multianno file"
        echo "  -O/--outdir             output directory"
        echo "  -o/--out                output prefix"
        echo "  -h/--help               Display usage information"
            exit 0
      ;;
    *)
      >&2 printf "Error: Invalid argument\n"
      exit 1
      ;;
  esac
  shift
done

autogvp_input=$vcf_file

# Filter VCF file for read depth, alt allele freq, pass filter and other specified criteria

vcf_filtered_file=${out_file}."filtered.vcf"
bash filter_vcf.sh $vcf_file $out_file $out_dir $filtering_criteria
autogvp_input=$out_dir/$vcf_filtered_file


if [[ "$workflow" = "cavatica" ]];then

  # Run AutoGVP from Cavatica workflow
  Rscript 01-annotate_variants_CAVATICA_input.R --vcf $autogvp_input \
  --multianno $multianno_file \
  --intervar $intervar_file \
  --autopvs1 $autopvs1_file \
  --output $out_file \
  --variant_summary $variant_summary_file

  else

  # Run AutoGVP from custom workflow
  Rscript 01-annotate_variants_custom_input.R --vcf $autogvp_input \
  --clinvar $clinvar_file \
  --multianno $multianno_file \
  --intervar $intervar_file \
  --autopvs1 $autopvs1_file \
  --output $out_file \
  --variant_summary $variant_summary_file \

fi


# Parse vcf file so that info field values are in distinct columns
bash parse_vcf.sh $autogvp_input

# Define parsed vcf and autogvp output file variables
vcf_parsed_file=${autogvp_input%.vcf*}."parsed.tsv"
autogvp_output="../results/"${out_file}".cavatica_input.annotations_report.abridged.tsv"

# Filter VCF gene/transcript annotations and merge data with AutoGVP output
Rscript 04-filter_gene_annotations.R --vcf $vcf_parsed_file --autogvp $autogvp_output --output $out_file

rm $out_dir/$vcf_filtered_file $autogvp_input $vcf_parsed_file $out_dir/$autogvp_output