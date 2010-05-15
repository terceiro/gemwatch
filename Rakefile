ENV['LC_ALL'] = 'POSIX'

desc "Deploys gemwatch on alioth.debian.org"
task :alioth do
  sh 'rsync -avtPC --exclude /.git --exclude /tmp --exclude /.bundle ./ alioth.debian.org:/var/lib/gforge/chroot/home/groups/pkg-ruby-extras/gemwatch/'
  sh 'ssh alioth.debian.org chmod -R a+rX /var/lib/gforge/chroot/home/groups/pkg-ruby-extras/gemwatch/'
end

task :default do
  system 'rake -T -s'
end
