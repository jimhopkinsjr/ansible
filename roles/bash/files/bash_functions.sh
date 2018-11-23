#!/usr/bin/env bash
debugon=false
my_name=functions.sh
redhat_release=$(cat /etc/redhat-release 2>/dev/null)


function pathmunge() {
    case ":${PATH}:" in
        *:"$1":*)
            ;;
        *)
            if [ "$2" = "after" ] ; then
                PATH=$PATH:$1
            else
                PATH=$1:$PATH
            fi
    esac
}


settitle() {
    printf "\033k%s\033\\" ${1}
}


do_set_dir_colors() {
    if [[ -f ~/.dircolors && -x /usr/bin/dircolors ]]; then
    eval "$(dircolors ~/.dircolors)"
    fi
}


_lrtail() {
    /usr/bin/ls -lrt --color=always "$@" | tail
}; alias lrtail='_lrtail' ; alias lrt='_lrtail'


pwgrep() {
    gpg -d ~/.crypt/passwords.gpg | grep "$@"
}


timestamp() {
  date --iso-8601=seconds
}


reverse_array() {
# Input: An array of strings, separated by whitespace.
# Output: The same array, reversed.
    local array
    array=("$@")
    for (( idx=${#array[@]}-1 ; idx>=0 ; idx-- )) ; do
        echo -n "${array[idx]} "
    done
}


format_bash_call_stack() {
# Formats a function call stack for printing in log messages.
# Input: A whitespace separated list of function names, typically
# "${FUNCNAME[*]}".
# Output: The same list, reversed, with the log_* function names and redundant
# main calls removed and spaces replaced with '->' indicators.
    local colons dedupe_mains input no_logs reversed
    input="$*"
    reversed=$(reverse_array ${input})
    dedupe_mains=${reversed/main main /main }
    no_logs=${dedupe_mains% log_*}
    colons=${no_logs// /:}
    echo ${colons}
}


log_debug() {
    local stack
    if [ _${debugon} == _true ]; then
        stack=$(format_bash_call_stack "${FUNCNAME[*]}")
        printf 'Debug [[%s: %s]]: %s\n' "${my_name}" "${stack}" "$*" > /dev/stderr
    fi
}


log_error() {
    local stack
    stack=$(format_bash_call_stack "${FUNCNAME[*]}")
    printf 'Error [[%s: %s]]: %s\n' "${my_name}" "${stack}" "$*" > /dev/stderr
}


log_info() {
    local stack
    stack=$(format_bash_call_stack "${FUNCNAME[*]}")
    printf '[[%s: %s]]: %s\n' "${my_name}" "${stack}" "$*"
}


is_gcp() {
# Checks if currently running in Google Compute Platform.
# Returns 0 if true, 1 if false.
    log_debug "Begin."
    local return_value
    if grep -q '^Google$' /sys/devices/virtual/dmi/id/sys_vendor ; then
        return_value=0
    else
        return_value=1
    fi
    log_debug "End. Returning \"${return_value}\"."
    return ${return_value}
}


is_macos() {
# Checks if currently running in a MacOS env.
# Returns 0 if true, 1 if false.
# Stubbed in for now; just returns 1.
    log_debug "Begin."
    local return_value
    return_value=1
    log_debug "End. Returning \"${return_value}\"."
    return ${return_value}
}


is_aws() {
# Checks if currently running in Amazon Web Services
# Returns 0 if true, 1 if false.
    log_debug "Begin."
    local return_value
    if curl -fm2 -so /dev/null http://169.254.169.254/1.0/meta-data/ami-id 2>/dev/null ; then
        return_value=0
    else
        return_value=1
    fi
    log_debug "End. Returning \"${return_value}\"."
    return ${return_value}
}


is_virtualbox() {
# Checks if currently running in Virtualbox.
# Returns 0 if true, 1 if false.
    log_debug "Begin."
    local return_value
    if grep -q '^VirtualBox' /sys/devices/virtual/dmi/id/product_name ; then
        return_value=0
    else
        return_value=1
    fi
    log_debug "End. Returning \"${return_value}\"."
    return ${return_value}
}


is_el6() {
# Checks if this is an EL 6  (RHEL or CentOS) system.
# Returns 0 for true; 1 for false.
    log_debug "Begin."
    if [[ ${redhat_release} = "CentOS release 6"* ]]; then
        log_debug "Detected CentOS 6."
        return_value=0
    elif [[ ${redhat_release} = "Red Hat Enterprise Linux Server release 6"* ]]; then
        log_debug "Detected RHEL 6."
        return_value=0
    else
        log_debug "Release \"${redhat_release}\" is not EL 6."
        return_value=1
    fi
    log_debug "End. Returning \"${return_value}\"."
    return $return_value
}


is_el7() {
# Checks if this is an EL 7  (RHEL or CentOS) system.
# Returns 0 for true; 1 for false.
    log_debug "Begin."
    if [[ ${redhat_release} = "CentOS Linux release 7"* ]]; then
        log_debug "Detected CentOS 7."
        return_value=0
    elif [[ ${redhat_release} = "Red Hat Enterprise Linux Server release 7"* ]]; then
        log_debug "Detected RHEL 7."
        return_value=0
    else
        log_debug "Release \"${redhat_release}\" is not EL 7."
        return_value=1
    fi
    log_debug "End. Returning \"${return_value}\"."
    return $return_value
}


is_centos() {
# Checks if this is a CentOS system.
# Returns 0 for true; 1 for false.
# Note: a "Red Hat Enterprise Linux" result will return FALSE.
    log_debug "Begin."
    local release
    release=$(cat /etc/redhat-release)
    if [[ _${release} == _"CentOS release "* ]] || \
       [[ _${release} == _"CentOS Linux release "* ]]; then
        log_debug "Detected \"${release}\", which is CentOS."
        return_value=0
    else
        log_debug "Detected \"${release}\", which is NOT CentOS."
        return_value=1
    fi
    log_debug "End. Returning \"${return_value}\"."
    return $return_value
}


is_puppet_two() {
# Attempts to determine if Puppet version 2.* is already installed.
# Returns 0 for true; 1 for false.
    local puppet_version return_value
    puppet_version=$(puppet --version 2>/dev/null || echo error )
    if [[ ${puppet_version} =~ ^2 ]]; then
        log_debug "Puppet 2 detected."
        return_value=0
    elif [[ ${puppet_version} = "error" ]]; then
        log_debug "Puppet not detected."
        return_value=1
    else
        log_debug "Puppet detected but not version 2."
        return_value=1
    fi
    return ${return_value}
}  # end is_puppet_two()


is_interactive() {
# Checks if the current shell is interactive.
# Returns 0 if true, 1 if false.
    log_debug "Begin."
    local return_value
    if [[ "$-" == *i* ]]; then
        return_value=0
    else
        return_value=1
    fi
    log_debug "End. Returning \"${return_value}\"."
    return ${return_value}
}


do_or_die() {
# If the provided script exists, run it.
# Otherwise, do nothing.
# If the script runs and returns non-zero exit code, abort execution immediately.
    log_debug "Begin."
    local result
    if [ -x "${1}" ]; then
        log_info "Running script \"${1}\"."
        bash "$@" ; result=$?
        if [ ! ${result} == 0 ]; then
            log_error "Script ${1} returned ${result}. Abort!"
            exit ${result}
        fi
    else
        log_info "No executable script \"${1}\". Skipping."
    fi
    log_debug "End."
}


do_set_tputs() {
# Sets a bunch of tput env vars.
# Returns 0.
#
# Reference:
#     tput setab N = bg color
#     tput setaf N = fg color
#        colors
#        0 = black
#        1 = red
#        2 = green
#        3 = yellow
#        4 = blue
#        5 = purple
#        6 = cyan
#        7 = white
#     tput bold = bold
#     tput dim = dim
#     tput smul = set underline
#     tput rmul = exit underline
#     tput rev = reverse
#     tput smso = set standout
#     tput rmso = exit standout
#     tput sgr0 = reset all

    if ( which tput >/dev/null ); then
    #
    #     export tput_reset="\[$(tput sgr0)\]"
    #     export tput_set_bold="\[$(tput bold)\]"
    #     export tput_set_dim="\[$(tput dim)\]"
    #     export tput_set_ul="\[$(tput smul)\]"
    #     export tput_unset_ul="\[$(tput rmul)\]"
    #     export tput_set_reverse="\[$(tput rev)\]"
    #     export tput_set_standout="\[$(tput smso)\]"
    #     export tput_unset_standout="\[$(tput rmso)\]"
    #     export tput_bg_black="\[$(tput setab 0)\]"
    #     export tput_bg_red="\[$(tput setab 1)\]"
    #     export tput_bg_green="\[$(tput setab 2)\]"
    #     export tput_bg_yellow="\[$(tput setab 3)\]"
    #     export tput_bg_blue="\[$(tput setab 4)\]"
    #     export tput_bg_purple="\[$(tput setab 5)\]"
    #     export tput_bg_cyan="\[$(tput setab 6)\]"
    #     export tput_bg_white="\[$(tput setab 7)\]"
    #     export tput_fg_black="\[$(tput setaf 0)\]"
    #     export tput_fg_red="\[$(tput setaf 1)\]"
    #     export tput_fg_green="\[$(tput setaf 2)\]"
    #     export tput_fg_yellow="\[$(tput setaf 3)\]"
    #     export tput_fg_blue="\[$(tput setaf 4)\]"
    #     export tput_fg_purple="\[$(tput setaf 5)\]"
    #     export tput_fg_cyan="\[$(tput setaf 6)\]"
    #     export tput_fg_white="\[$(tput setaf 7)\]"

        export tput_reset="$(tput sgr0)"
        export tput_set_bold="$(tput bold)"
        export tput_set_dim="$(tput dim)"
        export tput_set_ul="$(tput smul)"
        export tput_unset_ul="$(tput rmul)"
        export tput_set_reverse="$(tput rev)"
        export tput_set_standout="$(tput smso)"
        export tput_unset_standout="$(tput rmso)"
        export tput_bg_black="$(tput setab 0)"
        export tput_bg_red="$(tput setab 1)"
        export tput_bg_green="$(tput setab 2)"
        export tput_bg_yellow="$(tput setab 3)"
        export tput_bg_blue="$(tput setab 4)"
        export tput_bg_purple="$(tput setab 5)"
        export tput_bg_cyan="$(tput setab 6)"
        export tput_bg_white="$(tput setab 7)"
        export tput_fg_black="$(tput setaf 0)"
        export tput_fg_red="$(tput setaf 1)"
        export tput_fg_green="$(tput setaf 2)"
        export tput_fg_yellow="$(tput setaf 3)"
        export tput_fg_blue="$(tput setaf 4)"
        export tput_fg_purple="$(tput setaf 5)"
        export tput_fg_cyan="$(tput setaf 6)"
        export tput_fg_white="$(tput setaf 7)"
    fi
    return 0
}  # end set_tputs()


do_set_less_termcaps() {
# Sets LESS_TERMCAP values for pretty file viewing.
# Returns 0.

    export LESS_TERMCAP_mb=$(tput bold; tput setaf 2) # green
    export LESS_TERMCAP_md=$(tput bold; tput setaf 6) # cyan
    export LESS_TERMCAP_me=$(tput sgr0)
    export LESS_TERMCAP_so=$(tput bold; tput setaf 3; tput setab 4) # yellow on blue
    export LESS_TERMCAP_se=$(tput rmso; tput sgr0)
    export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 7) # white
    export LESS_TERMCAP_ue=$(tput rmul; tput sgr0)
    export LESS_TERMCAP_mr=$(tput rev)
    export LESS_TERMCAP_mh=$(tput dim)
    export LESS_TERMCAP_ZN=$(tput ssubm)
    export LESS_TERMCAP_ZV=$(tput rsubm)
    export LESS_TERMCAP_ZO=$(tput ssupm)
    export LESS_TERMCAP_ZW=$(tput rsupm)
    export LESS="--RAW-CONTROL-CHARS"
    return 0
}


do_set_aliases() {
# Sets a ton of aliases.
# Returns 0.

    uname_a=$(uname -a)

    # Environment-specific:
    case $(uname -a) in
        Darwin*)
            alias idea='open -a "IntelliJ IDEA CE.app"'
            alias ls='ls -G'
            alias ll='ls -lF'
            alias l='ls'
            alias grep='/usr/bin/grep --color=always'
            alias updatedb='/usr/libexec/locate.updatedb'
            alias less='less -RFX'
            alias cdsvn='cd ~/svn'
            alias openssl1='/usr/local/Cellar/openssl@1.1/1.1.0h/bin/openssl'
            ;;
        *Linux*)
            alias ls='/bin/ls --color=always'
            alias ll='ls -lF'
            alias l='ls'
            alias grep='/bin/grep --color=always'
            alias ip='ip -4'
            alias less='less -RFX'
            alias cdsvn='cd ~/svn'
            alias tree='tree -c'
            alias cr='cmus-remote'
            alias crplay='cmus-remote --play' crp='crplay'
            alias crpause='cmus-remote --pause' cru='crpause'
            alias crresume='cmus-remote --pause'
            alias crprev='cmus-remote --prev' crr='crprev'
            alias crnext='cmus-remote --next' crn='crnext'
            alias crstop='cmus-remote --stop' crs='crstop'
            alias crvolume='cmus-remote --volume' crv='crvolume'
            alias whatprovides='sudo yum whatprovides'
            ;;
        * )
            ;;
    esac

    # git
    alias g=git
    alias gs='git status'
    alias gst='git status'
    alias gg='git gui &'
    alias cola='nohup git cola >/dev/null 2>&1 & '
    alias ecola='exec cola'
    alias gs='git status'
    alias gti='git'
    alias gpoh='git push -u origin head'

    # vagrant
    alias v=vagrant
    alias vup='vagrant up'
    alias vsh='vagrant ssh'
    alias vst='vagrant status'
    alias vstat='vagrant status'

    # text
    alias shrug='echo ${shrug}'
    alias shrugn='echo -n ${shrug}'
    alias brofist='echo ${brofist}'
    alias thumbsup='echo ${thumbsup}'

    # Misc
    alias ..='cd ..'
    alias b=brightness
    alias batterysaver='~/bin/setbrightness 60 && ~/bin/cpu s'
    alias d-c='docker-compose'
    alias gcal='sudo gcalcli'
    alias gerp='grep'
    alias gvim='gvim -p'
    alias lrtail='ls -lrt | tail'
    alias status='git status'
    alias tf=terraform
    alias tree='tree -C'
    alias vi='vim'
    alias slugify='slugify -d'

    # Docker
    alias cleanup='do_docker_cleanup'
}  # end do_set_aliases


