#!/bin/sh

# Finds non-scene material in <share-dir> and stores logs in <log-dir>.
#
# Usage:
# ./find_non_scene_data.sh <log-dir> <share-dir>
# ./find_non_scene_data.sh '/disk0/logs/' '/disk0/share'
# ----------------------------------------------------------------------------

LOG_DIR="${1}/$(basename $2)"
SHARE_DIR="$2"

# ----------------------------------------------------------------------------

mkdir -p "$LOG_DIR"

rm -f "${LOG_DIR}/bad_directories.log"
rm -f "${LOG_DIR}/bad_files.log"
rm -f "${LOG_DIR}/bad_names.log"
rm -f "${LOG_DIR}/duplicate_files.log"
rm -f "${LOG_DIR}/missing_directories.log"

# ----------------------------------------------------------------------------

REGEX_ALLOWED_FILES='.+\.(([acr-xz])?[0-9]+|ace|arj|avi|cue|flac|jpg|m3u|mkv|mp4|mpg|mp3|nfo|rar|sfv|zip)$'

REGEX_RELEASE_FILES='.+\.(nfo|rar|sfv|zip)$'
REGEX_RELEASE_NAME='(^|.*/)[^/]+-[^/]+$'
REGEX_RELEASE_ALLOWED_CHARACTERS='[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\.-_]+'

REGEX_SHOW_FILES='.+\.(avi|jpg|mkv|mp4|mpg|nfo|r[0-9]+|rar|sfv)$'
REGEX_SHOW_NAME='.+\.(720p|1080p|2160p|BDRiP|BLURAY|DiVX|DVDR|DVD[^/]?Rip|H264|HDDVD|HDTV|PDTV|S?VCD|VHS[^/]?Rip|UHD|x264|x265|XViD)(\.|-).+'
REGEX_SHOW_NAME_NOT='.*\.(((AUDIO|DIR|NFO|RAR|SAMPLE|SUB)[^/]?FiX)|(READ[^/]?NFO)|(SUB[^/]?PACK)|SUBS)(\.|-).+'

REGEX_MUSIC_FILES='.+\.(flac|m3u|mp3|)$'

REGEX_DIRFIX_DIR='.+/[^/]+\.DIR[^/]?FiX[^/]+/[^/]+$'
REGEX_PROOF_DIR='.+/Proof/[^/]+$'
REGEX_PROOFFIX_DIR='.+/[^/]+\.PROOF[^/]?FiX[^/]+/[^/]+$'
REGEX_SAMPLE_DIR='.+/Sample/[^/]+$'
REGEX_SAMPLEFIX_DIR='.+/[^/]+\.SAMPLE[^/]?FiX[^/]+/[^/]+$'
REGEX_SUBS_DIR='.+/Subs?/[^/]+$'
REGEX_SUBFIX_DIR='.+/[^/]+\.SUB[^/]?FiX[^/]+/[^/]+$'

REGEX_JPG_FILES='.+\.(jpe?g|png)$'
REGEX_NFO_FILES='.+\.(nfo)$'
REGEX_SFV_FILES='.+\.(sfv)$'

REGEX_DIRFIX_FILES="$REGEX_NFO_FILES"
REGEX_PROOF_FILES="$REGEX_JPG_FILES"
REGEX_PROOFFIX_FILES="(${REGEX_JPG_FILES}|${REGEX_NFO_FILES})"
REGEX_SAMPLE_FILES='.+\.(avi|mkv|mp4|mpg)$'
REGEX_SAMPLEFIX_FILES="(${REGEX_NFO_FILES}|${REGEX_SAMPLE_FILES})"
REGEX_SUBS_FILES='.+\.(r[0-9]+|rar|sfv)$'
REGEX_SUBFIX_FILES="(${REGEX_NFO_FILES}|${REGEX_SUBS_FILES})"

REGEX_AVI_DIR='.+\.(DiVX|XViD)(\.|-)[^/]+$'
REGEX_MKV_DIR='.+\.(H264|x264|x265)(\.|-)[^/]+$'
REGEX_MPG_DIR='.+\.(S?VCD)(\.|-)[^/]+$'

REGEX_AVI_FILES='.+\.(avi)$'
REGEX_MKV_FILES='.+\.(mkv)$'
REGEX_MPG_FILES='.+\.(mpe?g)$'

