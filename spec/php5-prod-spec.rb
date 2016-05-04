require_relative "lib/ansible_helper"
require_relative "bootstrap"

RSpec.configure do |config|
  config.before :suite do
    AnsibleHelper.instance.playbook("playbooks/php5-playbook.yml", {
      env_name: "prod",
      copy_phpinfo: true,
      copy_index_php: true
    })

    set :env, :PHPENV_VERSION => "5.6.21"
  end
end

describe "Phpenv is installed and working" do
  include_examples "phpenv"
end

describe command("php --version") do
  it "has no errors" do
    expect(subject.stderr).to eq ''
    expect(subject.exit_status).to eq 0
  end

  it "is the correct version" do
    expect(subject.stdout).to match /^PHP 5\.6\.21/
  end
end

describe command(%Q{php -r 'echo "PHP is running\\n";'}) do
  it "executes PHP code" do
    expect(subject.stdout).to match /^PHP is running$/
  end
end

describe command("php -i") do
  it "does not have XDebug installed" do
    expect(subject.stdout).to_not match /^xdebug support/
  end

  it "has the environment name set" do
    expect(subject.stdout).to match /_SERVER\["ENV_NAME"\] => prod/
  end
end

describe command("phpunit --version") do
  it "is not installed" do
    expect(subject.stderr).to match /phpunit: command not found/

    expect(subject.exit_status).to_not eq 0
  end
end

describe command("psysh --version") do
  it "is not installed" do
    expect(subject.stderr).to match /psysh: command not found/

    expect(subject.exit_status).to_not eq 0
  end
end

describe command("curl -i phpenv-test.dev") do
  it "sends a 200 OK response" do
    expect(subject.stdout).to match /^HTTP\/1\.1 200 OK$/
  end

  it "executes PHP code" do
    expect(subject.stdout).to match /Nginx is serving PHP 5\.6\.21 code on phpenv-test\.dev/
  end
end

describe command("curl phpenv-test.dev/phpinfo.php") do
  it "does not have XDebug enabled" do
    expect(subject.stdout).to_not match /xdebug support/
  end

  it "has the environment name set" do
    expect(subject.stdout).to match /_SERVER\["ENV_NAME"\]<\/td><td.+>prod/
  end
end

describe "Nginx config is valid" do
  include_examples "nginx::config"
end
