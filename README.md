# Bash script for recursive Git<-Svn sync

## Commands
* **clone** svnRepoUrl [_authorsFilePath_]
* **rclone** svnBaseUrl gitReposPath [_authorsFilePath_]
* **sync** gitRepoPath
* **rsync** syncDir

---
Note, that it normally works only when
you have enabled _**http-bulk-updates**_ option
in **~/.subversion/servers** file
 
```
[global]
http-bulk-updates=on
