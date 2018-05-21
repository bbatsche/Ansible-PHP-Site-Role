require_relative "lib/bootstrap"

RSpec.configure do |config|
  php_version = "7.1.10"

  config.before :suite do

    AnsibleHelper.playbook("playbooks/playbook.yml", ENV["TARGET_HOST"], {
      php_version: php_version,
      domain: "php-dynamic.dev",
      copy_index_php: true,
      dynamic_php: true
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

context "PHP FPM" do
  describe "index.php" do
    let(:subject) { command("curl -i php-dynamic.dev") }

    include_examples("curl request", "200")

    include_examples "curl request html"

    it "contains the correct information" do
      expect(subject.stdout).to match /^Nginx is serving PHP #{Regexp.quote(@php_version)} code on php-dynamic\.dev$/
    end
  end

  describe "another url" do
    let(:subject) { command("curl -i php-dynamic.dev/some_other_url") }

    include_examples("curl request", "200")

    include_examples "curl request html"

    it "redirected to index.php" do
      expect(subject.stdout).to match /^Nginx is serving PHP #{Regexp.quote(@php_version)} code on php-dynamic\.dev$/
    end
  end
end