do_set_sparks() {
# Sets spark characters for showing progress in ascii output.
# Returns 0

    export spark_1='▁'
    export spark_2='▂'
    export spark_3='▃'
    export spark_4='▄'
    export spark_5='▅'
    export spark_6='▆'
    export spark_7='▇'
    export spark_8='█'

    export spark_percent_00='▁'
    export spark_percent_12='▂'
    export spark_percent_25='▃'
    export spark_percent_37='▄'
    export spark_percent_50='▅'
    export spark_percent_62='▆'
    export spark_percent_75='▇'
    export spark_percent_87='█'

    return 0
}


do_docker_cleanup() {
# Does a few simple docker cleanup steps.
# Returns sum of results of commands run.
    log_debug "Begin."
    local return_value=0


    docker container prune -f
    return_value=$(( return_value + $? ))
    docker image prune -f
    return_value=$(( return_value + $? ))
    docker volume prune -f
    return_value=$(( return_value + $? ))

    log_debug "End. Returning \"${return_value}\"."
    return ${return_value}
}


# Only invoke main() if we were NOT sourced.
# This allows other scripts to source this file and cherry-pick function calls.
[ "$0" = "$BASH_SOURCE" ] && nature=executed || nature=sourced
if [ _${nature} != _"sourced" ]; then
    log_debug "Executing main()."
    main
else
    log_debug "Being read as source. Skipping main() execution."
fi
