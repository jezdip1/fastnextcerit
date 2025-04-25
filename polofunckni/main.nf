nextflow.enable.dsl=2

//
// definice parametrů (všechny ostatní nastavíš v nextflow.config)
//
params.license   = '/mnt/data/license.txt'
params.input_dir = '/mnt/data/input'
params.out_dir   = '/mnt/data/subjects'

workflow {

  Channel
    .fromPath("${params.input_dir}/*.nii")
    .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
    .map { file -> tuple( file, file.baseName ) }
    .set { scans }

  fastsurfer_seg(scans)
}

process fastsurfer_seg {
  /*
   * Cpu-only verze, používá naši upravenou image se zabudovaným /bin/bash
   */
  executor  'k8s'
  container 'jezdip1/fastsurfer-cerit:latest'
  cpus      1
  memory    '12 GB'

  tag "$id"

  input:
    tuple path(t1), val(id)

  /*
   * t1_file je absolutní cesta ke vstupní NIfTI
   * OUTDIR je adresář, kam FastSurfer vypíše výsledky pro všechny subjekty
   */
  script:
  """
    T1_FILE=\$( realpath ${t1} )
    OUTDIR=${params.out_dir}

    echo "▶ Subject: $id"
    echo "  T1 file: \$T1_FILE"
    echo "  Output dir: \$OUTDIR"

    mkdir -p "\$OUTDIR"

    /fastsurfer/run_fastsurfer.sh \\
      --fs_license ${params.license} \\
      --t1 "\$T1_FILE" \\
      --sid "$id" \\
      --sd "\$OUTDIR" \\
      --seg_only
  """
}
