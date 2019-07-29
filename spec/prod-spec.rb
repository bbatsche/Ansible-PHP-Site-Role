require_relative "lib/bootstrap"

RSpec.configure do |config|
  php_version = "7.2.20"

  config.before :suite do
    AnsibleHelper.playbook("playbooks/playbook.yml", ENV["TARGET_HOST"], {
      php_version: php_version,
      domain: "php-prod.dev",
      copy_index_php: true,
      copy_phpinfo: true,
      env_name: "prod"
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

  include_examples("phpinfo", "error_reporting",        "6143")
  include_examples("phpinfo", "display_errors",         "Off")
  include_examples("phpinfo", "display_startup_errors", "Off")

  include_examples("phpinfo", "Collecting statistics",        "No")
  include_examples("phpinfo", "Collecting memory statistics", "No")

  include_examples("phpinfo", "zend.assertions", "-1")

  include_examples("phpinfo", "opcache.revalidate_freq", "300")

  include_examples("phpinfo", "ENV_NAME",             "prod")
  include_examples("phpinfo", "$_SERVER['ENV_NAME']", "prod")

  it "does not have xdebug included" do
    expect(php_info).to_not match /xdebug/
  end
end

context "PHP FPM" do
  describe "index.php" do
    let(:subject) { command("curl -i php-prod.dev") }

    include_examples("curl request", "200")

    include_examples "curl request html"

    it "contains the correct information" do
      expect(subject.stdout).to match /^Nginx is serving PHP #{Regexp.quote(@php_version)} code on php-prod\.dev$/
    end
  end

  describe "Standard features" do
    include_examples("supports sessions", "php-prod.dev")
    include_examples("logs errors",       "php-prod.dev")
    include_examples("sets open basedir", "php-prod.dev")
  end

  describe "PHP Config" do
    let(:php_info) { command("curl php-prod.dev/phpinfo.php").stdout }

    include_examples("phpinfo html row",     "session.save_handler",      "files")
    include_examples("phpinfo html row",     "session.serialize_handler", "php_serialize")
    include_examples("phpinfo html row",     "ENV_NAME",                  "prod")
    include_examples("phpinfo html row",     "$_SERVER['ENV_NAME']",      "prod")

    it "has the correct path for sessions" do
      expect(php_info).to match %r|<td class="e">\s*session\.save_path\s*</td>\s*<td class="v">\s*/usr/local/phpenv/versions/#{@php_version}/var/run/session\s*</td>|
    end
    it "does not have xdebug included" do
      expect(php_info).to_not match /xdebug/
    end
  end

  describe "PHP FPM Config" do
    let(:subject) { file("/usr/local/phpenv/versions/#{@php_version}/etc/pool.d/php-prod.dev.conf") }

    it "should set process manager to dynamic" do
      expect(subject.content).to match /^pm\s*=\s*dynamic$/
    end
  end
end
