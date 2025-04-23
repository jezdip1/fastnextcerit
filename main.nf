nextflow.enable.dsl=2

// workflow parameters
params.input_dir  = '/mnt/data/input'
params.license    = '/mnt/data/license.txt'
params.output_dir = '/mnt/data/output'

workflow {
  Channel
    .fromPath("$params.input_dir/*.nii")
    .ifEmpty { error "No NIfTI files found in $params.input_dir" }
    .map { file ->
      def id = file.baseName.replaceFirst(/\.nii$/, '')
      println "Found file: $file → id=$id"
      tuple(file, id)
    }
    .set { t1_scans }

  fastsurfer_seg(t1_scans)
}

process fastsurfer_seg {
  tag   "$id"
  // náš wrapnutý image s fungujícím bash
  container 'jezdip1/fastsurfer-cerit:latest'

  // výchozí zdroje
  cpus   2
  memory '12 GB'

  // explicitně požadujeme 1 GPU
  ext.k8s = [
    requests: [ 'nvidia.com/gpu':'1', cpu:'2', memory:'10Gi' ],
    limits:   [ 'nvidia.com/gpu':'1', cpu:'2', memory:'12Gi' ]
  ]

  input:
    tuple path(t1), val(id)

  output:
    path "${id}_output"

  shell:
  """
  echo "Processing subject $id from \$FASTDIR"
  FASTDIR=${params.input_dir}    # absolutní mount point
  T1=\$FASTDIR/${id}.nii
  echo " Using absolute T1 path: \$T1"

  /fastsurfer/run_fastsurfer.sh \\
    --fs_license ${params.license} \\
    --t1 \$T1 \\
    --sid $id \\
    --sd ${id}_output \\
    --seg_only
  """
}
