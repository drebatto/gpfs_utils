# GPFS commands completion for bash shell
#
#  2015-05-05 dr <david.rebatto@mi.infn.it>


###
###  utility functions
###

__delopts()
{
    local dd
    for dd in $2; do
       eval "$1=(\${$1[@]/$dd})"
    done
} # __delopts()


__fslist()
{
   awk '/ gpfs / {d=$1;sub("/dev/","",d);printf d" "}' /etc/fstab
} # __fslist()

__nsdlist()
{
   mmlsfs ${1:-all} -d | awk '/^ -d/ { print $2 }'| tr ';' ' '
} # __nsdlist()

__poollist()
{
   awk -F':' '
     $2=="60_SG_DISKS" && $3=="'$1'" { disks[$22] += 1}
     END { for (x in disks) printf("%s ", x); print "" }
   ' /var/mmfs/gen/mmsdrfs;
} # __poollist()


###
###  mm* commands
###

#   mmlsfs {Device | all | all_local | all_remote} [-A] [-B] [-d] [-D]
#          [-E] [-f] [-i] [-I] [-j] [-k] [-K] [-L] [-m] [-M] [-n] [-o]
#          [-P] [-Q] [-r] [-R] [-S] [-t] [-T] [-u] [-V] [-z]
#          [--create-time] [--fastea] [--filesetdf] [--inode-limit]
#          [--perfileset-quota] [--mount-priority]
_mmlsfs() 
{
    local cur prev opts base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [[ $COMP_CWORD == 1 ]]; then
        opts="all all_local all_remote `__fslist`"
    elif [[ ${cur} == -* ]] ; then
        opts="-A -B -d -D -E -f -i -I -j -k -K -L -m -M -n -o"
        opts="${opts} -P -Q -r -R -S -t -T -u -V -z"
        opts="${opts} --create-time --fastea --filesetdf --inode-limit"
        opts="${opts} --perfileset-quota --mount-priority"
    fi

    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))  
    return 0
}
complete -F _mmlsfs mmlsfs


#   mmdiag [--all] [--version] [--waiters] [--threads] [--memory]
#          [--network] [--config] [--trace] [--assert] [--iohist]
#          [--tokenmgr] [--commands] [--stats]
_mmdiag() 
{
    local cur opts optsarray
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    opts="--all --version --waiters --threads --memory --network --config"
    opts="${opts} --trace --assert --iohist --tokenmgr --commands --stats"

    if [[ ${#COMP_WORDS[@]} -gt 2 ]]; then
        optsarray=($opts)
        opts="${COMP_WORDS[@]:1:${#COMP_WORDS[@]}-2}"
        __delopts optsarray "$opts"
        opts=${optsarray[@]}
    fi

    COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
    return 0
}
complete -F _mmdiag mmdiag


#   mmlsnsd [-a | -F | -f Device | -d "DiskName[;DiskName...]"]
#           [-L | -m | -M | -X] [-v]
_mmlsnsd()
{
    local cur prev opts optsarray
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [[ "${prev}" == "-f" ]]; then
        opts=`__fslist`
    elif [[ "${prev}" == "-d" ]]; then
        opts=`__nsdlist all_local`
    else
        optsarray=( -a -F -f -d -L -m -M -X -v )
        for c in ${COMP_WORDS[@]::${#COMP_WORDS[@]}-1}; do
            case "$c" in
            -a|-F|-f|-d)
                __delopts optsarray "-a -F -f -d"
                ;;
            -L|-m|-M|-X)
                __delopts optsarray "-L -m -M -X"
                ;;
            -v)
                __delopts optsarray "-v"
                ;;
            esac
        done
        opts=${optsarray[@]}
    fi

    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
    return 0
}
complete -F _mmlsnsd mmlsnsd


#   mmlsdisk Device [-d "DiskName[;DiskName...]"] [-e] [-L]
#      or
#   mmlsdisk Device [-d "DiskName[;DiskName...]"] {-m | -M}
_mmlsdisk()
{
    local cur prev opts base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [[ $COMP_CWORD == 1 ]]; then
        opts="`__fslist`"
    elif [[ "${prev}" == "-d" ]]; then
        opts=`__nsdlist ${COMP_WORDS[1]}`
    else
        optsarray=( -d -e -L -m -M )
        for c in ${COMP_WORDS[@]::${#COMP_WORDS[@]}-1}; do
            case "$c" in
            -e)
                __delopts optsarray "-m -M -e"
                ;;
            -L)
                __delopts optsarray "-m -M -L"
                ;;
            -m|-M)
                optsarray=()
                ;;
            esac
        done
        opts=${optsarray[@]}
    fi

    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
    return 0
}
complete -F _mmlsdisk mmlsdisk

#   mmlspool Device {PoolName[,PoolName...] | all} [-L]
_mmlspool()
{
    local cur prev opts base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [[ $COMP_CWORD == 1 ]]; then
        opts="`__fslist`"
    elif [[ $COMP_CWORD == 2 ]]; then
        opts="`__poollist ${COMP_WORDS[1]}` all"
    elif [[ $COMP_CWORD == 3 ]]; then
        opts="-L"
    fi

    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
    return 0
}
complete -F _mmlspool mmlspool

#   mmdf Device [-d] [-F] [-m] [-P PoolName] [-Y | --block-size {BlockSize | auto}]
#        [--qos QosClass]
_mmdf()
{
    local cur prev opts base optsarray
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [[ $COMP_CWORD == 1 ]]; then
        opts="`__fslist`"
    elif [[ "${prev}" == "-P" ]]; then
        opts="`__poollist ${COMP_WORDS[1]}`"
    elif [[ "${prev}" == "--block-size" ]]; then
        opts="auto K M G T"
    elif [[ "${prev}" == "--qos" ]]; then
        opts="maintenance other"
    else
        optsarray=( -d -F -m -P -Y --block-size --qos )
        for c in ${COMP_WORDS[@]::${#COMP_WORDS[@]}-1}; do
            case "$c" in
            -d|-F|-m|-P|--qos)
                __delopts optsarray "$c"
                ;;
            -Y|--block-size)
                __delopts optsarray "-Y --block-size"
                ;;
            esac
        done
        opts=${optsarray[@]}
    fi

    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
    return 0
}
complete -F _mmdf mmdf
