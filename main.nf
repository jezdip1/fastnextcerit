nextflow.enable.dsl=2

// -----------------------------
// workflow parameters
// -----------------------------
params.input_dir   = '/mnt/data/input'
params.license     = '/mnt/data/license.txt'
params.output_dir  = '/mnt/data/output'

// -----------------------------
// workflow definition
// -----------------------------
workflow {

    // načti všechny .nii soubory jako absolutní cesty
    Channel
        .fromPath("$params.input_dir/*.nii")
        .ifEmpty { error "No NIfTI files found in $params.input_dir" }
        .map { file ->
            def id = file.baseName.replaceFirst(/\.nii$/, '')
            println "Found file: $file → id=$id"
            tuple( file, id )
        }
        .set { t1_scans }

    // spusť FastSurfer pro každý pár (file, id)
    fastsurfer_seg(t1_scans)
}

// -----------------------------
// FastSurfer process
// -----------------------------
process fastsurfer_seg {

    tag   "$id"
    // použij svůj wrapnutý image
    container 'jezdip1/fastsurfer-cerit:latest'

    // výchozí CPU/memory
    cpus   2
    memory '12 GB'

    // specifické zdroje pro GPU
    ext.k8s = [
      limits:   [ 'nvidia.com/gpu': '1', cpu: '2', memory: '12Gi' ],
      requests: [ 'nvidia.com/gpu': '1', cpu: '2', memory: '10Gi' ]
    ]

    // vstupy
    input:
      tuple path(t1), val(id)

    // výstup je celý adresář <id>_output
    output:
      path "${id}_output"

    // použij shell (bash) s absolutní cestou k T1
    shell:
    """
    echo "Processing subject $id with file $t1"
    /fastsurfer/run_fastsurfer.sh \\
      --fs_license $params.license \\
      --t1 $t1 \\
      --sid $id \\
      --sd ${id}_output \\
      --seg_only
    """
}
