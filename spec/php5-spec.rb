require_relative "bootstrap"

RSpec.configure do |config|
  config.before :suite do
    php_version = "5.6.32"

    AnsibleHelper.playbook("playbooks/playbook.yml", ENV["TARGET_HOST"], {
      php_version: php_version,

      pecl_extensions: [{
        name: "yaml",
        version: "1.3.1"
      }, {
        name: "imagick",
        version: "3.4.3"
      }, {
        name: "redis",
        version: "3.1.4"
      }],

      composer_packages: [{
        name: "phpunit/phpunit",
        version: "5.7.*"
      }, {
        name: "phpspec/phpspec",
        version: "3.4.*"
      }, {
        name: "psy/psysh",
        version: "0.8.*"
      }],

      domain: "php5-dev.dev",
      copy_index_php: true,
      copy_phpinfo: true
    })

    set :env, :PHPENV_VERSION => php_version

    set :docker_container_exec_options, { :Env => ["PHPENV_VERSION=#{php_version}", "COMPOSER_ALLOW_SUPERUSER=1"] }
  end

  config.before :each do
    @php_version = "5.6.32"
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

  include_examples("phpinfo", "error_log", "/usr/local/phpenv/versions/5.6.32/var/log/error.log")

  include_examples("phpinfo", "imagick module", "enabled")
  include_examples("phpinfo", "imagick module version", "3.4.3")

  include_examples("phpinfo", "Redis Support", "enabled")
  include_examples("phpinfo", "Redis Version", "3.1.4")

  include_examples("phpinfo", "LibYAML Support", "enabled")
  include_examples("phpinfo", "Module Version", "1.3.1")

  include_examples("phpinfo", "xdebug support", "enabled")
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
      expect(subject.stdout).to match /^PHPUnit 5\.7\.\d+/
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
      expect(subject.stdout).to match /phpspec 3\.4\.\d+/
    end

    include_examples("no errors")
  end
end

context "PHP FPM" do
  describe "index.php" do
    let(:subject) { command("curl -i php5-dev.dev") }

    include_examples("curl request", "200")

    include_examples "curl request html"

    it "contains the correct information" do
      expect(subject.stdout).to match /^Nginx is serving PHP #{Regexp.quote(@php_version)} code on php5-dev\.dev$/
    end
  end

  describe "Standard features" do
    include_examples("supports sessions", "php5-dev.dev")
    include_examples("logs errors", "php5-dev.dev")
    include_examples("sets open basedir", "php5-dev.dev")
  end

  describe "PHP Config" do
    let(:php_info) { command("curl php5-dev.dev/phpinfo.php").stdout }

    include_examples("phpinfo html heading", "xdebug support",            "enabled")
    include_examples("phpinfo html row",     "session.save_handler",      "files")
    include_examples("phpinfo html row",     "session.save_path",         "/usr/local/phpenv/versions/5.6.32/var/run/session")
    include_examples("phpinfo html row",     "session.serialize_handler", "php_serialize")
    include_examples("phpinfo html row",     "ENV_NAME",                  "dev")
    include_examples("phpinfo html row",     '_SERVER["ENV_NAME"]',       "dev")
  end
end
