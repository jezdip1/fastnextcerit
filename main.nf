nextflow.enable.dsl = 2


workflow {

    Channel
        // vezmeme všechna *.nii v zadané složce
        .fromPath("${params.input_dir}/*.nii")
        .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }

        // vytvoříme tuple (soubor, subjekt-ID)
        .map { f ->
            def id = f.getBaseName().replaceFirst(/\.nii$/, '')
            println "Found file: ${f}  →  id=${id}"
            tuple(f, id)
        }
        .set { t1_scans }

    fastsurfer_seg(t1_scans)      // spustí proces pro každý tuple
}


process fastsurfer_seg {

    tag       "$id"
    container 'jezdip1/fastsurfer-cerit:latest'   // náš „opravný“ image

    cpus      2
    memory    '12 GB'

    input:
        tuple path(t1), val(id)

    output:
        path "${id}_output"

    shell:
    """
    T1=${params.input_dir}/${id}.nii
    echo "Processing subject $id  →  \$T1"

    /fastsurfer/run_fastsurfer.sh \\
        --fs_license ${params.license} \\
        --t1 \$T1 \\
        --sid $id \\
        --sd ${id}_output \\
        --seg_only
    """
}
