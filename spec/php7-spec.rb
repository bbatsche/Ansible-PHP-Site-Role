require_relative "lib/ansible_helper"
require_relative "bootstrap"

RSpec.configure do |config|
  config.before :suite do
    AnsibleHelper.playbook("playbooks/php7-playbook.yml", ENV["TARGET_HOST"], {
      copy_phpinfo: true,
      copy_index_php: true
    })

    set :env, :PHPENV_VERSION => "7.1.10"
  end
end

describe "Phpenv is installed and working" do
  include_examples "phpenv"
end

describe command("php --version") do
  it "has no errors" do
    expect(subject.exit_status).to eq 0
  end

  it "is the correct version" do
    expect(subject.stdout).to match /^PHP 7\.0\.6/
  end

  it "has OPcache enabled" do
    expect(subject.stdout).to match /^\s+with Zend OPcache v\d+\.\d+\.\d+/
  end
end

describe command(%Q{php -r 'echo "PHP is running\\n";'}) do
  it "executes PHP code" do
    expect(subject.stdout).to match /^PHP is running$/
  end
end

describe command("php -i") do
  it "has Imagick installed" do
    expect(subject.stdout).to match /^imagick module => enabled/
  end

  it "has XDebug installed" do
    expect(subject.stdout).to match /^xdebug support => enabled/
  end

  it "has YAML installed" do
    expect(subject.stdout).to match /^LibYAML Support => enabled/
  end
end

describe command("phpunit --version") do
  it "is installed" do
    expect(subject.stdout).to match /^PHPUnit 5\.3\.\d+/
  end
end

describe command("phpunit /srv/http/phpenv-test.dev/public/phpinfo.php") do
  it "has XDebug enabled" do
    expect(subject.stdout).to match /^xdebug support => enabled/
  end
end

describe command("psysh --version") do
  it "is installed" do
    expect(subject.stdout).to match /Psy Shell v0\.7\.\d+/
  end
end

describe command("curl -i phpenv-test.dev") do
  it "sends a 200 OK response" do
    expect(subject.stdout).to match /^HTTP\/1\.1 200 OK$/
  end

  it "executes PHP code" do
    expect(subject.stdout).to match /Nginx is serving PHP 7\.0\.6 code on phpenv-test\.dev/
  end
end

describe command("curl phpenv-test.dev/phpinfo.php") do
  it "has XDebug enabled" do
    expect(subject.stdout).to match /<th>xdebug support<\/th><th>enabled<\/th>/
  end
end

describe command("curl phpenv-test.dev/session_test.php") do
  it "can start a session" do
    expect(subject.stdout).to match /^2$/ # 2 == PHP_SESSION_ACTIVE
  end
end

describe "Nginx config is valid" do
  include_examples "nginx::config"
end
