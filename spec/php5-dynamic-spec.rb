require_relative "lib/ansible_helper"
require_relative "bootstrap"

RSpec.configure do |config|
  config.before :suite do
    AnsibleHelper.instance.playbook "playbooks/php5-playbook.yml", copy_index_php: true, dynamic_php: true

    set :env, :PHPENV_VERSION => "5.6.18"
  end
end

describe "Phpenv is installed and working" do
  include_examples "phpenv"
end

describe command("curl phpenv-test.dev/some-url") do
  it "redirects to index.php" do
    expect(subject.stdout).to match /Nginx is serving PHP 5\.6\.18 code on phpenv-test\.dev/
  end
end

describe "Nginx config is valid" do
  include_examples "nginx::config"
end
