require 'open3'
require 'set'
require 'fileutils'

def main
  STDERR.puts("Loading list of installed packages…")
  installed = File.read("installed-packages.txt").split

  STDERR.puts("Installing tools")
  unless(system("yum", "install", "-y", "yum-utils"))
    STDERR.puts("Could not install yum-utils, exit code #{$?}")
    exit 1
  end

  STDERR.puts("Moving to Build Directory")
  Dir.chdir("/tmp/inputs")

  if(File.exist?('system-packages.txt'))
    STDERR.puts("Installing System Packages")
    build_deps = File.read("system-packages.txt").split
    unless(system("yum", "install", "-y", *(build_deps)))
      STDERR.puts("Could not install build dependency pacakges")
      exit 2
    end
  end

  STDERR.puts("Building Gems")
  FileUtils.mkdir_p("/tmp/build/bundle")
  unless(system("bundle","install","--deployment","--path=/tmp/build/bundle"))
    STDERR.puts("Couldn't build gems")
    exit 3
  end

  STDERR.puts("Locating dynamic library depdendencies")
  libs = Set.new
  repoquery_cache = Hash.new() do |h,k|  # Reduce calls to repoquery
    pkgs_str, status = Open3.capture2("repoquery","-f", k)    
    h[k] = pkgs_str
  end

  Dir['/tmp/build/**/*.so*'].each do |lib|
    STDERR.write("Checking deps on #{lib}…")
    deps_str, status = Open3.capture2("ldd",lib)
    unless(status.exitstatus == 0)
      STDERR.puts("Couldn't run ldd! Status code: #{status}, ignoring…")
      #exit 3
    end
    deps = deps_str.split("\n").collect { |d_str| d_str[/(?<==>\s)(\/\S+)/] }.compact
    if(deps.length > 0)
      deps.each do |dep|
        STDERR.write('d')
        pkgs = repoquery_cache[dep].split("\n")
        if(pkgs.length > 0) 
          # See if it's already on the system
          unless((installed & pkgs).first)
            libs << dep
            STDERR.write("!")
          end
        end
      end
    end
    STDERR.write("\n")
  end

  STDERR.puts("The following libs need to be copied into /opt/lib: #{libs.to_a.join(',')}")
  FileUtils.mkdir_p('/tmp/outputs/lib')
  FileUtils.cp(libs.to_a, '/tmp/outputs/lib')

  STDERR.puts("Moving Bundle into place")
  FileUtils.cp_r("/tmp/build/bundle", "/tmp/outputs")
  #This directory is not needed at runtime
  #STDERR.puts("Removing extra files")
  #FileUtils.rm_rf("/tmp/outputs/bundle/ruby/2.5.0/cache")

  STDERR.puts("All Done!")
end

main
true