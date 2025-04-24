nextflow.enable.dsl = 2

/*
 * ░░ WORKFLOW ░░
 */
workflow {
    Channel
        .fromPath("${params.input_dir}/*.nii")
        .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
        .map { file -> tuple(file, file.baseName.replaceFirst(/\.nii$/, '')) }
        .set { t1_scans }

    fastsurfer_seg(t1_scans)
}

/*
 * ░░ PROCESS ░░
 */
process fastsurfer_seg {

    label 'gpujob'
    tag   "$id"

    input:
        tuple path(t1), val(id)

    /*
     * Po skončení vytvoříme prázdný soubor `${id}.done`, aby Nextflow
     * nemusel kopírovat celý výstupní adresář.
     */
    output:
        path("${id}.done")

    /*
     * Spouštěcí skript
     */
    shell: '''
        T1=${t1.toAbsolutePath()}
        SD=${params.out_dir}

        echo "Processing $T1  →  $SD"

        /fastsurfer/run_fastsurfer.sh \
            --fs_license ${params.license} \
            --t1 "$T1" \
            --sid ${id} \
            --sd "$SD" \
            --seg_only

        touch ${id}.done
    '''
}
