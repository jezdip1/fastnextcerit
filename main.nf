nextflow.enable.dsl=2

workflow {
  Channel
    .fromPath("${params.input_dir}/*.nii")
    .ifEmpty { error "❌ No .nii files found in: ${params.input_dir}" }
    .map { file ->
      def id = file.getBaseName().replaceFirst(/\.nii$/, '')
      println "✅ Found file: $file"
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
  echo 'Running fastsurfer for $id'
  run_fastsurfer.sh \\
    --fs_license ${params.license} \\
    --t1 $t1 \\
    --sid $id \\
    --sd ${id}_output \\
    --seg_only \\
    --parallel
  """
}

