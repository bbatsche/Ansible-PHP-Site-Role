require_relative "lib/bootstrap"

RSpec.configure do |config|
  config.before :suite do
    php_version = "7.1.10"

    AnsibleHelper.playbook("playbooks/playbook.yml", ENV["TARGET_HOST"], {
      php_version: php_version,
      fpm_max_children: 40,
      fpm_start_servers: 10,
      fpm_min_spare_servers: 5,
      fpm_max_spare_servers: 30,
      env_name: "prod",
      domain: "fpm-static.dev"
    })

    set :env, :PHPENV_VERSION => php_version

    set :docker_container_exec_options, { :Env => ["PHPENV_VERSION=#{php_version}", "COMPOSER_ALLOW_SUPERUSER=1"] }
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
end

describe "PHP FPM Config" do
  let(:subject) { file("/usr/local/phpenv/versions/#{@php_version}/etc/pool.d/fpm-static.dev.conf") }

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
end
