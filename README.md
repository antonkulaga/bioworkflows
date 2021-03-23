# Bioworkflows

Systems biology of Aging Group shared workflows

This repository is dedicated to shared bioinformatic WDL workflows that are imported directly from github from other projects
For specific topics it is recommended to look at:
* RNA-Seq https://github.com/antonkulaga/rna-seq
* Variant-Calling and annotations https://github.com/antonkulaga/dna-seq
* Epigenetics (Bs-Seq, Chip-Seq) https://github.com/antonkulaga/epigenetics

For external pipelines it is recommended to look at:
* https://github.com/biowdl
* https://github.com/broadinstitute/warp

Current workflows
=================

At the moment there are following workflows in the repository:
* common - common tasks (i.e. file copying):
  * files.wdl - contains copy task
* download - download from NCBI as it is common public datasets source, consists of:
  * download_run.wdl - downloads single sequencing run from NCBI
  * download_runs.wdl - downloads multiple runs, calling download_run.wdl under the hood
  * download_samples.wdl - downloads GSM
* quality - quality control:
  * clean_reads.wdl - does adapter and quality trimming with fastp
* align - alignment (so far minimap2 only but will add bwa-mem2 soon):
  * align_reads.wdl - aligns fastq-files
  * align_runs - NCBI-oriented, reuses download_runs.wdl to download NCBI runs and then applies align_reads.wdl for alignment
  * align_samples - NCBI-oriented, reuses download_samples.wdl to download GSM-s and then applies align_reads.wdl for alignment