# Credentials in Jenkins

Credentials in Jenkins are way better than storing credentials in the source
code repositories. But due to the nature of a CI system, where the individual
jobs need to retrieve the passwords etc., there is always the possibility to
retrieve the information by the users who can access them.


## Use API Tokens and Untrusted Users

  - As you can't avoid the risk of credentials being retrieved from Jenkins,
    you should only use API Tokens with very limited permissions whenever
    possible.
  - Before storing username/password credentials of real users, check if there
    is another way of working. For example, an ssh login using an ssh key
    or using already encrypted passwords.


## Global vs Folder Scope

When adding credentials using the `Manage Jenkins` -> `Manage Credentials`
link, you can add global credentials. These credentials can be used by any
job and therefore any user.

When you add credentials by clicking on the `Credentials` link shown when
inside a specific folder, then the credentials are only available to jobs
inside this folder. This is important for multi-project Jenkins servers
when you have a different set of users for different projects, as it
allows you to separate the credentials.


## Conclusion

If possible, add credentials only to a folder scope to limit the audience. As
a best practice, only system credentials (e.g., credentials used for connections
to other nodes) should be stored globally.
