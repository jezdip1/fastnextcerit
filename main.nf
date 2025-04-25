#!/usr/bin/env nextflow
nextflow.enable.dsl=2

workflow {
  Channel
    .fromPath("${params.input_dir}/*.nii")
    .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
    .map { file ->
      def id = file.baseName.replaceFirst(/\.nii$/, '')
      tuple(id, file)
    }
    .set { t1_scans }

  fastsurfer_seg(t1_scans)
}


process fastsurfer_seg {
  tag   "$id"
  label 'gpujob'      // prozatím CPU, ale kdybyste posílali na GPU...

  input:
    tuple val(id), path(t1)

  output:
    path("${id}_output")

  script:
  """
    echo "▶ Processing subject $id"
    echo "   T1 file = $t1"
    echo "   License = ${params.license}"

    /fastsurfer/run_fastsurfer.sh \\
      --fs_license ${params.license} \\
      --t1 $t1 \\
      --sid $id \\
      --sd ${id}_output \\
      --seg_only
  """
}
