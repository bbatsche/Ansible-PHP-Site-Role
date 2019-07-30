require_relative "lib/bootstrap"

RSpec.configure do |config|
  php_version = "7.2.20"

  config.before :suite do
    AnsibleHelper.playbook("playbooks/playbook.yml", ENV["TARGET_HOST"], {
      php_version: php_version,
      domain: "dynamic-prod.test",
      dynamic_php: true,
      copy_index_php: true,
      copy_phpinfo: true,
      dynamic_php: true,
      env_name: "prod",
      timezone: "America/Phoenix",
      php_max_execution_time: 240,
      php_memory_limit: "256M",
      php_open_basedir: ["/etc/nginx"],
      php_disabled_functions: ["shell_exec"],
      max_upload_size: "20",
      fpm_max_children: 40,
      fpm_start_servers: 10,
      fpm_min_spare_servers: 5,
      fpm_max_spare_servers: 30
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

  include_examples "phpinfo", "error_reporting",        "6143"
  include_examples "phpinfo", "display_errors",         "Off"
  include_examples "phpinfo", "display_startup_errors", "Off"

  include_examples "phpinfo", "Collecting statistics",        "No"
  include_examples "phpinfo", "Collecting memory statistics", "No"

  include_examples "phpinfo", "zend.assertions", "-1"

  include_examples "phpinfo", "opcache.revalidate_freq", "300"

  include_examples "phpinfo", "ENV_NAME",             "prod"
  include_examples "phpinfo", "$_SERVER['ENV_NAME']", "prod"

  it "does not have xdebug included" do
    expect(php_info).to_not match /xdebug/
  end
end

context "PHP FPM" do
  describe "index.php" do
    let(:subject) { command "curl -i dynamic-prod.test" }

    include_examples "curl request", "200"
    include_examples "curl request html"

    it "contains the correct information" do
      expect(subject.stdout).to match /^Nginx is serving PHP #{Regexp.quote(@php_version)} code on dynamic-prod\.test$/
    end
  end

  describe "Standard features" do
    include_examples("supports sessions", "dynamic-prod.test")
    include_examples("logs errors",       "dynamic-prod.test")
    include_examples("sets open basedir", "dynamic-prod.test")
  end

  describe "another url" do
    let(:subject) { command "curl -i dynamic-prod.test/some_other_url" }

    include_examples "curl request", "200"
    include_examples "curl request html"

    it "redirected to index.php" do
      expect(subject.stdout).to match /^Nginx is serving PHP #{Regexp.quote(@php_version)} code on dynamic-prod\.test$/
    end
  end

  describe "PHP Config" do
    let(:php_info) { command("curl dynamic-prod.test/phpinfo.php").stdout }

    include_examples "phpinfo html row", "session.save_handler",      "files"
    include_examples "phpinfo html row", "session.serialize_handler", "php_serialize"
    include_examples "phpinfo html row", "ENV_NAME",                  "prod"
    include_examples "phpinfo html row", "$_SERVER['ENV_NAME']",      "prod"
    include_examples "phpinfo html row", "Default timezone",          "America/Phoenix"
    include_examples "phpinfo html row", "max_execution_time",        "240"
    include_examples "phpinfo html row", "memory_limit",              "256M"
    include_examples "phpinfo html row", "upload_max_filesize",       "20M"

    it "has the correct path for sessions" do
      expect(php_info).to match %r|<td class="e">\s*session\.save_path\s*</td>\s*<td class="v">\s*/usr/local/phpenv/versions/#{@php_version}/var/run/session\s*</td>|
    end
    it "does not have xdebug included" do
      expect(php_info).to_not match /xdebug/
    end
  end

  describe "Sets Open Basedir" do
    let(:subject) { command "curl -i dynamic-prod.test/open_basedir_test.php?path=/etc/nginx/nginx.conf" }

    include_examples "curl request", "200"
    include_examples "curl request html"

    it "read the nginx.conf file" do
      expect(subject.stdout).to match /# Configuration File - Nginx Server Configs/
    end
  end

  describe "Disables Functions" do
    let(:subject) { command "curl -i dynamic-prod.test/disabled_functions_test.php" }

    include_examples "curl request", "200"
    include_examples "curl request html"
  end

  describe "Error Log" do
    let(:subject) { command "tail -n 4 /usr/local/phpenv/versions/#{@php_version}/var/log/error.log" }

    it "contains the previous error" do
      expect(subject.stdout).to match /PHP Warning:\s+shell_exec\(\) has been disabled for security reasons/
    end
  end

  describe "PHP FPM Config" do
    let(:subject) { file "/usr/local/phpenv/versions/#{@php_version}/etc/pool.d/dynamic-prod.test.conf" }

    it "should set max children to 50" do
      expect(subject.content).to match /^pm\.max_children\s*=\s*40$/
    end
    it "should set start servers to 10" do
      expect(subject.content).to match /^pm\.start_servers\s*=\s*10$/
    end
    it "should set min spare servers to 5" do
      expect(subject.content).to match /^pm\.min_spare_servers\s*=\s*5$/
    end
    it "should set max spare servers to 30" do
      expect(subject.content).to match /^pm\.max_spare_servers\s*=\s*30$/
    end
    it "should set process manager to dynamic" do
      expect(subject.content).to match /^pm\s*=\s*dynamic$/
    end
  end
end
