def get_fingerprint(cmd_list):
    '''
    ref: https://www.microbiome-cosi.org/cami/submitting-results-to-cami
    '''
    handle = subp.Popen(cmd_list, stdout=subp.PIPE, stderr=subp.PIPE)
    fingerprint = handle.stdout.read().decode().strip().split(" ")[-1]
    return fingerprint


if config["params"]["gen_assembly_fingerprint"]:
    ASSEMBLIES = pd.read_csv(config["input"]["assembly"], sep='\t').set_index("id")

    rule fingerprint_assembly:
        input:
            lambda wildcards: ASSEMBLIES.loc[wildcards.sample, "genome"]
        output:
            os.path.join(config["output"]["assembly"], "{sample}_assembly_fingerprint.tsv")
        params:
            id = "{sample}",
            cami_client = config["params"]["cami_client"]
        run:
            fingerprint = get_fingerprint(
                ["java", "-jar", params.cami_client, "-af", input[0]])

            df = pd.DataFrame(data={
                "id": [params.id],
                "fingerprint": [fingerprint]
            })
            df.to_csv(output[0], sep='\t', index=False)


    rule fingerprint_assembly_merge:
        input:
            expand(
                os.path.join(config["output"]["assembly"],
                             "{sample}_assembly_fingerprint.tsv"),
                sample=ASSEMBLIES.index.unique())
        output:
            os.path.join(os.path.dirname(config["output"]["assembly"]),
                         "fingerprint_assembly.tsv")
        threads:
            8
        run:
            metapi.merge(input, metapi.parse, threads, output=output[0])


    rule fingerprint_assembly_all:
        input:
            os.path.join(os.path.dirname(config["output"]["assembly"]),
                         "fingerprint_assembly.tsv")

else:
    rule fingerprint_assembly_all:
        input:


if config["params"]["gen_binning_fingerprint"] or config["params"]["gen_profiling_fingerprint"]:
    rule taxdb_prepare:
        output:
            os.path.join(os.path.dirname(config["output"]["binning"],
                                         ".taxdb.prepare.done"))
        params:
            local = config["params"]["taxdb"]["local"],
            remote = config["params"]["taxdb"]["remote"]
        run:
            if os.path.exists(params.local):
                shell('''touch {output}''')
            else:
                shell(
                    '''
                    wget {params}.remote
                    tar -xvf taxdb.tar.gz
                    mv taxdb {params.local}
                    touch {output}
                    ''')


if config["params"]["gen_binning_fingerprint"]:
    BINS = pd.read_csv(config["input"]["binning"], sep='\t').set_index("id")

    rule fingerprint_binning:
        input:
            done = os.path.join(
                os.path.dirname(config["output"]["binning"],
                                ".taxdb.prepare.done")),
            taxdb = config["params"]["taxdb"]["local"],
            bin = lambda wildcards: BINS.loc[wildcards.sample, "bins"]
        output:
            os.path.join(config["output"]["binning"],
                         "{sample}_binning_fingerprint.tsv")
        params:
            id = "{sample}",
            cami_client = config["params"]["cami_client"]
        run:
            fingerprint = get_fingerprint(
                ["java", "-jar", params.cami_client, "-bf", input.bin, input.taxdb])

            df = pd.DataFrame(data={
                "id": [params.id],
                "fingerprint": [fingerprint]
            })
            df.to_csv(output[0], sep='\t', index=False)


    rule fingerprint_binning_merge:
        input:
            expand(
                os.path.join(config["output"]["binning"],
                             "{sample}_binning_fingerprint.tsv"),
                sample=BINS.index.unique())
        output:
            os.path.join(os.path.dirname(config["output"]["binning"]),
                         "fingerprint_binning.tsv")
        threads:
            8
        run:
            metapi.merge(input, metapi.parse, threads, output=output[0])


    rule fingerprint_binning_all:
        input:
            os.path.join(os.path.dirname(config["output"]["binning"]),
                         "fingerprint_binning.tsv")

else:
    rule fingerprint_binning_all:
        input:


if config["params"]["gen_profiling_fingerprint"]:
    PROFILES = pd.read_csv(config["input"]["profiling"], sep='\t').set_index("id")

    rule fingerprint_profiling:
        input:
            done = os.path.join(
                os.path.dirname(config["output"]["binning"],
                                ".taxdb.prepare.done")),
            taxdb = config["params"]["taxdb"]["local"],
            profile = lambda wildcards: PROFILES.loc[wildcards.sample, "profile"]
        output:
            os.path.join(config["output"]["profiling"],
                         "{sample}_profiling_fingerprint.tsv")
        params:
            id = "{sample}",
            cami_client = config["params"]["cami_client"]
        run:
            fingerprint = get_fingerprint(
                ["java", "-jar", params.cami_client, "-pf", input.profile, input.taxdb])

            df = pd.DataFrame(data={
                "id": [params.id],
                "fingerprint": [fingerprint]
            })
            df.to_csv(output[0], sep='\t', index=False)


    rule fingerprint_profiling_merge:
        input:
            expand(
                os.path.join(config["output"]["profiling"],
                             "{sample}_profiling_fingerprint.tsv"),
                sample=PROFILES.index.unique())
        output:
            os.path.join(os.path.dirname(config["output"]["profiling"]),
                         "fingerprint_profiling.tsv")
        threads:
            8
        run:
            metapi.merge(input, metapi.parse, threads, output=output[0])


    rule fingerprint_profiling_all:
        input:
            os.path.join(os.path.dirname(config["output"]["profiling"]),
                         "fingerprint_profiling.tsv")

else:
    rule fingerprint_profiling_all:
        input:


rule cami_fingerprint_all:
    input:
        rules.fingerprint_assembly_all.input,
        rules.fingerprint_binning_all.input,
        rules.fingerprint_profiling_all.input
