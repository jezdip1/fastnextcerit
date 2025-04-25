nextflow.enable.dsl=2

/*
 * 1) Načteme všechny .nii soubory z adresáře
 * 2) Pro každý předáme tuple([path, id])
 */
workflow {
  Channel
    .fromPath("${params.input_dir}/*.nii")
    .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
    .map { f -> tuple(f, f.baseName.replaceFirst(/\.nii$/, '')) }
    .set { scans }

  fastsurfer_seg(scans)
}


process fastsurfer_seg {
  tag   "$id"
  label 'gpu'       // aby se pro GPU úlohy použila správná resource-spec

  // Zapíšeme výstup z workDir do /mnt/data/subjects/<id>
  publishDir "${params.out_dir}/${id}", mode: 'copy', overwrite: true

  input:
    tuple path(t1), val(id)

  output:
    // vrátíme adresář s výsledky zpět do workflow (pro publishDir není nutné přidávat další channel)
    path("${id}_output")

  script:
  """
    echo "▶ Subject: $id"
    echo "  T1 file: $t1"
    echo "  Output dir (inside work): ${id}_output"

    /fastsurfer/run_fastsurfer.sh \\
      --fs_license ${params.license} \\
      --t1 "$t1" \\
      --sid "$id" \\
      --sd ${id}_output \\
      --seg_only
  """
}
