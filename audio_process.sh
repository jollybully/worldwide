#!/usr/bin/env bash

# DEPENDENCIES
# - python3
# - ffmpeg normalise
# -- pip3 install ffmpeg-normalize
# - ffmpeg

# FEATURES

# TODOs

# FUNCTIONS
get_sample_rate() {
	ffprobe -hide_banner -loglevel error -show_entries stream=sample_rate -of default=noprint_wrappers=1 "$1" | awk -F= '/^sample_rate/ { print $2 }'
}

strip_silence() {
	ffmpeg -hide_banner -loglevel error -i "$1" -af "silenceremove=start_periods=1:start_duration=1:start_threshold=$silence_thresh:detection=peak,aformat=dblp,areverse,silenceremove=start_periods=1:start_duration=1:start_threshold=$silence_thresh:detection=peak,aformat=dblp,areverse" "STRIPPED_$1"
}

normalize() {
	ffmpeg-normalize -pr -t -16.0 --sample-rate "$2" "$1" -o "NORMALIZED_$1"
}

crossfade_jingle() {
	ffmpeg -hide_banner -loglevel error -i "$jingle" -i "$1" -filter_complex acrossfade=d=$crossfade_duration:c1=exp:c2=nofade "JINGLE_$1"
}

fade_out() {
	echo "getting duration"
	duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$1")
	echo "duration=$duration"
	fade_start=$(bc <<<$duration-$fadeout_duration)
	echo $fade_start

	echo "adding fade and encoding mp3"
	ffmpeg -hide_banner -loglevel error -i "$1" -af "afade=t=out:st=$fade_start:d=$fadeout_duration" -codec:a libmp3lame -b:a 320k output.mp3
}

# VARIABLES
# silence threshold (in dB)
silence_thresh="-60dB"
# crossfade duration (in seconds)
crossfade_duration="4"
fadeout_duration="2"

jingle="jingles/jingle.wav"
audiofile="test.wav"

echo "finding sample rate"
sampleRate=$(get_sample_rate "$audiofile")
echo "sample rate=$sampleRate"

echo "stripping silence"
strip_silence "$audiofile"

echo "normalizing"
normalize "STRIPPED_$audiofile" "$sampleRate"

echo "adding jingle"
crossfade_jingle "NORMALIZED_STRIPPED_$audiofile"

echo "adding fadeout"
fade_out "JINGLE_NORMALIZED_STRIPPED_$audiofile"
