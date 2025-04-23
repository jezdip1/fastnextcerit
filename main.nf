nextflow.enable.dsl=2

workflow {
  Channel
    .fromPath("${params.input_dir}/*.nii")
    .map { file ->
      def id = file.getBaseName().replaceFirst(/\.nii$/, '')
      tuple(file, id)
    }
    .set { t1_scans }

  fastsurfer_seg(t1_scans)
}

process fastsurfer_seg {
  tag "$id"
  label 'gpujob'

  input:
    tuple path(t1), val(id)

  output:
    path("${id}_output")

  script:
  """
  run_fastsurfer.sh \\
    --fs_license ${params.license} \\
    --t1 $t1 \\
    --sid $id \\
    --sd ${id}_output \\
    --seg_only \\
    --parallel
  """
}
