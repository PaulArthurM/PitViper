



rule genes_integration:
    input:
        mageck_mle=rules.mageck_mle.output.gene_summary,
        mageck_rra=rules.mageck_rra.output.gene_summary,
        bagel=rules.bagel_bf.output.bf,
        crisphiermix=rules.CRISPhieRmix.output.gene_summary
    output:
        mageck_mle_genes="results/{token}/Integration/{treatment}_vs_{control}/Genes/MAGeck_MLE_{treatment}_vs_{control}.txt",
        mageck_rra_genes="results/{token}/Integration/{treatment}_vs_{control}/Genes/MAGeck_RRA_{treatment}_vs_{control}.txt",
        bagel_genes="results/{token}/Integration/{treatment}_vs_{control}/Genes/BAGEL_{treatment}_vs_{control}.txt",
        crisphiermix="results/{token}/Integration/{treatment}_vs_{control}/Genes/CRISPhieRmix_{treatment}_vs_{control}.txt"
    conda:
        "../envs/jupyter.yaml"
    log:
        notebook="notebooks/{token}/{treatment}_vs_{control}_genes_integration_notebook.ipynb"
    notebook:
        "../notebooks/Genes_Integration.py.ipynb"


def generatedResults(wildcards):
    results = []
    comparaisons = get_all_pairwise_comparaisons()

    token = config['token']

    for comparaison in comparaisons:
        if ((config['screen_type'] == "shRNA") or (config['screen_type'] == "CRISPR")) and (config['BAGEL']['activate'] == True):
            results.append("results/{token}/BAGEL/{treatment}_vs_{control}/{treatment}_vs_{control}_BAGEL_output.bf".format(token = token, treatment = comparaison['treatment'], control = comparaison['control']))
            results.append("results/{token}/BAGEL/{treatment}_vs_{control}/{treatment}_vs_{control}_bagel_essentials_genes.txt".format(token = token, treatment = comparaison['treatment'], control = comparaison['control']))
        if (config['MAGeCK']['MLE']['activate'] == True):
            results.append("results/{token}/MAGeCK_MLE/{treatment}_vs_{control}/{treatment}_vs_{control}.gene_summary.txt".format(token = token, treatment = comparaison['treatment'], control = comparaison['control']))
        if (config['MAGeCK']['RRA']['activate'] == True):
            results.append("results/{token}/MAGeCK_RRA/{treatment}_vs_{control}/{treatment}_vs_{control}.gene_summary.txt".format(token = token, treatment = comparaison['treatment'], control = comparaison['control']))
        if (config['CRISPhieRmix']['activate'] == True):
            results.append("results/{token}/CRISPhieRmix/{treatment}_vs_{control}/{treatment}_vs_{control}.txt".format(token = token, treatment = comparaison['treatment'], control = comparaison['control']))
        if (config['BAGEL']['activate'] == True):
            results.append("results/{token}/BAGEL/{treatment}_vs_{control}/{treatment}_vs_{control}_bagel_essentials_genes.txt".format(token = token, treatment = comparaison['treatment'], control = comparaison['control']))
            results.append("results/{token}/BAGEL/{treatment}_vs_{control}/{treatment}_vs_{control}_bagel_nonessentials_genes.txt".format(token = token, treatment = comparaison['treatment'], control = comparaison['control']))
    return results


rule integration:
    input:
        generatedResults
    output:
        pdf="results/" + config['token'] + "/reports/integration.pdf"
    conda:
        "../envs/jupyter.yaml"
    log:
        notebook="notebooks/" + config['token'] + "/report_integration_notebook.ipynb"
    notebook:
        "../notebooks/Reports_Integration.py.ipynb"