REGEX_CAPITALIZATION_DIR='.+/(((CD|DISC|DVD)[0-9]+)|Extras|Proof|Sample|Subs|Vobsubs)$'

# ----------------------------------------------------------------------------
# Test for finding unallowed files
# ----------------------------------------------------------------------------
paths=$(find -E "$SHARE_DIR" -type f -not -iregex "$REGEX_ALLOWED_FILES" 2>/dev/null)

for path in $paths; do
    echo "$path" >> "${LOG_DIR}/bad_files.log"
done

# ----------------------------------------------------------------------------
# Test for finding unallowed directories
# ----------------------------------------------------------------------------
paths=$(find -E "$SHARE_DIR" -mindepth 1 -type d -links 2 -not -iregex "$REGEX_RELEASE_NAME" | egrep -iv "$REGEX_CAPITALIZATION_DIR" 2>/dev/null)

for path in $paths; do
    echo "$path" >> "${LOG_DIR}/bad_directories.log"
done

# ----------------------------------------------------------------------------
# Tests for releases
# ----------------------------------------------------------------------------
release_paths=$(find -E "$SHARE_DIR" -type f -iregex "$REGEX_RELEASE_FILES" | xargs dirname | uniq | egrep "$REGEX_RELEASE_NAME" 2>/dev/null)

for release_path in $release_paths; do
    release_name=$(basename "$release_path")

    all_files=$(find "$release_path" -type f 2>/dev/null)
    all_subdirs=$(find "$release_path" -mindepth 1 -type d 2>/dev/null)

    result=$(echo "$release_name" | egrep -i "$REGEX_SHOW_NAME" | egrep -iv "$REGEX_SHOW_NAME_NOT")

    if [ ! -z "$result" ]; then
# ----------------------------------------------------------------------------
# Tests for show releases
# ----------------------------------------------------------------------------
        result=$(echo "$all_files" | egrep -iv "$REGEX_SHOW_FILES")

        if [ ! -z "$result" ]; then
            echo "$result" >> "${LOG_DIR}/bad_files.log"
        fi

        result=$(echo "$all_files" | egrep -i "$REGEX_DIRFIX_DIR" | egrep -iv "$REGEX_DIRFIX_FILES")

        if [ ! -z "$result" ]; then
            echo "$result" >> "${LOG_DIR}/bad_files.log"
        fi

# ----------------------------------------------------------------------------
# Tests for Sample directories
# ----------------------------------------------------------------------------
        result=$(echo "$all_files" | egrep -i "(${REGEX_SAMPLE_DIR}|${REGEX_SAMPLEFIX_DIR})")

        if [ -z "$result" ]; then
            echo "$release_path" >> "${LOG_DIR}/missing_directories.log"
        fi

        result=$(echo "$all_files" | egrep -iv "(${REGEX_SAMPLE_DIR}|${REGEX_SAMPLEFIX_DIR})" | egrep -i "$REGEX_SAMPLE_FILES")

        if [ ! -z "$result" ]; then
            echo "$result" >> "${LOG_DIR}/bad_files.log"
        fi

        result=$(echo "$all_files" | egrep -i "$REGEX_SAMPLE_DIR" | egrep -iv "$REGEX_SAMPLE_FILES")

        if [ ! -z "$result" ]; then
            echo "$result" >> "${LOG_DIR}/bad_files.log"
        fi

        result=$(echo "$all_files" | egrep -i "$REGEX_SAMPLEFIX_DIR" | egrep -iv "$REGEX_SAMPLEFIX_FILES")

        if [ ! -z "$result" ]; then
            echo "$result" >> "${LOG_DIR}/bad_files.log"
        fi

        result=$(echo "$all_files" | egrep -i "(${REGEX_SAMPLE_DIR}|${REGEX_SAMPLEFIX_DIR})" | egrep -i "$REGEX_AVI_DIR" | egrep -iv "(${REGEX_AVI_FILES}|${REGEX_NFO_FILES})")

        if [ ! -z "$result" ]; then
            echo "$result" >> "${LOG_DIR}/bad_files.log"
        fi

        result=$(echo "$all_files" | egrep -i "(${REGEX_SAMPLE_DIR}|${REGEX_SAMPLEFIX_DIR})" | egrep -i "$REGEX_MKV_DIR" | egrep -iv "(${REGEX_MKV_FILES}|${REGEX_NFO_FILES})")

        if [ ! -z "$result" ]; then
            echo "$result" >> "${LOG_DIR}/bad_files.log"
        fi

        result=$(echo "$all_files" | egrep -i "(${REGEX_SAMPLE_DIR}|${REGEX_SAMPLEFIX_DIR})" | egrep -i "$REGEX_MPG_DIR" | egrep -iv "(${REGEX_MPG_FILES}|${REGEX_NFO_FILES})")

        if [ ! -z "$result" ]; then
            echo "$result" >> "${LOG_DIR}/bad_files.log"
        fi

