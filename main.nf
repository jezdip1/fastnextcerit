// main.nf
nextflow.enable.dsl=2

workflow {
  Channel
    .fromPath( "${params.input_dir}/*.nii" )
    .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
    .map { file ->
      def id = file.baseName
      println "Found file: $file  →  id=$id"
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
    path "${id}_output"

  script:
  """
  t1_file="\$(pwd)/$t1"
  echo "Processing subject $id with file \$t1_file"
  /fastsurfer/run_fastsurfer.sh \\
    --fs_license ${params.license} \\
    --t1 "\$t1_file" \\
    --sid $id \\
    --sd ${id}_output \\
    --seg_only \\
    --parallel
  """
}
