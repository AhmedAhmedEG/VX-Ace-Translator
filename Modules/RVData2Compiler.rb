require 'fileutils'
require_relative 'RPG'

class RVData2Compiler

  def initialize
    @input_path = ''
    @rvdata2_data = []
    @indentation = ' ' * 2
  end

  attr_accessor :input_path
  attr_accessor :rvdata2_data
  attr_accessor :indentation

  def compile(game_path, input_path='', output_path='', target_basename='', indexless=true)
    game_data_path = join(game_path, 'Data')

    decrypt_game(game_path)
    if input_path.empty?
      @input_path = "Decompiled"
    else
      @input_path = input_path
    end

    if output_path.empty?
      output_path = game_data_path
    else
      FileUtils.mkdir_p(output_path) unless Dir.exist?(output_path)
    end

    Dir.foreach(game_data_path) do |filename|
      next if %w[. ..].include?(filename) || File.directory?(join(game_data_path, filename))

      file_basename = File.basename(filename, '.*')
      next unless SUPPORTED_FORMATS.any? { |s| file_basename.include?(s) }

      unless target_basename.empty?
        next unless file_basename.include?(target_basename)
      end

      puts "#{GREEN_COLOR}Compiling #{filename}...#{GREEN_COLOR}"

      File.open(join(game_data_path, filename), "rb") do |rvdata2_file|
        @rvdata2_data = Marshal.load(rvdata2_file.read)
      end

      case file_basename

      when 'Actors'
        self.compile_actors

      when 'Classes'
        self.compile_classes

      when 'CommonEvents'

        if indexless
          self.compile_common_events_indexless

        else
          self.compile_common_events

        end

      when 'Enemies'
        self.compile_enemies

      when 'Items'
        self.compile_items

      when 'MapInfos'
        self.compile_map_infos

      when 'Scripts'
        self.compile_scripts

      when 'Skills'
        self.compile_skills

      when 'States'
        self.compile_states

      when 'System'
        self.compile_system

      when 'Troops'

        if indexless
          self.compile_troops_indexless

        else
          self.compile_troops

        end

      when 'Weapons'
        self.compile_weapons

      when 'Armors'
        self.compile_armors

      else

        if file_basename.match(/\AMap\d+\z/)

          if indexless
            self.compile_map_indexless(file_basename)

          else
            self.compile_map(file_basename)

          end

        end

      end

      File.open(join(output_path, filename), "wb") do |rvdata2_file|
        rvdata2_file.write(Marshal.dump(@rvdata2_data))
      end

      # print "#{GREEN_COLOR}Compiled #{filename}#{RESET_COLOR}\n"
      # $stdout.flush
    end

  end

  def compile_actors

    File.open(join(@input_path, 'Actors.txt'), 'r:UTF-8') do |actors_file|
      ind = 0

      actors_file.each_line do |line|

        case line
        when /^Actor (\d+)/
          ind = $1.to_i

        when /^Nickname = (".*")/
          @rvdata2_data[ind].nickname = eval($1.to_s)

        when /^Character Name = (".*")/
          @rvdata2_data[ind].character_name = eval($1.to_s)

        when /^Face Name = (".*")/
          @rvdata2_data[ind].face_name = eval($1.to_s)

        when /^Name = (".*")/
          @rvdata2_data[ind].name = eval($1.to_s)

        when /^Description = (".*")/
          @rvdata2_data[ind].description = eval($1.to_s)

        when /^Note = (".*")/
          @rvdata2_data[ind].note = eval($1.to_s)

        else
          next

        end

      end

    end

  end

  def compile_classes

    File.open(join(@input_path, 'Classes.txt'), 'r:UTF-8') do |classes_file|
      ind = 0

      classes_file.each_line do |line|

        case line
        when /^Class (\d+)/
          ind = $1.to_i

        when /^Name = (".*")/
          @rvdata2_data[ind].name = eval($1.to_s)

        when /^Description = (".*")/
          @rvdata2_data[ind].description = eval($1.to_s)

        when /^Note = (".*")/
          @rvdata2_data[ind].note = eval($1.to_s)

        else
          next

        end

      end

    end

  end

  def compile_common_events
    event_ind = 0

    Dir.foreach(join(@input_path, 'CommonEvents')) do |common_event_filename|
      next if %w[. ..].include?(common_event_filename)

      File.open(join(@input_path, 'CommonEvents', common_event_filename), 'r:UTF-8') do |common_event_file|
        added_event_commands = {}

        common_event_file.each_line do |line|

          case line
          when /^CommonEvent (\d+)/
            event_ind = $1.to_i

          when /^Name = (".*")/
            @rvdata2_data[event_ind].name = eval($1.to_s)

          when /(\s*)(\d+)-(\D+?)\((.*)\)\+$/

            if $1.to_s.length % @indentation.length != 0 || $1.to_s.length < @indentation.length
              STDERR.puts "Error at CommonEvent #{event_ind}, Command #{$2} has incorrect indentation."
              break

            end

            indent = $1.to_s.length / @indentation.length
            parameters = eval($4.to_s)

            deserialize_parameters(parameters)

            event_command = RPG::EventCommand.new(code=TARGETED_EVENT_COMMANDS.key($3), indent=indent - 1, parameters=parameters)
            added_event_commands[$2.to_i] = event_command

          when /(\d+)-(\D+?)\((.*)\)/
            parameters = eval($3.to_s)
            deserialize_parameters(parameters)

            if $1.to_i >= @rvdata2_data[event_ind].list.length
              STDERR.puts "Command #{$1} is out of range at CommonEvent #{event_ind}."
              break
            end

            begin
              @rvdata2_data[event_ind].list[$1.to_i].code = TARGETED_EVENT_COMMANDS.key($2)
            rescue NoMethodError => e
              STDERR.puts "Unknown Command at CommonEvent #{event_ind}, Command #{$1}, #{$2}."
              STDERR.puts e
              break
            end

            if $2 == 'ShowText' && parameters[0].empty?
              @rvdata2_data[event_ind].list[$1.to_i].code = TARGETED_EVENT_COMMANDS.key('Empty')
              parameters.clear
            end

            @rvdata2_data[event_ind].list[$1.to_i].parameters = parameters

          else
            next

          end

        end

        added_event_commands.keys.sort.reverse.each do |ind|
          @rvdata2_data[event_ind].list.insert(ind, added_event_commands[ind])
        end

      end

    end

  end

  def compile_common_events_indexless
    event_ind = 0

    Dir.foreach(join(@input_path, 'CommonEvents')) do |common_event_filename|
      next if %w[. ..].include?(common_event_filename)

      File.open(join(@input_path, 'CommonEvents', common_event_filename), 'r:UTF-8') do |common_event_file|

        common_event_file.each_line do |line|

          case line
          when /^CommonEvent (\d+)/
            event_ind = $1.to_i
            @rvdata2_data[event_ind].list.clear

          when /^Name = (".*")/
            @rvdata2_data[event_ind].name = eval($1.to_s)

          when /(\s+)(\D+?)\((\[.*\])\)/

            if $1.to_s.length % @indentation.length != 0 || $1.to_s.length < @indentation.length
              STDERR.puts "Error at CommonEvent #{event_ind}, Command #{$2} has incorrect indentation."
              break

            end

            code = TARGETED_EVENT_COMMANDS.key($2)
            indent = $1.to_s.length / @indentation.length
            parameters = eval($3.to_s)

            if $2 == 'ShowText' && parameters[0].empty?
              code = TARGETED_EVENT_COMMANDS.key('Empty')
              parameters.clear
            end

            deserialize_parameters(parameters)

            event_command = RPG::EventCommand.new(code=code, indent=indent - 1, parameters=parameters)
            @rvdata2_data[event_ind].list.append(event_command)

          else
            next

          end

        end

      end

    end

  end

  def compile_enemies

    File.open(join(@input_path, 'Enemies.txt'), 'r:UTF-8') do |enemies_file|
      ind = 0

      enemies_file.each_line do |line|

        case line
        when /^Enemy (\d+)/
          ind = $1.to_i

        when /^Battler Name = (".*")/
          @rvdata2_data[ind].battler_name = eval($1.to_s)

        when /^Name = (".*")/
          @rvdata2_data[ind].name = eval($1.to_s)

        when /^Description = (".*")/
          @rvdata2_data[ind].description = eval($1.to_s)

        when /^Note = (".*")/
          @rvdata2_data[ind].note = eval($1.to_s)

        else
          next

        end

      end

    end

  end

  def compile_items

    File.open(join(@input_path, 'Items.txt'), 'r:UTF-8') do |items_file|
      ind = 0

      items_file.each_line do |line|

        case line
        when /^Item (\d+)/
          ind = $1.to_i

        when /^Name = (".*")/
          @rvdata2_data[ind].name = eval($1.to_s)

        when /^Description = (".*")/
          @rvdata2_data[ind].description = eval($1.to_s)

        when /^Note = (".*")/
          @rvdata2_data[ind].note = eval($1.to_s)

        else
          next

        end

      end

    end

  end

  def compile_weapons

    File.open(join(@input_path, 'Weapons.txt'), 'r:UTF-8') do |weapons_file|
      ind = 0

      weapons_file.each_line do |line|

        case line
        when /^Weapon (\d+)/
          ind = $1.to_i

        when /^Name = (".*")/
          @rvdata2_data[ind].name = eval($1.to_s)

        when /^Description = (".*")/
          @rvdata2_data[ind].description = eval($1.to_s)

        when /^Note = (".*")/
          @rvdata2_data[ind].note = eval($1.to_s)

        else
          next

        end

      end

    end

  end

  def compile_armors

    File.open(join(@input_path, 'Armors.txt'), 'r:UTF-8') do |armors_file|
      ind = 0

      armors_file.each_line do |line|

        case line
        when /^Armor (\d+)/
          ind = $1.to_i

        when /^Name = (".*")/
          @rvdata2_data[ind].name = eval($1.to_s)

        when /^Description = (".*")/
          @rvdata2_data[ind].description = eval($1.to_s)

        when /^Note = (".*")/
          @rvdata2_data[ind].note = eval($1.to_s)

        else
          next

        end

      end

    end

  end

  def compile_map(file_basename)
    event_ind = 0
    page_ind = 0

    File.open(join(@input_path, 'Maps', "#{file_basename}.txt"), 'r:UTF-8') do |map_file|
      added_event_commands = {}

      map_file.each_line do |line|

        case line
        when /^Display Name = (".*")/
          @rvdata2_data.display_name = eval($1.to_s)

        when /^Parallax Name = (".*")/
          @rvdata2_data.parallax_name = eval($1.to_s)

        when /^Note = (".*")/
          @rvdata2_data.note = eval($1.to_s)

        when /^CommonEvent (\d+)/
          event_ind = $1.to_i

        when /^\s+Page (\d+)/
          page_ind = $1.to_i

        when /(\s*)(\d+)-(\D+?)\((.*)\)\+$/

          if $1.to_s.length % @indentation.length != 0 || $1.to_s.length < @indentation.length
            STDERR.puts "Error at CommonEvent #{event_ind}, Page #{page_ind}, Command #{$2} has incorrect indentation."
            break

          end

          indent = $1.to_s.length / @indentation.length
          parameters = eval($4.to_s)

          deserialize_parameters(parameters)

          event_command = RPG::EventCommand.new(code=TARGETED_EVENT_COMMANDS.key($3), indent=indent - 2, parameters=parameters)
          added_event_commands[event_ind] = {page_ind => {$2.to_i => event_command}}

        when /(\d+)-(\D+?)\((.*)\)/
          parameters = eval($3.to_s)
          deserialize_parameters(parameters)

          if page_ind >= @rvdata2_data.events[event_ind].pages.length
            STDERR.puts "Page #{page_ind} is out of range at CommonEvent #{event_ind}."
            break
          end

          if $1.to_i >= @rvdata2_data.events[event_ind].pages[page_ind].list.length
            STDERR.puts "Command #{$1} is out of range at CommonEvent #{event_ind}."
            break
          end

          begin
            @rvdata2_data.events[event_ind].pages[page_ind].list[$1.to_i].code = TARGETED_EVENT_COMMANDS.key($2)
          rescue NoMethodError => e
            STDERR.puts "Unknown Command at CommonEvent #{event_ind}, Page #{page_ind}, #{$1}, #{$2}"
            STDERR.puts e
            break
          end

          if $2 == 'ShowText' && parameters[0].empty?
            @rvdata2_data.events[event_ind].pages[page_ind].list[$1.to_i].code = TARGETED_EVENT_COMMANDS.key('Empty')
            parameters.clear
          end

          @rvdata2_data.events[event_ind].pages[page_ind].list[$1.to_i].parameters = parameters
        else
          next

        end

      end

      added_event_commands.keys.each do |event_ind|

        added_event_commands[event_ind].keys.each do |page_ind|

          added_event_commands[event_ind][page_ind].keys.sort.reverse.each do |i|
            @rvdata2_data.events[event_ind].pages[page_ind].list.insert(i, added_event_commands[event_ind][page_ind][i])
          end

        end

      end

    end

  end

  def compile_map_indexless(file_basename)
    event_ind = 0
    page_ind = 0

    File.open(join(@input_path, 'Maps', "#{file_basename}.txt"), 'r:UTF-8') do |map_file|

      map_file.each_line do |line|

        case line
        when /^Display Name = (".*")/
          @rvdata2_data.display_name = eval($1.to_s)

        when /^Parallax Name = (".*")/
          @rvdata2_data.parallax_name = eval($1.to_s)

        when /^Note = (".*")/
          @rvdata2_data.note = eval($1.to_s)

        when /^CommonEvent (\d+)/
          event_ind = $1.to_i

        when /^\s+Page (\d+)/
          page_ind = $1.to_i
          @rvdata2_data.events[event_ind].pages[page_ind].list.clear

        when /(\s+)(\D+?)\((\[.*\])\)/

          if $1.to_s.length % @indentation.length != 0 || $1.to_s.length < @indentation.length
            STDERR.puts "Error at CommonEvent #{event_ind}, Page #{page_ind}, Command #{$1} has incorrect indentation."
            break

          end

          code = TARGETED_EVENT_COMMANDS.key($2)
          indent = $1.to_s.length / @indentation.length
          parameters = eval($3.to_s)

          if $2 == 'ShowText' && parameters[0].empty?
            code = TARGETED_EVENT_COMMANDS.key('Empty')
            parameters.clear
          end

          deserialize_parameters(parameters)

          event_command = RPG::EventCommand.new(code=code, indent=indent - 2, parameters=parameters)
          @rvdata2_data.events[event_ind].pages[page_ind].list.append(event_command)

        else
          next

        end

      end

    end

  end

  def compile_map_infos

    File.open(join(@input_path, 'MapInfos.txt'), 'r:UTF-8') do |map_infos_file|
      id = 0

      map_infos_file.each_line do |line|

        case line
        when /^MapInfo (\d+)/
          id = $1.to_i

        when /^Name = (".*")/
          @rvdata2_data[id].name = eval($1.to_s)

        else
          next

        end

      end

    end

  end

  def compile_scripts

    @rvdata2_data.each_with_index  do |script, i|
      script_path =  join(@input_path, 'Scripts', "#{i} - #{File.basename(script[1])}.rb")

      File.open(script_path, 'rb') do |script_file|
        script << Zlib::Deflate.deflate(script_file.read)
      end

    end

  end

  def compile_skills

    File.open(join(@input_path, 'Skills.txt'), 'r:UTF-8') do |skills_file|
      ind = 0

      skills_file.each_line do |line|

        case line
        when /^Skill (\d+)/
          ind = $1.to_i

        when /^Message 1 = (".*")/
          @rvdata2_data[ind].message1 = eval($1.to_s)

        when /^Message 2 = (".*")/
          @rvdata2_data[ind].message2 = eval($1.to_s)

        when /^Name = (".*")/
          @rvdata2_data[ind].name = eval($1.to_s)

        when /^Description = (".*")/
          @rvdata2_data[ind].description = eval($1.to_s)

        when /^Note = (".*")/
          @rvdata2_data[ind].note = eval($1.to_s)

        else
          next

        end

      end

    end

  end

  def compile_states

    File.open(join(@input_path, 'States.txt'), 'r:UTF-8') do |states_file|
      ind = 0

      states_file.each_line do |line|

        case line
        when /^State (\d+)/
          ind = $1.to_i

        when /^Message 1 = (".*")/
          @rvdata2_data[ind].message1 = eval($1.to_s)

        when /^Message 2 = (".*")/
          @rvdata2_data[ind].message2 = eval($1.to_s)

        when /^Message 3 = (".*")/
          @rvdata2_data[ind].message3 = eval($1.to_s)

        when /^Message 4 = (".*")/
          @rvdata2_data[ind].message4 = eval($1.to_s)

        when /^Name = (".*")/
          @rvdata2_data[ind].name = eval($1.to_s)

        when /^Description = (".*")/
          @rvdata2_data[ind].description = eval($1.to_s)

        when /^Note = (".*")/
          @rvdata2_data[ind].note = eval($1.to_s)

        else
          next

        end

      end

    end

  end

  def compile_system

    File.open(join(@input_path, 'System.txt'), 'r:UTF-8') do |system_file|

      system_file.each_line do |line|

        case line
        when /^Game Title = (".*")/
          @rvdata2_data.game_title = eval($1.to_s)

        when /^Currency Unit = (".*")/
          @rvdata2_data.currency_unit = eval($1.to_s)

        when /^Title 1 Name = (".*")/
          @rvdata2_data.title1_name = eval($1.to_s)

        when /^Title 2 Name = (".*")/
          @rvdata2_data.title2_name = eval($1.to_s)

        when /^Battleback 1 Name = (".*")/
          @rvdata2_data.battleback1_name = eval($1.to_s)

        when /^Battleback 2 Name = (".*")/
          @rvdata2_data.battleback2_name = eval($1.to_s)

        when /^Battler Name = (".*")/
          @rvdata2_data.battler_name = eval($1.to_s)

        else
          next

        end

      end

    end

    File.open(join(@input_path, 'System', 'Elements.txt'), 'r:UTF-8') do |elements_file|
      offset = @rvdata2_data.elements[0].nil? ? 1 : 0

      elements_file.each_line.with_index do |line, i|
        @rvdata2_data.elements[i + offset] = eval(line.strip)
      end

    end

    File.open(join(@input_path, 'System', 'Skill Types.txt'), 'r:UTF-8') do |skill_types_file|
      offset = @rvdata2_data.skill_types[0].nil? ? 1 : 0

      skill_types_file.each_line.with_index do |line, i|
        @rvdata2_data.skill_types[i + offset] = eval(line.strip)
      end

    end

    File.open(join(@input_path, 'System', 'Weapon Types.txt'), 'r:UTF-8') do |weapon_types_file|
      offset = @rvdata2_data.weapon_types[0].nil? ? 1 : 0

      weapon_types_file.each_line.with_index do |line, i|
        @rvdata2_data.weapon_types[i + offset] = eval(line.strip)
      end

    end

    File.open(join(@input_path, 'System', 'Armor Types.txt'), 'r:UTF-8') do |armor_types_file|
      offset = @rvdata2_data.armor_types[0].nil? ? 1 : 0

      armor_types_file.each_line.with_index do |line, i|
        @rvdata2_data.armor_types[i + offset] = eval(line.strip)
      end

    end

    File.open(join(@input_path, 'System', 'Switches.txt'), 'r:UTF-8') do |switches_file|
      offset = @rvdata2_data.switches[0].nil? ? 1 : 0

      switches_file.each_line.with_index do |line, i|
        @rvdata2_data.switches[i + offset] = eval(line.strip)
      end

    end

    File.open(join(@input_path, 'System', 'Variables.txt'), 'r:UTF-8') do |variables_file|
      offset = @rvdata2_data.variables[0].nil? ? 1 : 0

      variables_file.each_line.with_index do |line, i|
        @rvdata2_data.variables[i + offset] = eval(line.strip)
      end

    end

    File.open(join(@input_path, 'System', 'Terms.txt'), 'r:UTF-8') do |terms_file|
      values = []

      terms_file.each_line do |line|
        next unless line.include?('=')
        values << eval(line.strip.split(' = ')[1])
      end

      @rvdata2_data.terms.basic = values[0..7]
      @rvdata2_data.terms.params = values[8..15]
      @rvdata2_data.terms.etypes = values[16..20]
      @rvdata2_data.terms.commands = values[21..43]

    end

  end

  def compile_troops
    troop_ind = 0
    page_ind = 0

    File.open(join(@input_path, 'Troops.txt'), 'r:UTF-8') do |troops_file|
      added_event_commands = {}

      troops_file.each_line do |line|

        case line
        when /^Troop (\d+)/
          troop_ind = $1.to_i

        when /^Name = (".*")/
          @rvdata2_data[troop_ind].name = eval($1.to_s)

        when /^Page (\d+)/
          page_ind = $1.to_i

        when /(\s*)(\d+)-(\D+?)\((.*)\)\+$/

          if $1.to_s.length % @indentation.length != 0 || $1.to_s.length < @indentation.length
            STDERR.puts "Error at Troop #{troop_ind}, Page #{page_ind}, Command #{$2} has incorrect indentation."
            break

          end

          indent = $1.to_s.length / @indentation.length
          parameters = eval($4.to_s)

          deserialize_parameters(parameters)

          event_command = RPG::EventCommand.new(code=TARGETED_EVENT_COMMANDS.key($3), indent=indent - 1, parameters=parameters)
          added_event_commands[troop_ind] = {page_ind => {$2.to_i => event_command}}

        when /(\d+)-(\D+?)\((.*)\)/
          parameters = eval($3.to_s)
          deserialize_parameters(parameters)

          if page_ind >= @rvdata2_data[troop_ind].pages.length
            STDERR.puts "Page #{page_ind} is out of range at Troop #{troop_ind}."
            break
          end

          if $1.to_i >= @rvdata2_data[troop_ind].pages[page_ind].list.length
            STDERR.puts "Command #{$1} is out of range at Troop #{troop_ind}."
            break
          end

          begin
            @rvdata2_data[troop_ind].pages[page_ind].list[$1.to_i].code = TARGETED_EVENT_COMMANDS.key($2)
          rescue NoMethodError => e
            STDERR.puts "Unknown Command at Troop #{troop_ind}, Page #{page_ind}, #{$1}, #{$2}"
            STDERR.puts e
            break
          end

          if $2 == 'ShowText' && parameters[0].empty?
            @rvdata2_data[troop_ind].pages[page_ind].list[$1.to_i].code = TARGETED_EVENT_COMMANDS.key('Empty')
            parameters.clear
          end

          @rvdata2_data[troop_ind].pages[page_ind].list[$1.to_i].parameters = parameters
        else
          next

        end

      end

      added_event_commands.keys.each do |troop_ind|

        added_event_commands[troop_ind].keys.each do |page_ind|

          added_event_commands[troop_ind][page_ind].keys.sort.reverse.each do |i|
            @rvdata2_data[troop_ind].pages[page_ind].list.insert(i, added_event_commands[troop_ind][page_ind][i])
          end

        end

      end

    end

  end

  def compile_troops_indexless
    troop_ind = 0
    page_ind = 0

    File.open(join(@input_path, 'Troops.txt'), 'r:UTF-8') do |troops_file|

      troops_file.each_line do |line|

        case line
        when /^Troop (\d+)/
          troop_ind = $1.to_i

        when /^Name = (".*")/
          @rvdata2_data[troop_ind].name = eval($1.to_s)

        when /^Page (\d+)/
          page_ind = $1.to_i
          @rvdata2_data[troop_ind].pages[page_ind].list.clear

        when /(\s+)(\D+?)\((\[.*\])\)/

          if $1.to_s.length % @indentation.length != 0 || $1.to_s.length < @indentation.length
            STDERR.puts "Error at Troop #{troop_ind}, Page #{page_ind}, Command #{$1} has incorrect indentation."
            break

          end

          code = TARGETED_EVENT_COMMANDS.key($2)
          indent = $1.to_s.length / @indentation.length
          parameters = eval($3.to_s)

          if $2 == 'ShowText' && parameters[0].empty?
            code = TARGETED_EVENT_COMMANDS.key('Empty')
            parameters.clear
          end

          deserialize_parameters(parameters)

          event_command = RPG::EventCommand.new(code=code, indent=indent - 1, parameters=parameters)
          @rvdata2_data[troop_ind].pages[page_ind].list.append(event_command)

        else
          next

        end

      end

    end

  end

end