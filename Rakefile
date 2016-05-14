desc "Removes outdated compiled files"
task :clean do
  unless Dir['output/*'].empty?
    `bundle exec nanoc prune --yes`
  end
end

desc "Compile the site"
task :compile => [:clean] do
  puts "Compiling site"
  out = `bundle exec nanoc compile`

  if $?.to_i == 0
    puts  "Compilation succeeded"
  else
    abort "Compilation failed: #{$?.to_i}\n" +
          "#{out}\n"
  end
end

desc "Push compiled site to gh-pages"
task :publish => [:compile] do
  # Environment variables used for Travis-CI
  ENV['GIT_DIR'] = File.expand_path(`git rev-parse --git-dir`.chomp)

  # Check if remote branch exists or not
  if `git branch -r | grep gh-pages`.chomp.empty?
    old_sha = ""
  else
    old_sha = `git rev-parse refs/remotes/origin/gh-pages --`.chomp
  end

  Dir.chdir('output') do
    ENV['GIT_INDEX_FILE'] = gif = '/tmp/dev.gh.i'
    ENV['GIT_WORK_TREE'] = Dir.pwd
    File.unlink(gif) if File.file?(gif)
    `git add -A`
    tsha = `git write-tree`.strip
    puts "Created tree   #{tsha}"
    if old_sha.size == 40
      csha = `echo 'boom' | git commit-tree #{tsha} -p #{old_sha}`.strip
    else
      csha = `echo 'boom' | git commit-tree #{tsha}`.strip
    end
    puts "Created commit #{csha}"
    puts `git show #{csha} --stat`
    puts "Updating gh-pages from #{old_sha}"
    `git update-ref refs/heads/gh-pages #{csha}`
    `git push origin gh-pages`
  end
end

task :default => :compile
