#!/usr/bin/env bash

set -eo pipefail

generate() {
	output=$1
	args=$2
	postargs=$3

	crop="select-by-selector:svg;fit-canvas-to-selection"
	optimize="export-text-to-path;export-plain-svg"

	inkscape --batch-process -l --actions="$args;select-clear;$crop;$optimize;$postargs" -w 1024 -o "$outdir/$output" $source
}

if [[ -z $1 ]]; then
	echo "Usage: $0 <owocafe.svg>"
	exit 1
fi

source=$1
outdir=out

notext="select-by-id:owocafeLogo;delete-selection"
noborder="select-by-selector:path[inkscape\00003Alabel=borde];object-set-property:stroke-width,0"

mkdir -p "$outdir"

for ext in svg png; do
	generate owotan.$ext "$notext;$noborder"
	generate owotan-border.$ext "$notext"
	generate owotan-banner.$ext "$noborder"
	generate owotan-banner-border.$ext ""
done

# Generate social banner with imagemagic as adding flexible padding is hard to do in inkscape
convert $outdir/owotan-banner-border.png -background transparent -gravity center -extent 1100x550 $outdir/owotan-banner-social.png
convert $outdir/owotan-banner-border.png -background transparent -gravity center -extent 1100x350 $outdir/owotan-banner-mascot.png
