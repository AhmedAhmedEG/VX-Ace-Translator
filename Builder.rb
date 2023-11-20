require 'fileutils'

Dir.chdir(File.dirname(__FILE__))

Dir.mkdir('Build') unless Dir.exist?('Build')
FileUtils.cp_r('Resources', File.join('Build/Resources'))

system("Build.bat")

