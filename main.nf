nextflow.enable.dsl = 2

workflow {

    Channel
        .fromPath("${params.input_dir}/*.nii")
        .ifEmpty { error "V ${params.input_dir} nejsou žádné *.nii" }
        .map { file ->
            def id = file.baseName.replaceFirst(/\.nii$/, '')
            println "Found file: $file → id=$id"
            tuple(file, id)
        }
        .set { t1_scans }

    fastsurfer_seg(t1_scans)
}

process fastsurfer_seg {

    label 'gpujob'               // → spadne do GPU sekce z configu

    tag "$id"

    input:
        tuple path(t1), val(id)

    /*
     * FastSurfer zapíše subject directory **uvnitř sandboxu**
     * (= relativní cesta). Po skončení úlohy ho publishDir přesune
     * do params.out_dir na stejném PVC.
     */
    output:
        path("${id}_output")

    publishDir "${params.out_dir}", mode: 'copy', overwrite: true

    script:
    """
    echo "Processing subject $id  (T1 = $t1)"
    /fastsurfer/run_fastsurfer.sh \\
        --fs_license ${params.license} \\
        --t1 \$PWD/$t1 \\
        --sid $id \\
        --sd ${id}_output \\
        --seg_only
    """
}
