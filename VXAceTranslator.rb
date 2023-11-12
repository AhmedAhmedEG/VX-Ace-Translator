require_relative 'Modules/RVData2Decompiler'
require_relative 'Modules/RVData2Compiler'
require_relative 'Modules/Utils'
require_relative 'Modules/RPG'
require 'optparse'
require 'zlib'

$stdout.sync = true

USAGE = "#{RED_COLOR}Usage: RPGMakerVXAceTranslator.rb -d GAME_DIR|-c DECOMPILED_DIR -o OUTPUT#{RESET_COLOR}"

options = {}
options[:target_basename] = ''

while (arg = ARGV.shift)

  case arg
  when '-d', '--decompile'
    options[:decompile] = ARGV.shift
  when '-c', '--compile'
    options[:compile] = ARGV.shift
  when '-t', '--target'
    options[:target_basename] = ARGV.shift
  when '-o', '--output'
    options[:output] = ARGV.shift
  when '-h', '--help'
    print USAGE
    $stdout.flush

    exit
  else
    print USAGE
    $stdout.flush

    exit
  end

end

unless options[:decompile] || options[:compile]
  puts USAGE
  exit
end


if not options[:decompile].nil?
  d = RVData2Decompiler.new

  if options[:output].nil?
    d.decompile(options[:decompile], target_basename=options[:target_basename])
  else
    d.decompile(options[:decompile], options[:output], target_basename=options[:target_basename])
  end

elsif not options[:compile].nil?
  c = RVData2Compiler.new

  if options[:output].nil?
    c.compile(options[:compile], target_basename=options[:target_basename])
  else
    c.compile(options[:compile], options[:output], target_basename=options[:target_basename])
  end

end