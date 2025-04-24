nextflow.enable.dsl = 2

workflow {
    Channel
        .fromPath( "${params.input_dir}/*.nii" )
        .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
        .map   { file -> [ file, file.getBaseName().replaceFirst(/\.nii$/, '') ] }
        .set   { t1_scans }

    fastsurfer_seg( t1_scans )
}

/* --------------------------- PROCESS --------------------------- */

process fastsurfer_seg {

    tag "$id"
    container 'jezdip1/fastsurfer-cerit:latest'

    /* === k8s & HW limity ====================================== */
    ext.k8s = [
      limits:   [ cpu: '2',   memory: '12Gi' ],
      requests: [ cpu: '2',   memory: '12Gi' ],
    ]

    input:
    tuple path(t1), val(id)

    output:
    path("${id}_output")

    /*
     *  Vše necháme až do skriptu; proměnná $t1 už v té chvíli existuje,
     *  takže si z ní můžeme vzít absolutní cestu přes `realpath`.
     */
    shell:
    """
    T1=\$(realpath "$t1")             # absolutní cesta k T1
    SD=${params.out_dir}              # např. /mnt/data/subjects

    echo "Processing \$T1  →  \$SD"

    /fastsurfer/run_fastsurfer.sh \\
        --fs_license ${params.license} \\
        --t1 "\$T1" \\
        --sid ${id} \\
        --sd "\$SD" \\
        --seg_only
    """
}
