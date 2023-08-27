rule all:
    input:
        'results/blast/1284.tsv'

rule unicycler: 
    input:
        long_='data/{sample}.fastq'
    output:
        folder=directory('results/unicycler/{sample}'),
        fasta='results/unicycler/{sample}/assembly.fasta'

    conda:
        'env/unicycler.yml'
    log:
        'log/unicycler/{sample}.log'
    shell:
        'unicycler -l {input.long_} -o {output.folder}'
'''
rule unicycler: 
    input:
        long_='data/{sample}.fastq',
        short_1='data/{sample}_1.fastq',
        short_2='data/{sample}_2.fastq'
    output:
        directory('results/unicycler/{sample}')
    conda:
        'env/unicycler.yml'
    log:
        'log/unicycler/{sample}.log'
    shell:
        '(unicycler -1 {input.short_1} -2 {input.short_2} -l {input.long_} -o {output}) > {log}'
'''
rule abricate:
    input:
        'results/unicycler/{sample}/assembly.fasta'
    output:
        'results/abricate_plasmid/{sample}.tab'
    conda:
        'env/abricate.yml'
    log:
        'log/abricate/{sample}.log'
    shell:
        'abricate -db plasmidfinder {input} > {output}'

rule contig_plasmid:
    input:
        'results/abricate_plasmid/{sample}.tab'
    output:
        'results/contigs_plasmid/{sample}.fasta'
    script:
        'scripts/contig_plasmid.py'

rule prokka:
    input:
        'results/contigs_plasmid/{sample}.fasta'
    output:
        folder=directory('results/prokka_plasmid/{sample}'),
        tsv='results/prokka_plasmid/{sample}/{sample}.tsv',
        ffn='results/prokka_plasmid/{sample}/{sample}.ffn'

    conda:
        'env/prokka.yml'
    log:
        'log/prokka/{sample}.log'
    shell:
        'prokka --outdir {output.folder} --prefix {wildcards.sample} {input} --force'
    
rule get_hypothetical:
    input:
        tsv='results/prokka_plasmid/{sample}/{sample}.tsv',
        ffn='results/prokka_plasmid/{sample}/{sample}.ffn'
    output:
        'results/annotation/{sample}_hypothetical.fasta'
    script:
        'scripts/get_hypothetical.py'

rule wget_uniprot:
    input:

    output:
        uniprot_fasta='bin/swissprot/uniprot_sprot.fasta',
    params:
        'https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz'
    log:
        'log/wget_uniprot.log'
    shell:
        'wget {params} -P bin/swissprot && '
        'gunzip {output.uniprot_fasta}.gz'

rule makeblastdb:
    input:
        uniprot_fasta='bin/swissprot/uniprot_sprot.fasta'
    output:
        phr='bin/swissprot/uniprot_sprot.fasta.phr',
        pin='bin/swissprot/uniprot_sprot.fasta.pin',
        psq='bin/swissprot/uniprot_sprot.fasta.psq'
    conda:
        'env/blast.yml'
    log:
        'log/makeblastdb.log'
    shell:
        'makeblastdb -dbtype prot -in {input.uniprot_fasta}'

rule blastx:
    input:
        hypothetical='results/annotation/{sample}_hypothetical.fasta',
        phr='bin/swissprot/uniprot_sprot.fasta.phr',
        pin='bin/swissprot/uniprot_sprot.fasta.pin',
        psq='bin/swissprot/uniprot_sprot.fasta.psq'
    output:
        'results/blast/{sample}.tsv'   
    conda:
        'env/blast.yml'
    log:
        'log/blastx/{sample}.log'
    shell:
        'blastx -query {input.hypothetical} -db bin/swissprot/uniprot_sprot.fasta'
        ' -out {output} -outfmt 6 -evalue 10 -max_hsps 1 -num_threads 4'
