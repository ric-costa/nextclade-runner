include { NEXTCLADE_DATASETGET        } from '../../modules/nf-core/modules/nextclade/datasetget/main'

workflow PREPARE_NEXTCLADE_DATASETGET {
    main: 

    ch_versions = Channel.empty()

    ch_nextclade_db = Channel.empty()
    if (!params.skip_nextclade) {
        if (params.nextclade_dataset) {
            if (params.nextclade_dataset.endsWith('.tar.gz')) {
                UNTAR (
                    [ [:], params.nextclade_dataset ]
                )
                ch_nextclade_db = UNTAR.out.untar.map { it[1] }
                ch_versions     = ch_versions.mix(UNTAR.out.versions)
            } else {
                ch_nextclade_db = file(params.nextclade_dataset)
            }
        } else if (params.nextclade_dataset_name) {
            NEXTCLADE_DATASETGET (
                params.nextclade_dataset_name,
                params.nextclade_dataset_reference,
                params.nextclade_dataset_tag
            )
            ch_nextclade_db = NEXTCLADE_DATASETGET.out.dataset
            ch_versions     = ch_versions.mix(NEXTCLADE_DATASETGET.out.versions)
        }
    }

    emit:

    nextclade_db         = ch_nextclade_db         // path: nextclade_db
}    