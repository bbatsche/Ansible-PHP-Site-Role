require_relative "lib/bootstrap"

RSpec.configure do |config|
  php_version = "7.2.20"

  config.before :suite do
    AnsibleHelper.playbook("playbooks/playbook.yml", ENV["TARGET_HOST"], {
      php_version: php_version,
      domain: "static-dev.test",
      dynamic_php: false,
      copy_index_php: true,
      copy_phpinfo: true,
      composer_packages: [{
        name: "phpunit/phpunit",
        version: "7.5.*"
      }, {
        name: "phpspec/phpspec",
        version: "5.1.*"
      }, {
        name: "psy/psysh",
        version: "0.9.*"
      }],
      fpm_mb_per_child: 10,
      fpm_mem_percent: 100,
      fpm_start_percent: 10,
      fpm_min_spare_percent: 5,
      fpm_max_spare_percent: 50
    })

    set :env, :PHPENV_VERSION => php_version

    set :docker_container_exec_options, { :Env => ["PHPENV_VERSION=#{php_version}", "COMPOSER_ALLOW_SUPERUSER=1"] }
  end

  config.before :each do
    @php_version = php_version
  end
end

describe "PHP" do
  let(:php_info) { command("php -i").stdout }

  include_examples "phpenv is installed"
  include_examples "php is installed"
  include_examples "nginx"
  include_examples "default phpinfo config"

  include_examples "phpinfo", "error_reporting",        "32767"
  include_examples "phpinfo", "display_errors",         "STDOUT"
  include_examples "phpinfo", "display_startup_errors", "On"

  include_examples "phpinfo", "Collecting statistics",        "Yes"
  include_examples "phpinfo", "Collecting memory statistics", "Yes"

  include_examples "phpinfo", "zend.assertions", "1"

  include_examples "phpinfo", "opcache.revalidate_freq", "0"

  include_examples "phpinfo", "xdebug support", "enabled"

  include_examples "phpinfo", "ENV_NAME",             "dev"
  include_examples "phpinfo", "$_SERVER['ENV_NAME']", "dev"

  include_examples "phpinfo", "imagick module", "enabled"
  include_examples "phpinfo", "imagick module version", "3.4.4"

  include_examples "phpinfo", "Redis Support", "enabled"
  include_examples "phpinfo", "Redis Version", "5.0.2"

  include_examples "phpinfo", "LibYAML Support", "enabled"
  include_examples "phpinfo", "Module Version", "2.0.4"
end

context "Composer packages" do
  describe "composer" do
    let(:subject) { command "composer about" }

    it "is installed" do
      expect(subject.stdout).to match /Composer - Dependency Manager for PHP/
    end

    include_examples "no errors"
  end

  describe "phpunit" do
    let(:subject) { command "phpunit --version" }

    it "is installed" do
      expect(subject.stdout).to match /^PHPUnit 7\.5\.\d+/
    end

    include_examples "no errors"
  end

  describe "psysh" do
    let(:subject) { command "psysh --version" }

    it "is installed" do
      expect(subject.stdout).to match /Psy Shell v0\.9\.\d+/
    end

    include_examples "no errors"
  end

  describe "phpspec" do
    let(:subject) { command "phpspec --version" }

    it "is installed" do
      expect(subject.stdout).to match /phpspec 5\.1\.\d+/
    end

    include_examples "no errors"
  end
end

context "PHP FPM" do
  describe "index.php" do
    let(:subject) { command "curl -i static-dev.test" }

    include_examples "curl request", "200"
    include_examples "curl request html"

    it "contains the correct information" do
      expect(subject.stdout).to match /^Nginx is serving PHP #{Regexp.quote(@php_version)} code on static-dev\.test$/
    end
  end

  describe "Standard features" do
    include_examples "supports sessions", "static-dev.test"
    include_examples "logs errors",       "static-dev.test"
    include_examples "sets open basedir", "static-dev.test"
  end

  describe "another url" do
    let(:subject) { command "curl -i static-dev.test/some_other_url" }

    include_examples "curl request", "404"
  end

  describe "PHP Config" do
    let(:php_info) { command("curl static-dev.test/phpinfo.php").stdout }

    include_examples "phpinfo html heading", "xdebug support",            "enabled"
    include_examples "phpinfo html row",     "session.save_handler",      "files"
    include_examples "phpinfo html row",     "session.serialize_handler", "php_serialize"
    include_examples "phpinfo html row",     "ENV_NAME",                  "dev"
    include_examples "phpinfo html row",     "$_SERVER['ENV_NAME']",      "dev"

    it "has the correct path for sessions" do
      expect(php_info).to match %r|<td class="e">\s*session\.save_path\s*</td>\s*<td class="v">\s*/usr/local/phpenv/versions/#{@php_version}/var/run/session\s*</td>|
    end
  end

  describe "PHP FPM Config" do
    let(:subject) { file "/usr/local/phpenv/versions/#{@php_version}/etc/pool.d/static-dev.test.conf" }
    totalMem = host_inventory["memory"]["total"].to_i / 1024

    it "should set max children to 100% of total memory" do
      value = subject.content.match(/^pm\.max_children\s*=\s*(\d+)$/).captures.first.to_i
      expect(value).to be_within(2).of(totalMem / 10) # 10mb per child, 100% of available memory
    end
    it "should set start servers to 10% of total memory" do
      value = subject.content.match(/^pm\.start_servers\s*=\s*(\d+)$/).captures.first.to_i
      expect(value).to be_within(2).of((totalMem * 0.1) / 10) # 10mb per child, 10% of available memory
    end
    it "should set min spare servers to 5% of total memory" do
      value = subject.content.match(/^pm\.min_spare_servers\s*=\s*(\d+)$/).captures.first.to_i
      expect(value).to be_within(2).of((totalMem * 0.05) / 10) # 10mb per child, 5% of available memory
    end
    it "should set max spare servers to 50% of total memory" do
      value = subject.content.match(/^pm\.max_spare_servers\s*=\s*(\d+)$/).captures.first.to_i
      expect(value).to be_within(2).of((totalMem * 0.5) / 10) # 10mb per child, 50% of available memory
    end
    it "should set process manager to ondemand" do
      expect(subject.content).to match /^pm\s*=\s*ondemand$/
    end
  end
end
