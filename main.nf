nextflow.enable.dsl=2

params {
  input_dir = '/mnt/data/input'
  license   = '/mnt/data/license.txt'
  out_dir   = '/mnt/data/subjects'
}

workflow {
  Channel
    .fromPath("${params.input_dir}/*.nii")
    .ifEmpty { error "No NIfTI files found in ${params.input_dir}" }
    .map { file ->
      // id = baseName bez přípony
      def id = file.baseName
      println "Found file: $file → id=$id"
      tuple( file, id )
    }
    .set { t1_scans }

  fastsurfer_seg(t1_scans)
}

process fastsurfer_seg {
  tag "$id"
  label 'gpujob'
  container 'jezdip1/fastsurfer-cerit:latest'

  input:
    tuple path(t1), val(id)

  output:
    // uložím celý adresář subjects/<id>
    path "${params.out_dir}/${id}", emit: subject

  script:
    // absolutní cesta k T1
    def T1 = t1.toAbsolutePath()
    // absolutní cesta k výstupnímu adresáři pro tento subjekt
    def SD = "${params.out_dir}/${id}"

    """
    echo "Processing subject $id"
    echo "  T1 = \$T1"
    echo "  SD = \$SD"

    mkdir -p \$SD

    /fastsurfer/run_fastsurfer.sh \\
      --fs_license ${params.license} \\
      --t1 "\$T1" \\
      --sid "$id" \\
      --sd "\$SD" \\
      --seg_only \\
      --parallel
    """
}
