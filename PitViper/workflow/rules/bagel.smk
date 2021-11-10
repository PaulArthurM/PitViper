



rule bagel_generate_count_matrix:
    """ Generate count matrix between two conditions for BAGEL. """
    input:
        samples=config['tsv_file'],
        counts=config['normalized_count_table']
    output:
        matrix="results/{token}/count_matrices/BAGEL/{treatment}_vs_{control}_count_matrix.txt"

    log:
        "logs/{token}/BAGEL/{treatment}_vs_{control}_count_matrix.log"
    shell:
        "python3 workflow/scripts/bagel_count_files.py \
            --file {input.samples} \
            --counts {input.counts} \
            --directory results/{wildcards.token}/count_matrices/BAGEL/ \
            --control {wildcards.control} \
            --treatment {wildcards.treatment} > {log}"



rule bagel_foldchange:
    "Run BAGEL's script for foldchange calculation."
    input:
        count_table = rules.bagel_generate_count_matrix.output.matrix
    output:
        foldchange="results/{token}/BAGEL/{treatment}_vs_{control}/{treatment}_vs_{control}_BAGEL.foldchange"
    params:
        "results/{token}/BAGEL/{treatment}_vs_{control}/{treatment}_vs_{control}_BAGEL"
    conda:
        "../envs/bagel.yaml"
    log:
        "logs/{token}/BAGEL/{treatment}_vs_{control}_foldchange.log"
    shell:
        "python workflow/scripts/bagel-for-knockout-screens-code/BAGEL-calc_foldchange.py \
            -i {input.count_table} \
            -o {params} \
            -c 1 > {log}"


def bagel_bf_columns(wildcards):
    file = "results/{token}/BAGEL/{treatment}_vs_{control}/{treatment}_vs_{control}_BAGEL.foldchange".format(token=wildcards.token, treatment=wildcards.treatment, control=wildcards.control)
    print('File:', file)
    content = pd.read_csv(file, sep="\t")
    out = ",".join([ str(i + 1) for i in range(len(content.columns)-2)])
    print(out)
    return out

rule bagel_bf:
    "Use BAGEL's foldchanges for gene essentiality analysis."
    input:
        foldchange = rules.bagel_foldchange.output.foldchange
    output:
        bf = "results/{token}/BAGEL/{treatment}_vs_{control}/{treatment}_vs_{control}_BAGEL_output.bf"
    params:
        nonessential = config['nonessentials'],
        essentials = config['essentials'],
        columns = bagel_bf_columns#",".join([ i + 1 for i in range(len())])
    log:
        "logs/{token}/BAGEL/{treatment}_vs_{control}_bf.log"
    conda:
        "../envs/bagel.yaml"
    shell:
        "python workflow/scripts/bagel-for-knockout-screens-code/BAGEL.py \
            -i {input.foldchange} \
            -o {output.bf} \
            -e {params.essentials} \
            -n {params.nonessential} \
            -c {params.columns} > {log}"


rule bagel_essentials_genes:
    "Get essential genes estimated by BAGEL."
    input:
        rules.bagel_bf.output.bf
    output:
        "results/{token}/BAGEL/{treatment}_vs_{control}/{treatment}_vs_{control}_bagel_essentials_genes.txt"
    shell:
        "gawk '(NR==1) {{print $0}} ($2 > 0 && NR!=1) {{print $0}}' {input} > {output}"


rule bagel_nonessentials_genes:
    "Get nonessential genes estimated by BAGEL."
    input:
        rules.bagel_bf.output.bf
    output:
        "results/{token}/BAGEL/{treatment}_vs_{control}/{treatment}_vs_{control}_bagel_nonessentials_genes.txt"
    shell:
        "gawk '(NR==1) {{print $0}} ($2 < 0 && NR!=1) {{print $0}}' {input} > {output}"
