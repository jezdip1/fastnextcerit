// main.nf
nextflow.enable.dsl=2

workflow {
  Channel
    .fromPath( "${params.input_dir}/*.nii" )
    .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
    .map { file ->
      tuple(file, file.baseName)
    }
    .set { t1_scans }

  fastsurfer_seg(t1_scans)
}

process fastsurfer_seg {
  tag   "$id"
  label 'gpujob'

  input:
    tuple path(t1), val(id)

  output:
    path "${id}_output"

  script:
  """
  T1=\$( realpath "$t1" )
  SD=\$(pwd)/${id}_output
  mkdir -p "\$SD"

  /fastsurfer/run_fastsurfer.sh \\
    --fs_license ${params.license} \\
    --t1 "\$T1" \\
    --sid "$id" \\
    --sd "\$SD" \\
    --seg_only \\
    --parallel
  """
}
