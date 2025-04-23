nextflow.enable.dsl = 2

workflow {
    Channel
      .fromPath("${params.input_dir}/*.nii")
      .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
      .map { file ->
          def id = file.baseName.replaceFirst(/\.nii$/, '')
          println "Found file: $file  →  id=$id"
          tuple(file, id)
      }
      .set { scans }

    fastsurfer_seg(scans)
}

process fastsurfer_seg {
    tag "$id"

    input:
      tuple path(t1), val(id)

    output:
      path("${id}_output")

    shell:
      """
      echo "Processing subject \$id"
      /fastsurfer/run_fastsurfer.sh \\
        --fs_license ${params.license} \\
        --t1 \$t1 \\
        --sid \$id \\
        --sd ${id}_output \\
        --seg_only \\
        --parallel
      """
}
