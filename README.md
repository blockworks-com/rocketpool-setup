# rocketpool-setup
Bash scripts to install a Rocket Pool node starting from a basic Ubuntu image.

## Update
There are some excellent automated deployments for Rocket Pool, such as https://github.com/cloudstruct/rocketpool-deploy. These rely on powerful automation platforms, like Ansible, and are the _right way_ to do it. Check them out!

## Why this repo?
We were involved in the Rocket Pool beta and it was easy enough to follow the doc to setup the first server. But there were several steps that were new to us so we spent time researching so we understood what was happening. We started stubbing out one bash script to help guide us. Over the following months, we expanded the number of servers and the number of people using the script. Over time, we removed many hardcoded values by prompting for values, and then setting some default values. Then we added more smaller scripts for maintenance. Then we had to rebuild when we upgraded OS servers.

You should check out this repo if you want help setting up and maintaining a Rocket Pool node server and also want to see the commands used. For example, you can see all of the Unbuntu firewall commands (ufw) in the script to give you a better understanding of what's being done. This transparency - or lack of sophistication - is an opportunity to learn about administering an Ubuntu server. At least that's been the benefit for us.

## Prerequisites
None.
We start with a fresh instance of Ubuntu Server so you need the root password. We've tested on 20.04 and 22.04. We're trying to avoid prerequisites.

## Preparation
Upload the scripts to the server as root user.
Upload the scripts again as non-root user.
Optional: modify the defaults in new-install.yml

## Run script
Run `./new-install.sh` to install and configure a rocketpool node.

```
$ . ./new-install.sh -h
-d    | --defaults   Use default values and default options
-h    | --help       Displays this help and exit
-p    | --prompt     Prompt for values and options during the installation
-v    | --verbose    Show additional information during the installation
```

## Caution
READ THE OFFICIAL [ROCKETPOOL DOCUMENTATION](https://docs.rocketpool.net/guides/node/starting-rp.html). We update the script as we hear about changes and when we're building a new server. We welcome improvements from others! If you find a gap, please help us by submitting a pull request.

## Linting and Testing
We started using [ShellCheck](https://github.com/koalaman/shellcheck) as a script static analysis to improve the scripts so they are more reliable and more maintainable. We started adding test scripts when we started using ShellCheck. In the future, we plan to use [Bash Automated Testing System](https://github.com/bats-core/bats-core). Read the [Getting Started](https://bats-core.readthedocs.io/en/stable/tutorial.html).

From our project root directory, run the following:
git submodule add https://github.com/bats-core/bats-core.git Tests/bats
git submodule add https://github.com/bats-core/bats-support.git Tests/test_helper/bats-support
git submodule add https://github.com/bats-core/bats-assert.git Tests/test_helper/bats-assert
