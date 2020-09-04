#!/bin/sh
set -ue
umask 0022
export LC_ALL=C
export PATH="$(command -p getconf PATH 2>/dev/null)${PATH+:}${PATH-}"
case $PATH in :*) PATH=${PATH#?};; esac
export UNIX_STD=2003

sedlyLF="$(printf '\\\012_')"; sedlyLF="${sedlyLF%_}"
{
od -A n -t x1 -v "$1" |
	tr ABCDEF abcdef |
	tr -Cd '0123456789abcdef\n' |
	sed 's/../&'"$sedlyLF"'/g' |
	grep . |
	tr '\n' ,
echo
} | tee >log1 |
sed '
: main
	s'\
"`	`"'!^2f,\(\(\([^25].,\)*\(2[^f],\)*\(5[^c],\)*\(5c,..,\)*\)*\)2f,'\
"`	     `"'\(\(\([^25].,\)*\(2[^f],\)*\(5[^c],\)*\(5c,..,\)*\)*\)2f,'\
"`	`"'!\1P\7R'\
"`	`"'!
	t prepare_subst
	s!^5c,\(..,\)!&'"$sedlyLF"'!
	t do_print
	s!^(\([^25].,\)*\(2[^f],\)*\(5[^c],\)*\)\{1,\}!&'"$sedlyLF"'!
	t do_print
	b finally

: do_print
	P
	s!^.\{1,\}'"$sedlyLF"'!!
	b main

: prepare_subst
	s!^!x!
		: unescape_pattern
		s!x\(\(\([^5],\)*\(5[^c]\)*\)*\)5c,\(..,[^P]*\)!\1x\5!
		t unescape_pattern
	s!x!!
	s!P!Px!
		: unescape_replacement
		s!x\(\(\([^5],\)*\(5[^c]\)*\)*\)5c,\(..,[^R]*\)!\1x\5!
		t unescape_replacement
	s!x!!
	: while_subst
	s!R\([^?]\)!R?\1!
		: if_subst_able
		s!^\([^P]*\)P\([^R]*\)R\([^?]*\)?\1!\1P\2R\3\2!
		t while_subst
		b next_char
		: next_char
		s!?\(..,\)!\1?!
		t if_subst_able
		b no_more_subst
	: no_more_subst
	s!^[^R]\{1,\}R!!
	s!?$!!
	b main

: finally
	d
' | 
tr , '\n' |
grep . |
cat -A; exit
awk '
# todo hex2text
' |
xargs -n 1 printf

# finally
exit 0
