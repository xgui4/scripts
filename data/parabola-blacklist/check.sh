#!/bin/bash
# Copyright 2014           Michał Masłowski <mtjm@mtjm.eu>
# Copyright 2019,2020,2023 bill-auger       <bill-auger@programmer.net>
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# blacklist::check.sh Verify the blacklist entries are correctly formatted.

readonly BLACKLISTS=( aur-blacklist.txt                 \
                      blacklist.txt                     \
                      your-gaming-freedom-blacklist.txt \
                      your-init-freedom-blacklist.txt   \
                      your-privacy-blacklist.txt        )
readonly REF_REGEX='^[^:]*:[^:]*::[^:]*:.*$'
readonly SYNTAX_REGEX='^[^:]*:[^:]*:(debian|fedora|fsf|parabola|savannah)?:[^:]*:.*$'
readonly CSV_CHAR=':'
readonly SEP_CHAR='!'
readonly LOG_FILE=./check.log ; rm -f ${LOG_FILE} ;


exit_status=0

# TODO: the best sorting results are acheived when the field separator ($CSV_CHAR)
#         precedes any valid package name character in ASCII order
#       the lowest of which is ASCII 43 '+', and spaces are not allowed;
#         so ASCII 33 ('!') serves this purpose quite well
#       someday, we should re-write the tools to use parse on '!' instead of ':'
#       if that were done, then the `sort` command alone would yeild
#         the same results as this procedure, except for removing empty lines
unsortable="$(
  for blacklist in "${BLACKLISTS[@]}"
  do  echo -n "sorting and cleaning: '${blacklist}' ... " >> ${LOG_FILE}
      if   grep ${SEP_CHAR} ${blacklist}
      then echo "ERROR: can not sort - contains '${SEP_CHAR}' char" >> ${LOG_FILE}
           retval=1
      else echo "OK" >> ${LOG_FILE}
           cat ${blacklist}        | tr "${CSV_CHAR}" "${SEP_CHAR}" | sort | uniq |     \
           sed '/^[[:space:]]*$/d' | tr "${SEP_CHAR}" "${CSV_CHAR}" > ${blacklist}.temp
           mv ${blacklist}.temp ${blacklist}
      fi
  done
)"
if   [[ -n "$unsortable" ]]
then printf "\n[Entries containing '%s' char]:\n%s\n\n" "${SEP_CHAR}" "$unsortable" >> ${LOG_FILE}
     echo -n "ERROR: one of the data files is unsortable - check can not continue"
     echo " - correct the malformed entries, then run this script again"
     exit 1
fi

printf "\n\nchecking for entries with syntax errors: ... " >> ${LOG_FILE}
invalid="$(grep -E -v ${SYNTAX_REGEX} "${BLACKLISTS[@]}")"
if   [[ -z "$invalid" ]]
then printf "OK\n" >> ${LOG_FILE}
else printf "\n[Incorrectly formatted entries]:\n%s\n\n" "$invalid" >> ${LOG_FILE}
     exit_status=1
fi

printf "\n\nchecking for entries without reference to detailed description: ... " >> ${LOG_FILE}
unsourced="$(grep -E ${REF_REGEX} "${BLACKLISTS[@]}")"
if   [[ -z "$unsourced" ]]
then printf "OK\n" >> ${LOG_FILE}
else printf "\n[citation needed]:\n%s\n\n" "$unsourced" >> ${LOG_FILE}
     exit_status=1
fi

# summary
totals=$(wc -l "${BLACKLISTS[@]}" | sed 's|\(.*\)|\t\1|')
n_unsourced=$( [[ "${unsourced}" ]] && wc -l <<<${unsourced} || echo 0 )
n_malformed=$( [[ "${invalid}"   ]] && wc -l <<<${invalid}   || echo 0 )
echo -e "summary:\n\t* number of entries total:\n${totals}"
(( ${n_malformed} )) && echo -e "\t* number of entries improperly formatted: ${n_malformed}"
(( ${n_unsourced} )) && echo -e "\t* number of entries needing citation: ${n_unsourced}"
(( ${exit_status} )) && echo "refer to the file: '${LOG_FILE}' for details"

exit $exit_status
