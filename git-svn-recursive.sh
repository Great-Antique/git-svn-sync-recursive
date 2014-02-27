#!/usr/bin/env bash

### init
command=$1
gitBareBaseUrl='/home/git/';

### helpers
log(){
    time=`date +"%Y-%m-%d %H-%M-%S"`
    echo $time" "$1
}
filter-branch(){
    git filter-branch -f --msg-filter 'sed -e "/git-svn-id:/d"'
    git filter-branch -f --msg-filter '
    read msg
    if [ -n "$msg" ] ; then
        echo "$msg"
    else
        echo "<empty commit message>"
    fi'
}

### commands
case $command in
    "clone")
        log "========== CLONE ============="

        svnRepoUrl=$2;

        if [[ $svnRepoUrl == "" ]]; then
            log "Error: Invalid svn repo URL"
            exit 1
        fi

        authorsFilePath=$3
        if [[ $authorsFilePath != "" ]]; then
            if [[ ! -f $authorsFilePath ]]; then
                log "Error: Invalid svn authors file"
                exit 1
            else
                authorsFile=" --authors-file=$authorsFilePath"
            fi  
        else
            authorsFile=""
        fi

        log "========== START ============="
            log "Repo: $svnRepoUrl"

            gitRepoPath="$(echo $svnRepoUrl | awk '{gsub(/\/$/, ""); print}' | awk -F '/' '{print $NF }').git"
            log "Git repo path: $gitRepoPath"
            
            if [[ -f $gitRepoPath || -d $gitRepoPath ]]; then
                log "Error: $gitRepoPath is already exists"
                exit 1
            fi

            (
            log "git svn clone $authorsFile $svnRepoUrl $gitRepoPath"
            git svn clone $authorsFile $svnRepoUrl $gitRepoPath

            cd $gitRepoPath
            log `pwd`

            filter-branch
            
            git remote add bare $gitBareBaseUrl$gitRepoPath

            git push bare master

            )

        log "=========== END =============="
        ;;
    "rclone")
        log "===== RECURSIVE CLONE ======="

        svnBaseUrl=$2;

        if [[ $svnBaseUrl == "" ]]; then
            log "Error: Invalid svn repo base URL"
            exit 1
        fi

        gitReposPath=$3;
        if [[ $gitReposPath == "" || ! -d $gitReposPath ]]; then
            log "Error: Invalid git repos path"
            exit 1
        fi

        authorsFilePath=$4
        if [[ $authorsFilePath != "" ]]; then
            if [[ ! -f $authorsFilePath ]]; then
                log "Error: Invalid svn authors file"
                exit 1
            else
                authorsFile=" --authors-file=$authorsFilePath"
            fi  
        else
            authorsFile=""
        fi

        log "========== START ============="
        (
        cd $gitReposPath;
        log `pwd`

        log "svn ls $svnBaseUrl"
        repoList=(`svn ls $svnBaseUrl`)

        for repoName in "${repoList[@]}"
        do
            if [ ${repoName:${#repoName}-1} == "/" ]; then
                repo=${repoName:0:-1}
                repoUrl=$svnBaseUrl"/"$repo

                log "Repo: $repoUrl"

                (
                log "git svn clone $authorsFile $repoUrl $repo.git"
                git svn clone $authorsFile $repoUrl $repo.git

                cd $repo.git
                log `pwd`
                
                filter-branch

                git remote add bare $gitBareBaseUrl$repo.git

                git push bare master
                )

            log "------------------------------"
            fi
        done
        )
        log "=========== END =============="
        ;;
    "sync")
        log "========== SYNC  ============="

        repo=$2;
        if [[ $repo == "" || ! -d $repo ]]; then
            log "Error: Invalid repo"
            exit 1
        fi

        log "========== START ============="
        (
            cd $repo; 
            log `pwd`

            log "Repo: $repo"; 

            log "git svn fetch && git rebase git-svn" 
            git svn fetch && git rebase git-svn

            filter-branch

            git push bare master

            log "------------------------------"
        )
        log "=========== END =============="
        ;;
    "rsync")
        log "====== RECURSIVE SYNC ========"

        syncDir=$2;
        if [[ $syncDir == "" || ! -d $syncDir ]]; then
            log "Error: Invalid sync dir"
            exit 1
        fi

        log "========== START ============="
        (
        cd $syncDir
        log `pwd`

        dirList=(`ls -dl *.git --color=none | grep "^d" --color=none | awk '{print $9}'`)

        for dir in "${dirList[@]}"
        do  

            (
            cd $dir; 
            log `pwd`

            repo=`pwd`; 
            log "Repo: $repo"; 

            log "git svn fetch && git rebase git-svn" 
            git svn fetch && git rebase git-svn

            filter-branch

            git push bare master

            log "------------------------------"
            )

        done

        )
        log "=========== END =============="
        ;;
    "")
        log "Usage:"
        log "  clone <svnRepoUrl> [<authorsFilePath>]"
        log "  rclone <svnBaseUrl> <gitReposPath> [<authorsFilePath>]"
        log "  sync <gitRepoPath>"
        log "  rsync <syncDir>"
        ;;
    *)
        log "Unknown command"
        exit 1
        ;;
esac
