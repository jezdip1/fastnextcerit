nextflow.enable.dsl = 2

workflow {
    Channel
        .fromPath("${params.input_dir}/*.nii")
        .ifEmpty  { error "No NIfTI files found in ${params.input_dir}" }
        .map      { file -> tuple(file, file.baseName.replaceFirst(/\.nii$/, '')) }
        .set      { scans }

    fastsurfer_seg(scans)
}

process fastsurfer_seg {

    tag       "$id"
    publishDir "${workDir}/../output", mode: 'copy'

    input:
      tuple path(t1), val(id)

    output:
      path("${id}_output")

    shell:
      """
      echo "Processing subject \$id"
      /fastsurfer/run_fastsurfer.sh \
        --fs_license ${params.license} \
        --t1 \$t1 \
        --sid \$id \
        --sd ${id}_output \
        --seg_only \
        --parallel
      """
}
