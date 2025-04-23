nextflow.enable.dsl = 2


workflow {

    Channel
        .fromPath("${params.input_dir}/*.nii")
        .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
        .map { f ->
            def id = f.baseName.replaceFirst(/\.nii$/, '')
            println "Found file $f  → id=$id"
            tuple(f, id)
        }
        .set { t1_scans }

    fastsurfer_seg( t1_scans )
}


/**************************************************
 *                    PROCESS                     *
 **************************************************/
process fastsurfer_seg {

    tag "$id"

    /*  --- container ---  */
    container        = 'deepmi/fastsurfer:latest'
    containerOptions = '--entrypoint ""'      // <-- zruší ENTRYPOINT z Docker imagu

    /*  --- I/O ---  */
    input:
        tuple path(t1), val(id)

    output:
        path("${id}_output")

    /*  --- script ---  */
    shell: '''
        echo "Processing subject $id"
        /fastsurfer/run_fastsurfer.sh \
            --fs_license ${params.license} \
            --t1 $t1 \
            --sid $id \
            --sd ${id}_output \
            --seg_only \
            --parallel
    '''
}
