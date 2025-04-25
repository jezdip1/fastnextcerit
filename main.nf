nextflow.enable.dsl=2

//
// Define an output folder on the PVC
//
params.out_dir = '/mnt/data/subjects'

workflow {

  Channel
    .fromPath( "${params.input_dir}/*.nii" )
    .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
    .map { f -> tuple( f, f.baseName.replaceFirst(/\.nii$/, '') ) }
    .set { t1_scans }

  fastsurfer_seg( t1_scans )
}


//
// This process runs one FastSurfer per subject
//
process fastsurfer_seg {
  tag   "$id"
  label 'gpujob'

  input:
    tuple path(t1), val(id)

  output:
    // we write everything under /mnt/data/subjects/$id, so Nextflow
    // will capture that directory tree
    path "${params.out_dir}/${id}"

  script:
  """
  set -euo pipefail

  T1=\$( realpath "$t1" )
  SD="${params.out_dir}/${id}"
  mkdir -p "\$SD"

  echo "▶ Processing subject $id"
  echo "  └─ T1   : \$T1"
  echo "  └─ out  : \$SD"

  exec /fastsurfer/run_fastsurfer.sh \
    --fs_license ${params.license} \
    --t1 "\$T1" \
    --sid "$id" \
    --sd "\$SD" \
    --seg_only \
    --parallel
  """
}
