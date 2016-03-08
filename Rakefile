require "rake/extensiontask"
require "rubygems/package_task"

Rake::ExtensionTask.new "dtext" do |ext|
	ext.lib_dir = "lib/dtext"
end

s = Gem::Specification.new "dtext", "1.0" do |s|
	s.summary = "dtext parser"
	s.authors = ["r888888888@gmail.com"]
	s.extensions = %w(ext/dtext/extconf.rb)
	s.files = %w(
		RAkefile
		ext/dtext/extconf.rb
		ext/dtext/dtext.c
		lib/dtext.rb
	)
end

Gem::PackageTask.new(s) do
end

task :ragel do
	sh "ragel -C ext/dtext/dtext.rl -o ext/dtext/dtext.c"
end

task test: %w(ragel compile) do
	ruby '-Ilib', '-rdtext', '-e', "puts DTextRagel.parse(File.read('test/wiki.txt'))"
	#ruby '-Ilib', '-rdtext', '-e', 'puts DTextRagel.parse("pixiv account: http://www.pixiv.net/member.php?id=2631072\nh6. NO-POST ARTIST: DELETION REQUEST/CEASE AND DESIST RECEIVED")'
end

task default: :test