# ----------------------------------------------------------------------------
# Tests for Proof directories
# ----------------------------------------------------------------------------
        result=$(echo "$all_files" | egrep -iv "(${REGEX_PROOF_DIR}|${REGEX_PROOFFIX_DIR})" | egrep -i "$REGEX_PROOF_FILES")

        if [ ! -z "$result" ]; then
            echo "$result" >> "${LOG_DIR}/bad_files.log"
        fi

        result=$(echo "$all_files" | egrep -i "$REGEX_PROOF_DIR" | egrep -iv "$REGEX_PROOF_FILES")

        if [ ! -z "$result" ]; then
            echo "$result" >> "${LOG_DIR}/bad_files.log"
        fi

        result=$(echo "$all_files" | egrep -i "$REGEX_PROOFFIX_DIR" | egrep -iv "$REGEX_PROOFFIX_FILES")

        if [ ! -z "$result" ]; then
            echo "$result" >> "${LOG_DIR}/bad_files.log"
        fi

# ----------------------------------------------------------------------------
# Tests for Subs directories
# ----------------------------------------------------------------------------
        result=$(echo "$all_files" | egrep -i "$REGEX_SUBS_DIR" | egrep -iv "$REGEX_SUBS_FILES")

        if [ ! -z "$result" ]; then
            echo "$result" >> "${LOG_DIR}/bad_files.log"
        fi

        result=$(echo "$all_files" | egrep -i "$REGEX_SUBFIX_DIR" | egrep -iv "$REGEX_SUBFIX_FILES")

        if [ ! -z "$result" ]; then
            echo "$result" >> "${LOG_DIR}/bad_files.log"
        fi
# ----------------------------------------------------------------------------
    else
# ----------------------------------------------------------------------------
# Tests for non-show releases
# ----------------------------------------------------------------------------
        # Do stuff
    fi

# ----------------------------------------------------------------------------
# Tests for all releases
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Tests for duplicate files
# ----------------------------------------------------------------------------
    result=$(echo "$all_files" | egrep -i "$REGEX_NFO_FILES" | xargs dirname | uniq -d)

    if [ ! -z "$result" ]; then
        echo "$result" >> "${LOG_DIR}/duplicate_files.log"
    fi

    result=$(echo "$all_files" | egrep -i "$REGEX_SFV_FILES" | xargs dirname | uniq -d)

    if [ ! -z "$result" ]; then
        echo "$result" >> "${LOG_DIR}/duplicate_files.log"
    fi

# ----------------------------------------------------------------------------
# Tests for capitalization
# ----------------------------------------------------------------------------
    result=$(echo "$all_subdirs" | egrep -i "$REGEX_CAPITALIZATION_DIR" | egrep -v "$REGEX_CAPITALIZATION_DIR")

    if [ ! -z "$result" ]; then
        echo "$result" >> "${LOG_DIR}/bad_names.log"
    fi

    result=$(echo "$all_files" | egrep -i "$REGEX_ALLOWED_FILES" | egrep -v "$REGEX_ALLOWED_FILES")

    if [ ! -z "$result" ]; then
        echo "$result" >> "${LOG_DIR}/bad_names.log"
    fi
# ----------------------------------------------------------------------------
done

sort -u -o "${LOG_DIR}/bad_directories.log" "${LOG_DIR}/bad_directories.log" 2>/dev/null
sort -u -o "${LOG_DIR}/bad_files.log" "${LOG_DIR}/bad_files.log" 2>/dev/null
sort -u -o "${LOG_DIR}/bad_names.log" "${LOG_DIR}/bad_names.log" 2>/dev/null
sort -u -o "${LOG_DIR}/duplicate_files.log" "${LOG_DIR}/duplicate_files.log" 2>/dev/null
sort -u -o "${LOG_DIR}/missing_directories.log" "${LOG_DIR}/missing_directories.log" 2>/dev/null

exit 0
