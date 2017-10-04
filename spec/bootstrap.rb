require "serverspec"
require_relative "lib/ansible_helper"
require_relative "environments"
require_relative "shared/no_errors"

if ENV["CONTINUOUS_INTEGRATION"] == "true"
  set :backend, :docker

  set :docker_container, AnsibleHelper[ENV["TARGET_HOST"]].id

  # Trigger OS info refresh
  Specinfra.backend.os_info
else
  set :backend, :ssh

  set :ssh_options, AnsibleHelper[ENV["TARGET_HOST"]].sshConfig
end

# Disable sudo
set :disable_sudo, true

# use a login shell so that Phpenv is loaded
set :shell, "/bin/bash"
set :login_shell, true

# Set PATH
set :path, "/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:$PATH"

shared_examples "phpenv" do
  describe command("phpenv help") do
    it "has no errors" do
      expect(subject.exit_status).to eq 0
    end
  end
end
