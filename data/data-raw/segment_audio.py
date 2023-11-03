#! /usr/bin/env python3

"""Segment Eurovision audio.

This script segments the audio from the Eurovision dataset using McFee and Ellis's (2014) linear discriminant analysis, as implemented in MSAF (Nieto and Bello, 2016).

Typical usage:

    ./segment_audio.py SOURCE_DIRECTORY OUTPUT_DIRECTORY
"""

import os
import os.path
import argparse
import msaf


## Set up argument parser

parser = \
    argparse.ArgumentParser(description = 'Segment and split Eurovision audio.')
parser.add_argument(
    '-j', '--jobs',
    type = int,
    default = 4,
    help = 'number of parallel jobs'
)
parser.add_argument(
    'input_dir',
    help = 'input directory (of audio directories)'
)
parser.add_argument(
    'output_dir',
    help = 'output directory for features',
)
args = parser.parse_args()
args.input_dir = os.path.abspath(args.input_dir)
args.output_dir = os.path.abspath(args.output_dir)

## Set up MSAF

msaf.config.default_bound_id = 'olda'
msaf.config.default_label_id = None
msaf.config.dataset.audio_dir = '.'

## Process audio

def process_audio(d):
    msaf.config.dataset.estimations_dir = \
        os.path.join(args.output_dir, 'estimations', d.name)
    msaf.config.dataset.features_dir = \
        os.path.join(args.output_dir, 'features', d.name)
    msaf.config.dataset.references_dir = \
        os.path.join(args.output_dir, 'references', d.name)
    msaf.process(d.path, n_jobs = args.jobs)

[
    process_audio(d)
    for d in os.scandir(args.input_dir)
    if d.is_dir()
]
