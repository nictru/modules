process RAPIDSSINGLECELL_SCRUBLET {
    tag "${meta.id}"
    label 'process_medium'
    label 'process_gpu'

    container "ghcr.io/scverse/rapids_singlecell:v0.12.7"

    input:
    tuple val(meta), path(h5ad)
    val batch_col

    output:
    tuple val(meta), path("*.h5ad"), emit: h5ad
    tuple val(meta), path("*.pkl") , emit: predictions
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("Rapidssinglecell/scrublet does not support conda. Please use the scanpy/scrublet module or Docker / Singularity / Podman instead.")
    }
    if ("${h5ad}" == "${prefix}.h5ad") {
        error("Input and output names are the same, use \"task.ext.prefix\" to disambiguate!")
    }
    template('scrublet.py')

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("Rapidssinglecell/scrublet does not support conda. Please use the scanpy/scrublet module or Docker / Singularity / Podman instead.")
    }
    if ("${h5ad}" == "${prefix}.h5ad") {
        error("Input and output names are the same, use \"task.ext.prefix\" to disambiguate!")
    }
    """
    export MPLCONFIGDIR=./tmp/mpl
    export NUMBA_CACHE_DIR=./tmp/numba

    touch ${prefix}.h5ad
    touch ${prefix}.pkl

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 -c 'import platform; print(platform.python_version())')
        scanpy: \$(python3 -c 'import scanpy; print(scanpy.__version__)')
    END_VERSIONS
    """
}
