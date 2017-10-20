require_relative "bootstrap"

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

describe "PHP" do
  include_examples "php is installed"
end

describe "Phpenv" do
  include_examples "phpenv is installed"
end

describe "PHP Config" do
  let(:php_info) { command("php -i").stdout }

  include_examples("default phpinfo config")

  include_examples("phpinfo", "error_log", "/usr/local/phpenv/versions/7.1.10/var/log/error.log")

  include_examples("phpinfo", "imagick module", "enabled")
  include_examples("phpinfo", "imagick module version", "3.4.3")

  include_examples("phpinfo", "Redis Support", "enabled")
  include_examples("phpinfo", "Redis Version", "3.1.4")

  include_examples("phpinfo", "LibYAML Support", "enabled")
  include_examples("phpinfo", "Module Version", "2.0.2")
end

context "Composer packages" do
  describe "composer" do
    let(:subject) { command("composer about") }

    it "is installed" do
      expect(subject.stdout).to match /Composer - Package Management for PHP/
    end

    include_examples("no errors")
  end

  describe "phpunit" do
    let(:subject) { command("phpunit --version") }

    it "is installed" do
      expect(subject.stdout).to match /^PHPUnit 6\.4\.\d+/
    end

    include_examples("no errors")
  end

  describe "psysh" do
    let(:subject) { command("psysh --version") }

    it "is installed" do
      expect(subject.stdout).to match /Psy Shell v0\.8\.\d+/
    end

    include_examples("no errors")
  end

  describe "phpspec" do
    let(:subject) { command("phpspec --version") }

    it "is installed" do
      expect(subject.stdout).to match /phpspec 4\.0\.\d+/
    end

    include_examples("no errors")
  end
end
