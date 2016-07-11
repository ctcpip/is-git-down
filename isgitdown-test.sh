#!/bin/sh

#delete existing log
rm isgitdown.templog

echo
echo

echo test no file
./isgitdown.sh

echo
echo

echo test start time within 3 minutes
echo `date -v-1M +"%s"` > isgitdown.templog
./isgitdown.sh

echo
echo

echo test start time over 3 minutes
echo `date -v-3M +"%s"` > isgitdown.templog
./isgitdown.sh

echo
echo

echo test last sent time within 30 minutes
echo `date -v-44M +"%s"` "|" `date -v-25M +"%s"` > isgitdown.templog
./isgitdown.sh

echo
echo

echo test last sent time over 30 minutes
echo `date -v-44M +"%s"` "|" `date -v-40M +"%s"` > isgitdown.templog
./isgitdown.sh

echo
echo
