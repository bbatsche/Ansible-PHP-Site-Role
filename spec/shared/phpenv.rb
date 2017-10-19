require "serverspec"

shared_examples "php is installed" do
  describe "php" do
    let(:subject) { command("php --version") }

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

shared_examples "phpenv is installed" do
  describe "phpenv" do
    let(:subject) { command("phpenv help") }

    it "is installed" do
      expect(subject.stdout).to match /PHP multi-version installation and management utility/
    end

    include_examples "no errors"
  end
end

shared_examples "phpinfo" do |key, value|
  it "#{key} is #{value}" do
    expect(php_info).to match /^#{Regexp.quote(key)} => #{Regexp.quote(value)}/
  end
end

shared_examples "default phpinfo config" do
  include_examples("phpinfo", "PDO Driver for PostgreSQL", "enabled")
  include_examples("phpinfo", "BZip2 Support", "Enabled")
  include_examples("phpinfo", "gmp support", "enabled")
  include_examples("phpinfo", "iconv support", "enabled")
  include_examples("phpinfo", "Internationalization support", "enabled")
  include_examples("phpinfo", "PSpell Support", "enabled")
  include_examples("phpinfo", "error_log", "/usr/local/phpenv/versions/#{@php_version}/var/log/error.log") unless @php_version.nil?
end

shared_examples "supports sessions" do |url|
  describe "session_test.php" do
    let(:subject) { command("curl -i #{url}/session_test.php") }

    include_examples("curl request", "200")

    include_examples("curl request html")

    it 'has an active session' do
      expect(subject.stdout).to match /^2$/ # 2 == PHP_SESSION_ACTIVE
    end
  end
end

shared_examples "logs errors" do |url|
  describe "error_test.php" do
    let(:subject) { command("curl -i #{url}/error_test.php") }

    include_examples("curl request", "200")
  end

  describe "logged an error" do
    let(:subject) { command("tail -n 1 /usr/local/phpenv/versions/#{@php_version}/var/log/error.log") }

    it "logged an error" do
      expect(subject.stdout).to match /Test error message$/
    end
  end
end

shared_examples "sets open basedir" do |url, path=''|
  describe "open_basedir_test.php" do
    let(:subject) { command("curl -i #{url}/open_basedir_test.php?path=#{path}") }

    include_examples("curl request html")

    it "has open_basedir enabled" do
      expect(subject.stdout).to match /open_basedir restriction in effect\. File\(.+\) is not within the allowed path\(s\)/
    end
  end
end
