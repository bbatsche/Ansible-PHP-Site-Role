require_relative "bootstrap"

RSpec.configure do |config|
  php_version = "7.1.10"

  config.before :suite do

    AnsibleHelper.playbook("playbooks/playbook.yml", ENV["TARGET_HOST"], {
      php_version: php_version,
      domain: "php-dev.dev",
      copy_index_php: true,
      copy_phpinfo: true
    })

    set :env, :PHPENV_VERSION => php_version

    set :docker_container_exec_options, { :Env => ["PHPENV_VERSION=#{php_version}", "COMPOSER_ALLOW_SUPERUSER=1"] }
  end

  config.before :each do
    @php_version = php_version
  end
end

describe "PHP" do
  include_examples "php is installed"

  include_examples "nginx"
end

describe "Phpenv" do
  include_examples "phpenv is installed"
end

describe "PHP Config" do
  let(:php_info) { command("php -i").stdout }

  include_examples("default phpinfo config")

  include_examples("phpinfo", "error_reporting",        "32767")
  include_examples("phpinfo", "display_errors",         "STDOUT")
  include_examples("phpinfo", "display_startup_errors", "On")

  include_examples("phpinfo", "Collecting statistics",        "Yes")
  include_examples("phpinfo", "Collecting memory statistics", "Yes")

  include_examples("phpinfo", "zend.assertions", "1")

  include_examples("phpinfo", "opcache.revalidate_freq", "0")

  include_examples("phpinfo", "xdebug support", "enabled")

  include_examples("phpinfo", "ENV_NAME",             "dev")
  include_examples("phpinfo", "$_SERVER['ENV_NAME']", "dev")
end

context "PHP FPM" do
  describe "index.php" do
    let(:subject) { command("curl -i php-dev.dev") }

    include_examples("curl request", "200")

    include_examples "curl request html"

    it "contains the correct information" do
      expect(subject.stdout).to match /^Nginx is serving PHP #{Regexp.quote(@php_version)} code on php-dev\.dev$/
    end
  end

  describe "Standard features" do
    include_examples("supports sessions", "php-dev.dev")
    include_examples("logs errors", "php-dev.dev")
    include_examples("sets open basedir", "php-dev.dev")
  end

  describe "PHP Config" do
    let(:php_info) { command("curl php-dev.dev/phpinfo.php").stdout }

    include_examples("phpinfo html heading", "xdebug support",            "enabled")
    include_examples("phpinfo html row",     "session.save_handler",      "files")
    include_examples("phpinfo html row",     "session.save_path",         "/usr/local/phpenv/versions/7.1.10/var/run/session")
    include_examples("phpinfo html row",     "session.serialize_handler", "php_serialize")
    include_examples("phpinfo html row",     "ENV_NAME",                  "dev")
    include_examples("phpinfo html row",     "$_SERVER['ENV_NAME']",      "dev")
  end

  describe "PHP FPM Config" do
    let(:subject) { file("/usr/local/phpenv/versions/#{@php_version}/etc/pool.d/php-dev.dev.conf") }

    it "should set process manager to ondemand" do
      expect(subject.content).to match /^pm\s*=\s*ondemand$/
    end
  end
end
