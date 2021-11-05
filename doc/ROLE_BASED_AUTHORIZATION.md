# Role based Authorization Strategy

By using the [Role-based Authorization Strategy Plugin](https://plugins.jenkins.io/role-strategy/)
you can define the permissions of individual users based on global and item
roles. Here, we will discuss the setup for a multi-project Jenkins used by
multiple developers.

We want to create multiple projects separated by different root folders. E.g.,
we have the `project1` and `project2` folders. For each project, we have
users with different roles:

  - Users that only execute jobs, but do not develop jobs themselves. We call
    them just `users`.
  - Developers that create new jobs and need to debug them. If you have a lot
    of them, you can further distinguish between:
      - Developers that are allowed to manage credentials used within the
        project. Let's call them `trusted developers`.
      - Developers that do not need to manage credentials.

The separation of the developers into two groups does not mean that only
trusted developers would be able to retrieve credentials. Always keep in mind
that anyone who can access the Jenkins project to create new jobs or who has
write permissions on the used source code repositories can retrieve and decode
credentials! There is no way to prevent this due to the nature of a CI. You can
only reduce the chance of leaking credentials by avoiding global credentials
and use only per-project (resp. per-folder) credentials. See also
[Notes on Credentials](CREDENTIALS.md).


## Required Plugins

  - [Role-based Authorization Strategy Plugin](https://plugins.jenkins.io/role-strategy/)


## Initial Configuration

  - Under `Manage Jenkins` -> `Configure Global Security` you have to select
    the `Role-Based Strategy` in the Authorization section.
  - Under `Manage Jenkins` you will then find the `Manage and Assign Roles`
    link where you can configure the Role based Authorization Strategy.


## Example Configuration for two Projects

### Configuration under Manage Roles

![Manage Roles - Global Roles](images/role_strategy_global_roles.png?raw=true "Global Roles")
![Manage Roles - Item Roles](images/role_strategy_item_roles.png?raw=true "Item Roles")


### Configuration under Assign Roles

![Assign Roles - Global Roles](images/role_strategy_assignment_global_roles.png?raw=true "Global Roles")
![Assign Roles - Item Roles](images/role_strategy_assignment_item_roles.png?raw=true "Item Roles")
