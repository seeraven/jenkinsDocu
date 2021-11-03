# Backup of the Jenkins Server

Looking at all available Jenkins plugins and their associated issues, it seems
that no one is perfect and each of them provides a risk of incomplete or
unusable backups. Since backups are of utmost importance, we won't rely on
custom plugins, but use the old fashioned way of saving the complete Jenkins
home directory.


## Backup Method

To backup Jenkins, all we need to do is to backup the jenkins home. Using the
debian package, the default jenkins home directory is `/var/lib/jenkins`. In
order to perform the backup, we want to shutdown Jenkins, create a snapshot of
the jenkins home directory and start jenkins again. In theory, shutting down
Jenkins should not be necessary, but since there is a big gap between theory
and reality, we do the shutdown to be on the safe side.


### Shutting down Jenkins

There are many ways to shutdown Jenkins, e.g., by stopping the service or by
issuing the shutdown command over the Jenkins CLI. However, such a hard shutdown
often causes problems afterwards. For example, although pipelines should be
quite safe when it comes to interruptions, it turns out that after a restart
you can have quite ugly zombie pipeline steps filling up the queue or executors.

To avoid such problems, we use the
[safequietdown-plugin](https://github.com/seeraven/safequietdown-plugin) to
allow all downstream jobs and all started pipeline jobs to finish before
shutting down Jenkins.

In order to shutdown Jenkins, we perform the following steps:

  - Enable the safe quietdown mode in Jenkins using the Jenkins CLI.
  - Wait until we are sure there are no jobs running on the Jenkins any more.
  - Stop the Jenkins systemd service.


### File selection for Backup

Once Jenkins is shut down, we have to select the right files for the backup.
We select all files except the `workspace` folder, as this should contain only
left-overs of jobs. Depending on you setup, it might also be reasonable to
exclude the `log` and/or `logs` folders.


