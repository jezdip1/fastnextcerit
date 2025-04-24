nextflow.enable.dsl = 2

workflow {

    Channel
      .fromPath( "${params.input_dir}/*.nii" )
      .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
      .map    { file -> tuple( file, file.baseName.replaceFirst(/\.nii$/, '') ) }
      .set    { t1_scans }

    fastsurfer_seg( t1_scans )
}

/* ---------------- PROCESS --------------------------- */
process fastsurfer_seg {

    tag       "$id"
    container 'jezdip1/fastsurfer-cerit:latest'

    input:
    tuple path(t1), val(id)

    output:
    path("${id}_output")

    /*
     *  --- Skript (běží uvnitř kontejneru) --------------------
     *  1) absolutní cesta k T1                               
     *  2) adresář subjektů =  /mnt/data/subjects             
     */
    shell:
    """
    T1=\$(realpath "$t1")
    SD=${params.out_dir}

    echo "Processing \$T1 → \$SD"

    /fastsurfer/run_fastsurfer.sh \\
        --fs_license ${params.license} \\
        --t1 "\$T1" \\
        --sid ${id} \\
        --sd "\$SD" \\
        --seg_only
    """
}
