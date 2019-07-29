require_relative "lib/bootstrap"

RSpec.configure do |config|
  php_version = "7.2.20"

  config.before :suite do
    AnsibleHelper.playbook("playbooks/playbook.yml", ENV["TARGET_HOST"], {
      php_version: php_version,
      composer_packages: [{
        name: "phpunit/phpunit",
        version: "7.5.*"
      }, {
        name: "phpspec/phpspec",
        version: "5.1.*"
      }, {
        name: "psy/psysh",
        version: "0.9.*"
      }]
    })

    set :env, :PHPENV_VERSION => php_version

    set :docker_container_exec_options, { :Env => ["PHPENV_VERSION=#{php_version}", "COMPOSER_ALLOW_SUPERUSER=1"] }
  end

  config.before :all do
    @php_version = php_version
  end
end

describe "PHP" do
  include_examples "php is installed"
end

describe "Phpenv" do
  include_examples "phpenv is installed"
end

describe "PHP Config" do
  let(:php_info) { command("php -i").stdout }

  include_examples("default phpinfo config")

  it "has the correct error log path" do
    expect(php_info).to match %r|^error_log => /usr/local/phpenv/versions/#{@php_version}/var/log/error.log|
  end


  include_examples("phpinfo", "imagick module", "enabled")
  include_examples("phpinfo", "imagick module version", "3.4.4")

  include_examples("phpinfo", "Redis Support", "enabled")
  include_examples("phpinfo", "Redis Version", "5.0.2")

  include_examples("phpinfo", "LibYAML Support", "enabled")
  include_examples("phpinfo", "Module Version", "2.0.4")
end

context "Composer packages" do
  describe "composer" do
    let(:subject) { command("composer about") }

    it "is installed" do
      expect(subject.stdout).to match /Composer - Dependency Manager for PHP/
    end

    include_examples("no errors")
  end

  describe "phpunit" do
    let(:subject) { command("phpunit --version") }

    it "is installed" do
      expect(subject.stdout).to match /^PHPUnit 7\.5\.\d+/
    end

    include_examples("no errors")
  end

  describe "psysh" do
    let(:subject) { command("psysh --version") }

    it "is installed" do
      expect(subject.stdout).to match /Psy Shell v0\.9\.\d+/
    end

    include_examples("no errors")
  end

  describe "phpspec" do
    let(:subject) { command("phpspec --version") }

    it "is installed" do
      expect(subject.stdout).to match /phpspec 5\.1\.\d+/
    end

    include_examples("no errors")
  end
end
