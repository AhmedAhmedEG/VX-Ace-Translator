require_relative 'Modules/RVData2Decompiler'
require_relative 'Modules/RVData2Compiler'
require_relative 'Modules/Utils'
require_relative 'Modules/RPG'
require 'optparse'
require 'zlib'

$stdout.sync = true

USAGE = "#{RED_COLOR}Decompiler Usage: RPGMakerVXAceTranslator.rb -d GAME_DIR -o OUTPUT_DIR [Optional]
Compiler Usage: RPGMakerVXAceTranslator.rb -c GAME_DIR -i INPUT_DIR [Optional] -o OUTPUT_DIR [Optional]#{RESET_COLOR}"

options = {}
options[:target_basename] = ''
options[:input] = ''
options[:output] = ''

while (arg = ARGV.shift)

  case arg
  when '-d', '--decompile'
    options[:decompile] = ARGV.shift
  when '-c', '--compile'
    options[:compile] = ARGV.shift
  when '-t', '--target'
    options[:target_basename] = ARGV.shift
  when '-i', '--input'
    options[:input] = ARGV.shift
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

Dir.chdir(File.dirname(__FILE__))

if not options[:decompile].nil?
  d = RVData2Decompiler.new
  d.decompile(options[:decompile], output_path=options[:output], target_basename=options[:target_basename])


elsif not options[:compile].nil?
  c = RVData2Compiler.new
  c.compile(options[:compile], input_path=options[:input], output_path=options[:output], target_basename=options[:target_basename])


end