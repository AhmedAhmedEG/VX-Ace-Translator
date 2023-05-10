require_relative 'Modules/RVData2Decompiler'
require_relative 'Modules/RVData2Compiler'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: RPGMakerVXAceTranslator.rb -d GAME_DIR|-c DECOMPILED_DIR -o OUTPUT"

  opts.on("-d", "--decompile=GAME_DIR", "Game folder path") do |d|
    options[:decompile] = d
  end

  opts.on("-c", "--compile=DECOMPILED_DIR", "Decompiled files path") do |c|
    options[:compile] = c
  end

  opts.on("-o", "--output=OUTPUT", "Output files path") do |o|
    options[:output] = o
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

  unless options[:decompile] || options[:compile]
    puts opts
    exit
  end

end.parse!

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