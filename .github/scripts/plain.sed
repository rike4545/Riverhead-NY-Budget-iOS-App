# Turns summarise.sh's GitHub-flavoured markdown into plain terminal text.
# Kept as a file rather than an inline sed expression: the fence pattern
# contains backticks, which are painful to quote safely inside a Makefile
# recipe that is already a continued, quoted shell line.
s/^### //
/^```$/d
s/^\*\*\([A-Za-z]\{1,\}\)\*\*$/\1:/
