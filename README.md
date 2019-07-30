Ansible PHP Site Role
========================

[![Build Status](https://travis-ci.org/bbatsche/Ansible-PHP-Site-Role.svg)](https://travis-ci.org/bbatsche/Ansible-PHP-Site-Role)
[![License](https://img.shields.io/github/license/bbatsche/Ansible-PHP-Site-Role.svg)](LICENSE)
[![Ansible Galaxy](https://img.shields.io/ansible/role/22583.svg)](https://galaxy.ansible.com/bbatsche/PHP)
[![Release Version](https://img.shields.io/github/tag/bbatsche/Ansible-PHP-Site-Role.svg)](https://galaxy.ansible.com/bbatsche/PHP)
[![Downloads](https://img.shields.io/ansible/role/d/22583.svg)](https://galaxy.ansible.com/bbatsche/PHP)

This Ansible role will install a given version of PHP on your server and set up a site in Nginx running PHP. The role uses [Phpenv](https://github.com/madumlao/phpenv) to manage the different versions of PHP. It should be able to install any version of PHP from 5.2 through 7.2 (although if you're installing PHP 5.2, you may need to seriously rethink your life choices ;-).

Requirements
------------

Phpenv requires Git to be installed on your server, but then what server doesn't have Git these days?

This role takes advantage of Linux filesystem ACLs and a group called "web-admin" for granting access to particular directories. You can either configure those steps manually or install the [`bbatsche.Base`](https://galaxy.ansible.com/bbatsche/Base/) role.

In addition, installing this role to Ubuntu Xenial requires Ansible version 2.2 or greater. Ansible 2.1 is still supported by Ubuntu Trusty.

Role Variables
--------------

- `domain` &mdash; Site domain to be created
- `dynamic_php` &mdash; Whether or not Nginx should rewrite all requests on your site through `index.php`. This is used for most modern frameworks. Default is no
- `max_upload_size` &mdash; Maximum upload size in MB. Default is "10"
- `php_max_file_uploads` &mdash; Maximum number of files that can be uploaded simultaneously. Default is 20
- `timezone` &mdash; Timezone that should be configured in PHP. Default is "Etc/UTC"
- `mysql_socket` &mdash; Path to default MySQL socket for use when connecting to localhost.
- `install_mariadb` &mdash; Install MariaDB client libraries, rather than the default MySQL libraries. Default is no
- `php_session_save_handler` &mdash; Handler for saving sessions. Can be used to save session data to Redis, for example. Default is "files"
- `php_session_path` &mdash; Path to store session data in. Default is "`{{ phpenv_root }}/versions/{{ php_version }}/var/run/session`"
- `php_realpath_cache_size` &mdash; Size of cache used for looking up file & directory's real paths. Default is "256k"
- `php_realpath_cache_ttl` &mdash; Length of time to store entries in the realpath cache. Default is 600
- `php_max_execution_time` &mdash; Maximum length of time PHP is allowed to work (excluding calls to external resources like the filesystem). Default is 30.
- `php_default_socket_timeout` &mdash; Timeout when waiting for data from a socket. Default is 60
- `php_memory_limit` &mdash; Maximum amount of memory PHP is allowed to allocate for a single process. Default is "128M"
- `php_version` &mdash; Version of PHP to install with Phpenv.
- `phpenv_config_options` &mdash; List of flags to pass to PHP configure command (in addition to the defaults already included with Phpenv). Default: see [defaults/main.yml](defaults/main.yml)
- `phpenv_config_options_removed` &mdash; List of flags to _remove_ from Phpenv's standard list. Default is just `--with-tidy`
- `pecl_extensions` &mdash; A list of additional extension to install from [PECL](https://pecl.php.net/). Each value should have a `name` and a `version`
- `composer_packages` &mdash; A list of composer packages to install globally. Each value should have a `name` and a `version` property.
- `phpenv_version` &mdash; Version of [Phpenv](https://github.com/madumlao/phpenv) to install. Default is a Git SHA: "0852611"
- `phpenv_composer_version` &mdash; Version of [Phpenv Composer Plugin](https://github.com/ryoakg/phpenv-composer) to install. Default is a Git SHA: "1a6611d"
- `php_build_version` &mdash; Version of [PHP Build](https://github.com/php-build/php-build) to install. Default is a Git SHA: "5d166fe"
- `xdebug_version` &mdash; Version of [Xdebug](https://xdebug.org/) to install. Default is "2.5.5"
- `copy_phpinfo` &mdash; Whether to copy a `phpinfo()` page to the new site. Default is no
- `copy_index_php` &mdash; Whether to copy an `index.php` stub file to the new site. Default is no
- `disabled_function` &mdash; A list of functions to disable when PHP is running from the web.
- `open_basedir` &mdash; List of additional paths this domain should be able to read and write from. This list will always contain the domain's root itself, current PHP version's "var" directory (for session storage), and the domain's temp directory.
- `http_root` &mdash; Directory all sites will be created under. Default is "/srv/http"
- `phpenv_root` &mdash; Where to install Phpenv and its support files. Default is "/usr/local/phpenv"

### FPM Tuning Variables

PHP FPM is configured to run in one of two modes depending on `env_name`. In dev environments, PHP FPM will run in "ondemand" mode to minimize the number of processes spawned and sitting idle in a lower-resource dev environment. In other environments, FPM will run in "dynamic" mode so that child processes are already available to handle requests and don't need to be forked. When running in dynamic mode, there are a handful of ways to tweak FPM resource usage:

- `fpm_mb_per_child` &mdash; Average amount of memory a child process will consume for this domain. Default is "30"
- `fpm_mem_percent` &mdash; Maximum amount of total memory FPM should be allowed to consume. Default is "80"
- `fpm_max_children` &mdash; Maximum number of child processes to allow for this domain. Default is calculated based on `fpm_mem_percent` and `fpm_mb_per_child`
- `fpm_start_percent` &mdash; What percentage of FPM's max children should be started when the domain is initially created. Default is "20" with a floor of 2 servers total.
- `fpm_start_servers` &mdash; Number of servers to start when the domain is created. Default is calculated based on `fpm_start_percent`
- `fpm_max_spare_percent` &mash; Percentage of FPM's max children to keep active as spare servers when load begins to drop. Default is "80"
- `fpm_max_spare_servers` &mdash; Number of spare servers to keep active after a spike and as load begins to decline. Default is calculated based on `fpm_max_spare_percent`.

This allows you to tune your resource usage based either on a percentage of total memory **or** with static values, depending on your use case.

### Opcache Tuning Variables

The following variables can be used to tune Opcache and potentially improve application performance.

- `opcache_enable_cli` &mdash; Default is 0
- `opcache_memory_consumption` &mdash; Default is 128
- `opcache_internal_strings_buffer` &mdash; Default is 16
- `opcache_max_accelerated_files` &mdash; Default is 6000
- `opcache_max_wasted_percentage` &mdash; Default is 5
- `opcache_validate_timestamps` &mdash; Default is 1
- `opcache_revalidate_freq`&mdash; Set to 0 if the environment is dev. Otherwise, the default is 300
- `opcache_fast_shutdown` &mdash; Default is 0. Potentially risky if enabled

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
    domain: my-php-site.test
    php_version: 7.1.12
    composer_packages:
    - name: phpunit/phpunit
      version: ^6.4
    pecl_extensions:
    - name: yaml
      version: 2.0.2
    - name: imagick
      version: 3.4.3
```

License
-------

MIT

Testing
-------

Included with this role is a set of specs for testing each task individually or as a whole. To run these tests you will first need to have [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/) installed. The spec files are written using [Serverspec](http://serverspec.org/) so you will need Ruby and [Bundler](http://bundler.io/).

To run the full suite of specs:

```bash
$ gem install bundler
$ bundle install
$ rake
```

The spec suite will target Ubuntu Trusty Tahr (14.04), Xenial Xerus (16.04), and Bionic Bever (18.04).

To see the available rake tasks (and specs):

```bash
$ rake -T
```

These specs are **not** meant to test for idempotence. They are meant to check that the specified tasks perform their expected steps. Idempotency is tested independently via integration testing.
