require_relative "lib/bootstrap"

RSpec.configure do |config|
  php_version = "7.1.10"

  config.before :suite do

    AnsibleHelper.playbook("playbooks/playbook.yml", ENV["TARGET_HOST"], {
      php_version: php_version,
      domain: "php-variables.dev",
      copy_index_php: true,
      copy_phpinfo: true,
      timezone: "America/Phoenix",
      php_max_execution_time: 240,
      php_memory_limit: "256M",
      php_open_basedir: ["/etc/nginx"],
      php_disabled_functions: ["shell_exec"],
      max_upload_size: "20"
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
end

context "PHP FPM" do
  describe "Standard features" do
    include_examples("supports sessions", "php-variables.dev")
  end

  describe 'Customizes Config' do
    let(:php_info) { command("curl php-variables.dev/phpinfo.php").stdout }

    include_examples("phpinfo html row", "Default timezone",    "America/Phoenix")
    include_examples("phpinfo html row", "max_execution_time",  "240")
    include_examples("phpinfo html row", "memory_limit",        "256M")
    include_examples("phpinfo html row", "upload_max_filesize", "20M")
  end

  describe "Sets Open Basedir" do
    let(:subject) { command("curl -i php-variables.dev/open_basedir_test.php?path=/etc/nginx/nginx.conf") }

    include_examples("curl request", "200")
    include_examples("curl request html")

    it "read the nginx.conf file" do
      expect(subject.stdout).to match /# Configuration File - Nginx Server Configs/
    end
  end

  describe "Disables Functions" do
    let(:subject) { command("curl -i php-variables.dev/disabled_functions_test.php") }

    include_examples("curl request", "200")
    include_examples("curl request html")
  end

  describe "Error Log" do
    let(:subject) { command("tail -n 4 /usr/local/phpenv/versions/#{@php_version}/var/log/error.log") }

    it "contains the previous error" do
      expect(subject.stdout).to match /PHP Warning:\s+shell_exec\(\) has been disabled for security reasons/
    end
  end
end
