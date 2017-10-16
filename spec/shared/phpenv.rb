require "serverspec"
require_relative "no_errors"

shared_examples "php" do
  describe command("php --version") do
    it "is the correct version" do
      expect(subject.stdout).to match /^PHP #{Regexp.quote(@php_version)}/
    end

    it "has OPcache enabled" do
      expect(subject.stdout).to match /^\s+with Zend OPcache v\d+\.\d+\.\d+/
    end

    include_examples "no errors"
  end

  describe command(%Q{php -r 'echo "PHP is running\\n";'}) do
    it "executes PHP code" do
      expect(subject.stdout).to match /^PHP is running$/
    end

    include_examples "no errors"
  end
end

shared_examples "phpenv" do
  describe command("phpenv help") do
    include_examples "no errors"
  end
end

shared_examples "phpinfo" do |key, value|
  it "#{key} is #{value}" do
    expect(subject.stdout).to match /^#{Regexp.quote(key)} => #{Regexp.quote(value)}/
  end
end
