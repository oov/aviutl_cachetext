#!/bin/bash

mkdir -p bin/script

# copy readme
sed 's/\r$//' README.md | sed 's/$/\r/' > bin/キャッシュテキスト.txt

# update version string
VERSION='v0.3'
GITHASH=`git rev-parse --short HEAD`
cat << EOS | sed 's/\r$//' | sed 's/$/\r/' > 'src/ver.lua'
-- CacheText $VERSION ( $GITHASH ) by oov
EOS

# copy script files
sed 's/\r$//' 'src/CacheText.lua' | sed 's/$/\r/' > 'bin/script/CacheText.lua'
sed 's/\r$//' 'src/CacheText.anm' | sed 's/$/\r/' > 'bin/script/CacheText.anm'
sed 's/\r$//' 'src/CacheText.exa' | sed 's/$/\r/' > 'bin/キャッシュテキスト.exa'
