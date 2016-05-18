Ansible PHP Site Role
========================

[![Build Status](https://travis-ci.org/bbatsche/Ansible-PHP-Site-Role.svg?branch=master)](https://travis-ci.org/bbatsche/Ansible-PHP-Site-Role)

This Ansible role will install a given version of PHP on your server and set up a site in Nginx running PHP. The role uses [Phpenv](https://github.com/madumlao/phpenv) to manage the different versions of PHP. It should be able to install any version of PHP from 5.2 through 7.0 (although if you're installing PHP 5.2, you may need to seriously rethink your life choices ;-).

Requirements
------------

Phpenv requires Git to be installed on your server, but then what server doesn't have Git these days?

This role takes advantage of Linux filesystem ACLs and a group called "web-admin" for granting access to particular directories. You can either configure those steps manually or install the [`bbatsche.Base`](https://galaxy.ansible.com/bbatsche/Base/) role.

Role Variables
--------------

- `domain` &mdash; Site domain to be created
- `dynamic_php` &mdash; Whether or not Nginx should rewrite all requests on your site through `index.php`. This is used for most modern frameworks. Default is no
- `max_upload_size` &mdash; Maximum upload size in MB. Default is "10"
- `timezone` &mdash; Timezone that should be configured in PHP. Default is "Etc/UTC"
- `mysql_socket` &mdash; Path to default MySQL socket for use when connecting to localhost. Default is "/var/run/mysqld/mysqld.sock"
- `php_version` &mdash; Version of PHP to install with Phpenv. If this value is omitted, the OS default version will be used instead (5.5 for Ubuntu 14.04)
- `pecl_extensions` &mdash; A list of additional extension to install from [PECL](https://pecl.php.net/). Each value should have a `name` and a `version`
- `composer_packages` &mdash; A list of composer packages to install. Each value should have a `name` and a `version` property.
- `phpenv_version` &mdash; Version of [Phpenv](https://github.com/madumlao/phpenv) to install. Default is a Git SHA: "b003acc"
- `phpenv_composer_version` &mdash; Version of [Phpenv Composer Plugin](https://github.com/ryoakg/phpenv-composer) to install. Default is a Git SHA: "1a6611d"
- `phpenv_build_version` &mdash; Version of [PHP Build](https://github.com/php-build/php-build) to install. Default is a Git SHA: "876560b"
- `xdebug_version` &mdash; Version of [Xdebug](https://xdebug.org/) to install
- `copy_phpinfo` &mdash; Whether to copy a `phpinfo()` page to the new site. Default is no
- `copy_index_php` &mdash; Whether to copy an `index.php` stub file to the new site. Default is no
- `disabled_function` &mdash; A list of functions to disable when PHP is running from the web. The default value blocks functions that could be used to execute shell code or manipulate other processes on the server.
- `http_root` &mdash; Directory all sites will be created under. Default is "/srv/http"
- `phpenv_root` &mdash; Where to install Phpenv and its support files. Default is "/usr/local/phpenv"

Dependencies
------------

This role depends on bbatsche.Nginx. You must install that role first using:

```bash
ansible-galaxy install bbatsche.Nginx
```

Example Playbook
----------------

```yml
- hosts: servers
  roles:
  - role: bbatsche.Phpenv
    domain: my-php-site.dev
    php_version: 5.6.19
    xdebug_version: 2.4.0
    phpunit_version: ~5.2
    pecl_extensions:
    - name: yaml
      version: 1.2.0
    - name: imagick
      version: 3.4.0
```

License
-------

MIT

Testing
-------

Included with this role is a set of specs for testing each task individually or as a whole. To run these tests you will first need to have [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/) installed. The spec files are written using [Serverspec](http://serverspec.org/) so you will need Ruby and [Bundler](http://bundler.io/). _**Note:** To keep things nicely encapsulated, everything is run through `rake`, including Vagrant itself. Because of this, your version of bundler must match Vagrant's version requirements. As of this writing (Vagrant version 1.8.1) that means your version of bundler must be between 1.5.2 and 1.10.6._

To run the full suite of specs:

```bash
$ gem install bundler -v 1.10.6
$ bundle install
$ rake
```

To see the available rake tasks (and specs):

```bash
$ rake -T
```

There are several rake tasks for interacting with the test environment, including:

- `rake vagrant:up` &mdash; Boot the test environment (_**Note:** This will **not** run any provisioning tasks._)
- `rake vagrant:provision` &mdash; Provision the test environment
- `rake vagrant:destroy` &mdash; Destroy the test environment
- `rake vagrant[cmd]` &mdash; Run some arbitrary Vagrant command in the test environment. For example, to log in to the test environment run: `rake vagrant[ssh]`

These specs are **not** meant to test for idempotence. They are meant to check that the specified tasks perform their expected steps. Idempotency can be tested independently as a form of integration testing.
