#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

def json_schema = "$projectDir/nextflow_schema.json" 
outputPath = "$params.input"
subtypesPath = "$outputPath/subtypes.csv"
referencePath = "az://assets/flu"
runDir = "$outputPath/irma"

//String runDir = System.properties.'user.dir'

params.nextclade_dataset = null   

//=============================================================================
// MODULES
//=============================================================================
include { NEXTCLADE_RUN } from './modules/nf-core/modules/nextclade/run/main'
include { NEXTCLADE_DATASETGET } from './modules/nf-core/modules/nextclade/datasetget/main'

workflow {
/*
   //get Nextclade datasets (H1N1 and H3N2)
   ch_name = Channel.from ('flu_h3n2_ha', 'flu_h1n1pdm_ha')
   ch_reference = Channel.from ('CY163680', 'CY121680')
   ch_tag = Channel.from ('2022-12-07T08:35:53Z', '2022-12-07T08:35:53Z')
   NEXTCLADE_DATASETGET (
                  ch_name,
                  ch_reference,
                  ch_tag
            )
   NEXTCLADE_DATASETGET.out.dataset
      .view()
*/
   //read subtypes.csv file and create channel with sample name, fasta path and dataset for each sample
   Channel.fromPath(subtypesPath)
      .splitCsv(header: ['sample', 'subtype'], skip: 1)
      .filter (row -> row.subtype.length() >  1) //filter out samples with no determined subtypes
      .map { row ->
         def sample = row.sample
         def subtype = row.subtype
         println ("Staging sample ${sample} (${subtype} subtype) for clade analysis.")
         if ( subtype.length() <  2)
            println ("   -Skipping sample ${sample}. No subtype determined")
         if ( subtype.startsWith('H1') ) {
            dataset = "${referencePath}/flu_h1n1pdm_ha"
         } else {
            if ( subtype.startsWith('H3') ) {
               dataset =  "${referencePath}/flu_h3n2_ha"
            } else { 
               println ("Sample HA subtype other than H1 or H3 found for sample ${sample}") 
            }   
         }
         fasta = "${runDir}/${sample}.irma.consensus.fasta"
         [ sample, fasta, dataset ] 
      }
      .set { ch_samples }

   //NEXTCLADE_DATASETGET.out.dataset
   //   .view()
   NEXTCLADE_RUN (
            ch_samples.map {it -> [it[0], it[1]]},
            ch_samples.map {it -> [it[2]]}
      )
   NEXTCLADE_RUN.out.csv
      .view()
}

