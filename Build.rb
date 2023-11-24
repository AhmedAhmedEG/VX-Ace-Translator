require 'fileutils'

Dir.chdir(File.dirname(__FILE__))

FileUtils.rm_r('Build') if Dir.exist?('Build')
Dir.mkdir('Build')

FileUtils.cp_r('Resources', File.join('Build/Resources'))
system("Builder.bat")

