nextflow.enable.dsl = 2

workflow {
    Channel
        .fromPath( "${params.input_dir}/*.nii" )
        .ifEmpty { error "❌ No NIfTI files found in ${params.input_dir}" }
        .map { f -> tuple(f, f.baseName) }
        .set { scans }

    fastsurfer_seg(scans)
}

process fastsurfer_seg {
    label   'gpujob'                // pokud chcete GPU, pak s ext.k8s dále
    cpus    1
    memory  '12 GB'

    input:
      tuple path(t1), val(id)

    output:
      // každý výstup pak skončí ve složce subjects/${id}
      path "${params.output_dir}/${id}"

    script:
    """
    # absolutní cesty, ať FastSurfer najde všechno
    T1=\$( realpath "${t1}" )
    SD=${params.output_dir}

    echo "▶ Processing subject ${id}"
    echo "   T1   => \$T1"
    echo "   SDir => \$SD"

    /fastsurfer/run_fastsurfer.sh \\
      --fs_license ${params.license} \\
      --t1 "\$T1" \\
      --sid "${id}" \\
      --sd "\$SD"     \\
      --seg_only
    """
}
