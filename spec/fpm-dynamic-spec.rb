require_relative "lib/bootstrap"

RSpec.configure do |config|
  php_version = "7.2.20"

  config.before :suite do
    AnsibleHelper.playbook("playbooks/playbook.yml", ENV["TARGET_HOST"], {
      php_version: php_version,
      fpm_mb_per_child: 10,
      fpm_mem_percent: 100,
      fpm_start_percent: 10,
      fpm_min_spare_percent: 5,
      fpm_max_spare_percent: 50,
      env_name: "prod",
      domain: "fpm-dynamic.dev"
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
end

describe "Phpenv" do
  include_examples "phpenv is installed"
end

describe "PHP Config" do
  let(:php_info) { command("php -i").stdout }

  include_examples("default phpinfo config")
end

describe "PHP FPM Config" do
  let(:subject) { file("/usr/local/phpenv/versions/#{@php_version}/etc/pool.d/fpm-dynamic.dev.conf") }
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
end
