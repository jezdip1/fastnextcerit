nextflow.enable.dsl = 2

workflow {

  Channel
      .fromPath("${params.input_dir}/*.nii")
      .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
      .map { file -> tuple(file, file.baseName.replaceFirst(/\.nii$/, '')) }
      .set { scans }

  fastsurfer_seg(scans)
}

process fastsurfer_seg {

  label 'gpu'                   // zapne blok s GPU zdroji

  tag  "$id"

  input:
    tuple path(t1), val(id)

  output:
    path "${params.subjects_dir}/${id}"

  /*
   *  Pozn.:  run_fastsurfer.sh MUSÍ dostat absolutní --sd
   *          a stejně tak absolutní --t1, pak už nezáleží
   *          kde uvnitř skriptu zrovna je.
   */
  shell:
  """
  T1=${params.input_dir}/${id}.nii
  SD=${params.subjects_dir}

  echo "Processing \$T1  →  \$SD"

  /fastsurfer/run_fastsurfer.sh \
       --fs_license ${params.license} \
       --t1 \$T1 \
       --sid $id \
       --sd \$SD \
       --seg_only
  """
}
