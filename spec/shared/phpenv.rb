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
end

shared_examples "phpinfo html heading" do |key, value|
  it "#{key} is #{value}" do
    expect(php_info).to match %r|<th>\s*#{Regexp.quote(key)}\s*</th>\s*<th>\s*#{Regexp.quote(value)}\s*</th>|
  end
end

shared_examples "phpinfo html row" do |key, value, count=1|
  it "#{key} is #{value}" do
    expect(php_info).to match %r|<td class="e">\s*#{Regexp.quote(key)}\s*</td>\s*<td class="v">\s*#{Regexp.quote(value)}\s*</td>|
  end
end

shared_examples "supports sessions" do |url|
  describe "session_test.php" do
    let(:subject) { command("curl -i #{url}/session_test.php") }
    let(:cookie)  { subject.stdout.each_line.find { |line| line =~ /Set-Cookie: PHPSESSID=/}}

    include_examples("curl request", "200")
    include_examples("curl request html")

    it "uses httponly same site cookies" do
      expect(cookie).to match /HttpOnly/
      expect(cookie).to match /SameSite=Lax/
    end

    it "has an active session" do
      expect(subject.stdout).to match /^2$/ # 2 == PHP_SESSION_ACTIVE
    end
  end
end

shared_examples "logs errors" do |url|
  describe "error_test.php" do
    let(:subject) { command("curl -i #{url}/error_test.php") }

    include_examples("curl request", "200")
  end

  describe "Error Log" do
    let(:subject) { command("tail -n 1 /usr/local/phpenv/versions/#{@php_version}/var/log/error.log") }

    it "contains the previous error" do
      expect(subject.stdout).to match /Test error message$/
    end
  end
end

shared_examples "sets open basedir" do |url, path=''|
  describe "open_basedir_test.php" do
    let(:subject) { command("curl -i #{url}/open_basedir_test.php?path=#{path}") }

    include_examples("curl request html")
  end

  describe "Error Log" do
    let(:subject) { command("tail -n 8 /usr/local/phpenv/versions/#{@php_version}/var/log/error.log") }

    it "contains the previous error" do
      expect(subject.stdout).to match /open_basedir restriction in effect\. File\(.+\) is not within the allowed path\(s\)/
      expect(subject.stdout).to match /failed to open stream: Operation not permitted/
    end
  end
end
