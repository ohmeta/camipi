#!/usr/bin/env python3

import argparse
import os
import sys
import subprocess as subp
import concurrent.futures
from pprint import pprint


def run(cmd):
    try:
        subp.run(cmd, shell=True)
    except subp.CalledProcessError as e:
        return cmd
    return None


def dl(cami_client_jar, base_url, pattern, output_dir, download_fastq, threads):
    base_url = base_url.strip("/") + "/"

    if "~" in cami_client_jar:
        cami_client_jar = os.path.join(
            os.path.expanduser("~"), cami_client_jar.split("/", 1)[1]
        )
    else:
        cami_client_jar = os.path.abspath(cami_client_jar)

    if "~" in output_dir:
        output_dir = os.path.join(os.path.expanduser("~"), output_dir.split("/", 1)[1])
    else:
        output_dir = os.path.abspath(output_dir)

    cmd = ["java", "-jar", cami_client_jar, "-l", base_url]
    dl_list = []

    if pattern is not None:
        cmd += ["-p", pattern]
    try:
        cami_list = subp.check_output(cmd, shell=False, stderr=subp.STDOUT)
        for i in cami_list.splitlines():
            i = i.decode()
            remote_file = f"{base_url}{i}"
            local_file = os.path.join(output_dir, i)
            local_dir = os.path.dirname(local_file)
            if not os.path.exists(local_dir):
                os.makedirs(local_dir, exist_ok=True)
            if (not download_fastq) and local_file.endswith("fq.gz"):
                next
            else:
                dl_list.append(f"curl -C - {remote_file} -o {local_file}")

    except subp.CalledProcessError as e:
        print("cami list returncode: ", e.returncode)
        print("cami std output: ", e.output)
        raise

    failed_list = []
    with concurrent.futures.ProcessPoolExecutor(max_workers=threads) as worker:
        for i in worker.map(run, dl_list):
            if i is not None:
                failed_list.append(i)

    for i in failed_list:
        print(f"download failed: {i}")


def main():
    parser = argparse.ArgumentParser("cami client wrapper")
    parser.add_argument(
        "--cami-client-jar",
        dest="cami_client_jar",
        help="path to cami-client-jar, default: ~/.local/bin/camiClient.jar",
        default="~/.local/bin/camiClient.jar",
    )
    parser.add_argument(
        "--base-url",
        dest="base_url",
        help="cami download url",
        default="https://openstack.cebitec.uni-bielefeld.de:8080/swift/v1/CAMI_Urogenital_tract",
    )
    parser.add_argument(
        "--pattern", dest="pattern", default=None, help="cami download pattern"
    )
    parser.add_argument(
        "--download-fastq",
        dest="download_fastq",
        action="store_true",
        default=False,
        help="download fastq, default: False",
    )
    parser.add_argument(
        "--output-dir",
        dest="output_dir",
        help="path to store downloaded file, default: ./",
        default="./",
    )
    parser.add_argument(
        "--threads", help="download threads, default: 4", type=int, default=4
    )
    args = parser.parse_args()
    dl(
        args.cami_client_jar,
        args.base_url,
        args.pattern,
        args.output_dir,
        args.download_fastq,
        args.threads,
    )


if __name__ == "__main__":
    main()
