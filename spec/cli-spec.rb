require_relative "lib/ansible_helper"
require_relative "bootstrap"
require_relative "shared/phpenv"

RSpec.configure do |config|
  config.before :suite do
    php_version = "7.1.10"

    AnsibleHelper.playbook("playbooks/playbook.yml", ENV["TARGET_HOST"], {
      php_version: php_version,
      pecl_extensions: [{
        name: "yaml",
        version: "2.0.2"
      }, {
        name: "imagick",
        version: "3.4.3"
      }, {
        name: "redis",
        version: "3.1.4"
      }],
      composer_packages: [{
        name: "phpunit/phpunit",
        version: "6.4.*"
      }, {
        name: "phpspec/phpspec",
        version: "4.0.*"
      }, {
        name: "psy/psysh",
        version: "0.8.*"
      }]
    })

    set :env, :PHPENV_VERSION => php_version
  end

  config.before :each do
    @php_version = "7.1.10"
  end
end

describe "php" do
  include_examples "php"
end

describe "phpenv" do
  include_examples "phpenv"
end

describe command("php -i") do
  include_examples("phpinfo", "error_log", "/usr/local/phpenv/versions/7.1.10/var/log/error.log")
  include_examples("phpinfo", "Default timezone", "Etc/UTC")
  include_examples("phpinfo", "PDO Driver for PostgreSQL", "enabled")

  include_examples("phpinfo", "imagick module", "enabled")
  include_examples("phpinfo", "imagick module version", "3.4.3")

  include_examples("phpinfo", "Redis Support", "enabled")
  include_examples("phpinfo", "Redis Version", "3.1.4")

  include_examples("phpinfo", "LibYAML Support", "enabled")
  include_examples("phpinfo", "Module Version", "2.0.2")
end

context "composer" do
  describe command("composer about") do
    include_examples("no errors")
  end

  describe command("phpunit --version") do
    it "is installed" do
      expect(subject.stdout).to match /^PHPUnit 6\.4\.\d+/
    end

    include_examples("no errors")
  end

  describe command("psysh --version") do
    it "is installed" do
      expect(subject.stdout).to match /Psy Shell v0\.8\.\d+/
    end

    include_examples("no errors")
  end

  describe command("phpspec --version") do
    it "is installed" do
      expect(subject.stdout).to match /phpspec 4\.0\.\d+/
    end

    include_examples("no errors")
  end
end
