#!/usr/bin/env bash
set -e

BAD_NAMES_REGEX="(utils|helpers|misc|common|process|handle|execute|run)"

if git diff --cached | grep -E "$BAD_NAMES_REGEX" ; then
    echo " Naming policy violation detected . "
    echo " Generic or ambiguous names found . "
    echo " Refer to Naming Conventions Policy . "
    exit 1
fi