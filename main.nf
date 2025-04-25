#!/usr/bin/env nextflow
nextflow.enable.dsl=2

workflow {
  // Seber všechny T1.nii
  Channel
    .fromPath("${params.input_dir}/*.nii")
    .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
    .map { f ->
      def id = f.baseName.replaceFirst(/\.nii$/, '')
      tuple(id, f)
    }
    .set { t1_scans }

  // Spusť segmentaci
  fastsurfer_seg(t1_scans)
}


process fastsurfer_seg {
  tag   "$id"
  label 'gpu'              // použije GPU nastavení z configu

  input:
    tuple val(id), path(t1)

  output:
    // Výsledky zkopíruj do /mnt/data/subjects/$id
    path(id), emit: result

  publishDir "${params.out_dir}/${id}", mode: 'copy', overwrite: true

  script:
  """
  echo "▶ Subject: ${id}"
  echo "  T1 file: ${t1}"
  echo "  License: ${params.license}"

  /fastsurfer/run_fastsurfer.sh \\
    --fs_license ${params.license} \\
    --t1 ${t1} \\
    --sid ${id} \\
    --sd ${id} \\
    --seg_only
  """
}
