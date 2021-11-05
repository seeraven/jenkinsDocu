# Jenkins Server in Docker Container or as a System Service

Jenkins itself can be installed either by using a docker container or by
installing it into the host system, e.g., by using a debian package. In this
document, we will discuss the benefits of both variants.


## Advantages and Disadvantages of each Method

At first, using Jenkins in a docker container looks like an additional level
of security, since the core processes of the Jenkins server run in an
encapsulated environment. This means that if someone gets full access of the
Jenkins server, he will be able to see the container environment, but not the
host.

But depending on the wanted feature set, some elements of the host must be
exposed to the container as well. For example, if you want to use the host
based PAM authentication to authorize the Jenkins users, you need to expose
the configuration parts of the host to the container (and eventually need to
modify the docker image). Access to each required host service must be
realized to work from the docker container, which can mean quite an effort. And
if the infrastructure of your provider changes, adaptions might be necessary,
so you need to plan extra efforts for this too. As a result, the docker
container might be much less robust in terms of usability as a host
installation.

Installation on the host is often much easier and is secured by using a
dedicated `jenkins` user. This ensures some protection of the jenkins home
against other users (without sudo rights) and it allows the Jenkins server to
use all available services on the host.

Regarding updates of the Jenkins itself, both variants allow a quite easy update
method. With the docker container, you would stop the container, pull the image
and start the container again. When using a system service on the host, all you
have to do is update the system and the new package is installed.


## Comparison Matrix

| Topic         | Docker Container      | System Installation    |
| ------------- | --------------------- | ---------------------- |
| Installation  | Pulling the image     | Installing the package |
| Update        | Pulling the new image | Updating the package   |
| Auto Update   | Must be implemented   | Available by unattended upgrades or similar |
