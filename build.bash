#!/bin/bash

mkdir -p bin/script

# update version string
VERSION='v0.4'
GITHASH=`git rev-parse --short HEAD`

# copy readme
sed 's/\r$//' README.md | sed 's/$/\r/' | sed 's/\$VERSION\$/'$VERSION'/' | sed 's/\$GITHASH\$/'$GITHASH'/' > bin/キャッシュテキスト.txt

# copy script files
sed 's/\r$//' 'src/CacheText.lua' | sed 's/$/\r/' | sed 's/\$VERSION\$/'$VERSION'/' | sed 's/\$GITHASH\$/'$GITHASH'/' > 'bin/script/CacheText.lua'
sed 's/\r$//' 'src/CacheText.anm' | sed 's/$/\r/' | sed 's/\$VERSION\$/'$VERSION'/' | sed 's/\$GITHASH\$/'$GITHASH'/' > 'bin/script/CacheText.anm'
sed 's/\r$//' 'src/CacheText.exa' | sed 's/$/\r/' | sed 's/\$VERSION\$/'$VERSION'/' | sed 's/\$GITHASH\$/'$GITHASH'/' > 'bin/キャッシュテキスト.exa'
