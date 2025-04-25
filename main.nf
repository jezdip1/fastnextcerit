nextflow.enable.dsl = 2

workflow {
  Channel
    .fromPath("${params.input_dir}/*.nii")
    .ifEmpty { error "❌ No NIfTI files found in ${params.input_dir}" }
    .map { f -> tuple(f, f.baseName) }
    .set { scans }

  fastsurfer_seg(scans)
}

process fastsurfer_seg {
  label   'gpujob'
  cpus    1
  memory  '12 GB'

  input:
    tuple path(t1), val(id)

  output:
    // Každý subject putuje do vlastní složky
    path "${params.output_dir}/${id}"

  script:
  """
//  # vynutíme absolutní cesty
  T1=\$( realpath "${t1}" )
  SD=${params.output_dir}/${id}

  echo "▶ Subject: ${id}"
  echo "  T1 file: \$T1"
  echo "  Output: \$SD"

//  # Ujistíme se, že složka existuje
  mkdir -p \$SD

//  # Spustíme FastSurfer se správnými cestami
  /fastsurfer/run_fastsurfer.sh \\
    --fs_license ${params.license} \\
    --t1 "\$T1" \\
    --sid "${id}" \\
    --sd "\$SD" \\
    --seg_only
  """
}
