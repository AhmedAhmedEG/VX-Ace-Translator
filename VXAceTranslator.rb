require_relative 'Modules/RVData2Decompiler'
require_relative 'Modules/RVData2Compiler'
require_relative 'Modules/Utils'
require_relative 'Modules/RPG'
require 'optparse'
require 'zlib'

USAGE = "#{RED_COLOR}Usage: RPGMakerVXAceTranslator.rb -d GAME_DIR|-c DECOMPILED_DIR -o OUTPUT#{RESET_COLOR}"
options = {}

while (arg = ARGV.shift)

  case arg
  when '-d', '--decompile'
    options[:decompile] = ARGV.shift
  when '-c', '--compile'
    options[:compile] = ARGV.shift
  when '-o', '--output'
    options[:output] = ARGV.shift
  when '-h', '--help'
    puts USAGE
    exit
  else
    puts USAGE
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
    d.decompile(options[:decompile])
  else
    d.decompile(options[:decompile], options[:output])
  end

elsif not options[:compile].nil?
  c = RVData2Compiler.new

  if options[:output].nil?
    c.compile(options[:compile])
  else
    c.compile(options[:compile], options[:output])
  end

end