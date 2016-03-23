#!/usr/bin/python

import os

class Phpenv(object):
    def __init__(self, module):
        self.module             = module
        self.available_commands = []

        self.root        = os.path.expanduser(self.module.params['phpenv_root'])
        self.php_version = self.module.params['php_version']
        self.phpenv_bin  = os.path.expanduser(self.root + "/bin")

        self.module.run_command_environ_update.update({'PHPENV_ROOT': self.root})
        if self.php_version:
            self.module.run_command_environ_update.update({'PHPENV_VERSION': self.php_version})

        self.init_command = "eval \"$(phpenv init -)\";"

    def is_command_valid(self, command):
        self.load_commands()

        if command not in self.available_commands:
            self.module.fail_json(
                msg = "%s is not a valid phpenv command" % command,
                available_commands = self.available_commands
            )

    def load_commands(self):
        list_commands = "%s phpenv commands" % self.init_command

        rc, out, err = self.module.run_command(
            list_commands,
            executable       = "/bin/bash",
            use_unsafe_shell = True,
            path_prefix      = self.phpenv_bin
        )

        self.available_commands = out.splitlines()

    def command(self, command):
        self.is_command_valid(command)

        if command == "install" and self.php_version:
            php_path = "%s/versions/%s/bin/php" % (self.root, self.php_version)

            php_path = os.path.expanduser(php_path)

            if os.path.exists(php_path):
                self.skip("skipped, since PHP %s is already installed" % self.php_version)

        command = "%s phpenv %s %s" % (self.init_command, command, self.module.params['arguments'])

        self.run(command)

    def shell(self, command):
        if self.module.params['creates']:
            # do not run the command if the line contains creates=filename
            # and the filename already exists. This allows idempotence
            creates = os.path.expanduser(self.module.params['creates'])
            if os.path.exists(creates):
                self.skip("skipped, since %s exists" % creates)

        if self.module.params['removes']:
            # do not run the command if the line contains removes=filename
            # and the filename do not exists. This allows idempotence
            removes = os.path.expanduser(self.module.params['removes'])
            if not os.path.exists(removes):
                self.skip("skipped, since %s does not exist" % removes)

        command = "%s %s" % (self.init_command, command)

        self.run(command)

    def run(self, command):
        rc, out, err = self.module.run_command(
            command,
            executable       = "/bin/bash",
            use_unsafe_shell = True,
            path_prefix      = self.phpenv_bin
        )

        self.module.exit_json(changed=True, rc=rc, stdout=out.strip(), stderr=err.strip())

    def skip(self, msg):
        self.module.exit_json(
            rc      = 0,
            changed = False,
            stdout  = msg,
            stderr  = False
        )

def main():
    module = AnsibleModule(
        argument_spec = dict(
            command     = dict(required=False, type='str'),
            arguments   = dict(required=False, default="", type='str'),
            shell       = dict(required=False, type='str'),
            php_version = dict(required=False, type='str'),
            phpenv_root = dict(required=False, default='~/.phpenv', type='str'),
            creates     = dict(required=False, type='str'),
            removes     = dict(required=False, type='str')
        ),
        mutually_exclusive = [['command', 'shell']],
    )

    phpenv = Phpenv(module)

    if module.params['shell']:
        phpenv.shell(module.params['shell'])
    else:
        command = "install"

        if module.params['command']:
            command = module.params['command']

        phpenv.command(command)

from ansible.module_utils.basic import *
if __name__ == '__main__':
    main()
