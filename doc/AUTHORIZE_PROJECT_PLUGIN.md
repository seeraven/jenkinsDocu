# The Authorize Project Plugin

The authorize project plugin allows you to run jobs as the user who actually
triggered the build rather than the default SYSTEM user. This is necessary in
combination of the [role-based authorization](ROLE_BASED_AUTHORIZATION.md) to
avoid that a user can trigger a job from another project without having the
permission to access that other project.


## Installation

Install the plugin [Authorize Project](https://plugins.jenkins.io/authorize-project/)
from the Plugin Manager.


## Configuration

Under `Manage Jenkins` open the `Configure Global Security` link. Under
`Access Control for Builds` click `Add` and select
`Project default Build Authorization`. Choose the strategy
`Run as User who Triggered Build`.
