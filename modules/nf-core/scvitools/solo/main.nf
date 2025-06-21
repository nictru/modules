process SCVITOOLS_SOLO {
    tag "$meta.id"
    label 'process_medium'
    label 'process_gpu'

    conda "${moduleDir}/environment.yml"
    // GPU images can be found here: https://github.com/scverse/scvi-tools/pkgs/container/scvi-tools
    container "${ task.ext.use_gpu ? 'ghcr.io/scverse/scvi-tools:py3.12-cu12-1.3.1.post1-' :
        workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/4b/4bdeb294d71c935691525ddc161a455b79cf5501189800da9c973f051f7442d9/data':
        'community.wave.seqera.io/library/scvi-tools:1.3.1.post1--7cdffa676822148e' }"

    input:
    tuple val(meta), path(h5ad)

    output:
    tuple val(meta), path("*.h5ad"), emit: h5ad
    tuple val(meta), path("*.pkl") , emit: predictions
    path "versions.yml"            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    batch_key = task.ext.batch_key ?: ""
    max_epochs = task.ext.max_epochs ?: ""
    template 'solo.py'

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    export MPLCONFIGDIR=./tmp

    touch ${prefix}.h5ad
    touch ${prefix}.pkl

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 -c 'import platform; print(platform.python_version())')
        anndata: \$(python3 -c 'import anndata; print(anndata.__version__)')
        scvi: \$(python3 -c 'import scvi; print(scvi.__version__)')
    END_VERSIONS
    """
}
