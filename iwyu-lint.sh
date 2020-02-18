#!/usr/bin/env bash

script_name="$0"

help() {
    printf "%s" "
usage: ${script_name} [-h] [-v] [-o {clang,iwyu}] [-j JOBS] -p <build-path>
             [fix options] [source [source ...]] -- [<IWYU args>]
                           [source [source ...]]

Include-what-you-use compilation database linter.

fix_includes.py reads the output from the include-what-you-use
script on stdin -- run with --v=1 (default) verbose or above -- and,
unless --sort_only or --dry_run is specified,
modifies the files mentioned in the output, removing their old
#include lines and replacing them with the lines given by the
include_what_you_use script.  It also sorts the #include and
forward-declare lines.

All files mentioned in the include-what-you-use script are modified,
unless filenames are specified on the commandline, in which case only
those files are modified.

The exit code is the number of files that were modified (or that would
be modified if --dry_run was specified) unless that number exceeds 100,
in which case 100 is returned.

positional arguments:
  source                Zero or more source files (or directories) to run IWYU
                        on. Defaults to all in compilation database.

optional arguments:
  -h, --help            show this help message and exit
  -v, --verbose         Print IWYU commands
  -o {clang,iwyu}, --output-format {clang,iwyu}
                        Output format (default: iwyu)
  -j JOBS, --jobs JOBS  Number of concurrent subprocesses
  -p <build-path>       Compilation database path

fix options:
  -b, --blank_lines     Put a blank line between primary header file and C/C++
                        system #includes, and another blank line between
                        system #includes and google #includes [default]
  --noblank_lines
  --comments            Put comments after the #include lines
  --nocomments
  --safe_headers        Do not remove unused #includes/fwd-declares from
                        header files; just add new ones [default]
  --nosafe_headers
  --reorder             Re-order lines relative to other similar lines (e.g.
                        headers relative to other headers)
  --noreorder           Do not re-order lines relative to other similar lines.
  -s, --sort_only       Just sort #includes of files listed on cmdline; do not
                        add or remove any #includes
  -n, --dry_run         Do not actually edit any files; just print diffs.
                        Return code is 0 if no changes are needed, else
                        min(the number of files that would be modified, 100)
  --ignore_re=IGNORE_RE
                        fix_includes.py will skip editing any file whose name
                        matches this regular expression.
  --only_re=ONLY_RE     fix_includes.py will skip editing any file whose name
                        does not match this regular expression.
  --separate_project_includes=SEPARATE_PROJECT_INCLUDES
                        Sort #includes for current project separately from all
                        other #includes.  This flag specifies the root
                        directory of the current project. If the value is
                        \" <tld >\", #includes that share the same top-level
                        directory are assumed to be in the same project.  If
                        not specified, project #includes will be sorted with
                        other non-system #includes.
  -m, --keep_iwyu_namespace_format
                        Keep forward-declaration namespaces in IWYU format,
                        eg. namespace n1 { namespace n2 { class c1; } }. Do
                        not convert to \"normalized\" Google format: namespace
                        n1 {\nnamespace n2 {\n class c1;\n}\n}.
  --nokeep_iwyu_namespace_format
  -p BASEDIR, --basedir=BASEDIR
                        Specify the base directory. fix_includes will
                        interpret non-absolute filenames relative to this
                        path.
"
    exit 0
}

retval=
find_executable() {
    program_list="$*"
    while [[ $# -gt 0 ]]; do
        local program
        program="$1"
        # printf "find executable for %s\n" "${program}"
        if command -v "${program}"; then
            # printf "%s is found\n" "${program}"
            retval="${program}"
            return 0
        fi
        shift
    done
    printf "ERROR: %s - are not found\n" "$program_list" >&2
    printf "%s is required tools from %s\n" "$script_name" "https://include-what-you-use.org/" >&2
    exit 1
}

find_executable iwyu_tool.py iwyu_tool >/dev/null
IWYU_TOOL="${retval}"
find_executable fix_includes.py fix_include >/dev/null
FIX_INCLUDES="${retval}"

POSITIONAL=()
CHECK_ARGS=""
FIX_ARGS=""
IWYU_ARGS=""
VERBOSE=0

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -h | --help)
        help
        shift
        ;;
    -v | --verbose)
        CHECK_ARGS="${CHECK_ARGS} $1"
        VERBOSE=1
        shift # past argument
        ;;
    -o | --output-format)
        CHECK_ARGS="${CHECK_ARGS} $1 $2"
        shift # past argument
        shift # past value
        ;;
    -j | --jobs)
        CHECK_ARGS="${CHECK_ARGS} $1 $2"
        shift # past argument
        shift # past value
        ;;
    -p)
        CHECK_ARGS="${CHECK_ARGS} $1 $2"
        FIX_ARGS="${FIX_ARGS} $1 $2"
        shift # past argument
        shift # past value
        ;;
    -b | --blank_lines)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --noblank_lines)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --comments)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --nocomments)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --safe_headers)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --nosafe_headers)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --reorder)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --noreorder)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    -s | --sort_only)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    -n | --dry_run)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --create_cl_if_possible)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --nocreate_cl_if_possible)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    -m | --keep_iwyu_namespace_format)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --nokeep_iwyu_namespace_format)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --ignore_re=*)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --checkout_command=*)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --append_to_cl=*)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --separate_project_includes=*)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --invoking_command_line=*)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --basedir=*)
        FIX_ARGS="$FIX_ARGS $1"
        shift # past argument
        ;;
    --)
        shift # past argument
        IWYU_ARGS="$*"
        break
        ;;
    *)                     # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift              # past argument
        ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ $VERBOSE -eq 1 ]]; then
    printf "check_args: %s\n" "${CHECK_ARGS}"
    printf "fix_args:   %s\n" "${FIX_ARGS}"
    printf "iwyu_args:  %s\n" "${IWYU_ARGS}"
    printf "sources:    %s\n" "$*"
fi

temp_file=$(mktemp)
if [[ -z "$IWYU_ARGS" ]]; then
    # shellcheck disable=SC2086,SC2048
    $IWYU_TOOL $CHECK_ARGS $* &>"$temp_file"
else
    # shellcheck disable=SC2086,SC2048
    $IWYU_TOOL $CHECK_ARGS $* -- $IWYU_ARGS &>"$temp_file"
fi
# shellcheck disable=SC2086,SC2048
$FIX_INCLUDES $FIX_ARGS $* <"$temp_file"
rm "$temp_file"
