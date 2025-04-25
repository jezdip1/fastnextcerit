#!/usr/bin/env nextflow
nextflow.enable.dsl=2

workflow {

    /*
     * 1) Najdi všechny .nii soubory
     * 2) Vytvoř channel s tuple(id, path)
     */
    Channel
      .fromPath("${params.input_dir}/*.nii")
      .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
      .map { f ->
         def id = f.baseName.replaceFirst(/\.nii$/, '')
         tuple(id, f)
      }
      .set { t1_scans }

    /*
     * Spusť proces fastsurfer_seg nad každým tuple(id, path)
     */
    fastsurfer_seg(t1_scans)
}


process fastsurfer_seg {

    tag   "$id"
    label 'gpu'                // aby procesy označené 'gpu' dostaly i GPU

    /*
     * Po ukončení procesu se vygenerovaný adresář
     *   ${id}   (obsahující výsledky)
     * zkopíruje do /mnt/data/subjects/${id}
     */
    publishDir "${params.out_dir}/${id}", mode: 'copy', overwrite: true

    input:
      tuple val(id), path(t1)

    output:
      // Aby proces Nextflowu věděl, že máme výstup:
      path(id)

    script:
    """
    echo "▶ Subject: ${id}"
    echo "  T1: ${t1}"
    echo "  LICENSE: ${params.license}"

    /fastsurfer/run_fastsurfer.sh \\
      --fs_license ${params.license} \\
      --t1 ${t1} \\
      --sid ${id} \\
      --sd ${id} \\
      --seg_only
    """
}
