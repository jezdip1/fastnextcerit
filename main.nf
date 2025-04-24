nextflow.enable.dsl=2

workflow {
    Channel
        .fromPath( params.input_dir + '/*.nii' )
        .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
        .map { f -> tuple(f, f.baseName) }
        .set { scans }

    fastsurfer_seg(scans)
}

process fastsurfer_seg {
    container 'jezdip1/fastsurfer-cerit:latest'
    executor  'k8s'
    cpus      1
    memory    '12 GB'

    input:
    tuple path(t1), val(id)

    output:
    path "${params.output_dir}/${id}"

    script:
    """
    T1=\$(realpath "${t1}")
    SD=${params.output_dir}

    /fastsurfer/run_fastsurfer.sh \\
      --fs_license ${params.license} \\
      --t1 "\$T1" \\
      --sid "${id}" \\
      --sd "\$SD" \\
      --seg_only
    """
}
