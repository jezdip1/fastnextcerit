nextflow.enable.dsl = 2

/*
 *  Konstanty k cestám – nic nepřepisovat v procesu
 */
workflow {
    Channel
        .fromPath("${params.input_dir}/*.nii")
        .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
        .map { file ->
            def id = file.baseName.replaceFirst(/\.nii$/, '')
            tuple( file, id )
        }
        .set { t1_scans }

    fastsurfer_seg(t1_scans)
}

process fastsurfer_seg {

    tag "$id"
    publishDir "${params.out_dir}", mode: 'copy'
    container 'jezdip1/fastsurfer-cerit:latest'
    errorStrategy 'retry'; maxRetries 1

    input:
        tuple path(t1), val(id)

    output:
        path("${id}"), emit: subjects      // složka /subjects/<id>

    script:
    """
    T1=${t1.toAbsolutePath()}
    SD=${params.out_dir}                  # např. /mnt/data/subjects

    echo "Processing \$T1  →  \$SD"

    /fastsurfer/run_fastsurfer.sh \\
        --fs_license ${params.license} \\
        --t1 \$T1 \\
        --sid ${id} \\
        --sd \$SD \\
        --seg_only
    """
}
