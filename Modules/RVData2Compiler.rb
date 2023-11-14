require 'fileutils'

class RVData2Compiler

  def initialize
    @input_path = ''
    @metadata = []
  end

  attr_accessor :input_path
  attr_accessor :metadata

  def compile(game_path, input_path='', output_path='', target_basename='')
    game_data_path = join(game_path, 'Data')

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

      print "#{RED_COLOR}Compiling #{filename}...\n#{RESET_COLOR}"
      $stdout.flush

      File.open(join(game_data_path, filename), "rb") do |rvdata2_file|
        @metadata = Marshal.load(rvdata2_file.read)
      end

      case file_basename

      when 'Actors'
        self.compile_actors

      when 'Classes'
        self.compile_classes

      when 'CommonEvents'
        self.compile_common_events

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
        self.compile_troops

      when 'Weapons'
        self.compile_weapons

      when 'Armors'
        self.compile_armors

      else

        if file_basename.match(/\AMap\d+\z/)
          self.compile_map(file_basename)
        end

      end

      File.open(join(output_path, filename), "wb") do |rvdata2_file|
        rvdata2_file.write(Marshal.dump(@metadata))
      end

      print "#{GREEN_COLOR}Compiled #{filename}\n#{RESET_COLOR}"
      $stdout.flush
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
          @metadata[ind].nickname = eval($1.to_s)
        when /^Character Name = (".*")/
          @metadata[ind].character_name = eval($1.to_s)
        when /^Face Name = (".*")/
          @metadata[ind].face_name = eval($1.to_s)
        when /^Name = (".*")/
          @metadata[ind].name = eval($1.to_s)
        when /^Description = (".*")/
          @metadata[ind].description = eval($1.to_s)
        when /^Note = (".*")/
          @metadata[ind].note = eval($1.to_s)
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
          @metadata[ind].name = eval($1.to_s)
        when /^Description = (".*")/
          @metadata[ind].description = eval($1.to_s)
        when /^Note = (".*")/
          @metadata[ind].note = eval($1.to_s)
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

        common_event_file.each_line do |line|

          case line
          when /^CommonEvent (\d+)/
            event_ind = $1.to_i

          when /^Name = (".*")/
            @metadata[event_ind].name = eval($1.to_s)

          when /(\d+)-(\D+?)\((.*)\)/
            parameters = eval($3.to_s)
            deserialize_parameters(parameters)

            @metadata[event_ind].list[$1.to_i].code = TARGETED_EVENT_COMMANDS.key($2)
            @metadata[event_ind].list[$1.to_i].parameters = parameters

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
          @metadata[ind].battler_name = eval($1.to_s)
        when /^Name = (".*")/
          @metadata[ind].name = eval($1.to_s)
        when /^Description = (".*")/
          @metadata[ind].description = eval($1.to_s)
        when /^Note = (".*")/
          @metadata[ind].note = eval($1.to_s)
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
          @metadata[ind].name = eval($1.to_s)
        when /^Description = (".*")/
          @metadata[ind].description = eval($1.to_s)
        when /^Note = (".*")/
          @metadata[ind].note = eval($1.to_s)
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
          @metadata[ind].name = eval($1.to_s)
        when /^Description = (".*")/
          @metadata[ind].description = eval($1.to_s)
        when /^Note = (".*")/
          @metadata[ind].note = eval($1.to_s)
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
          @metadata[ind].name = eval($1.to_s)
        when /^Description = (".*")/
          @metadata[ind].description = eval($1.to_s)
        when /^Note = (".*")/
          @metadata[ind].note = eval($1.to_s)
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

      map_file.each_line do |line|

        case line
        when /^Display Name = (".*")/
          @metadata.display_name = eval($1.to_s)
        when /^Parallax Name = (".*")/
          @metadata.parallax_name = eval($1.to_s)
        when /^Note = (".*")/
          @metadata.note = eval($1.to_s)
        when /^CommonEvent (\d+)/
          event_ind = $1.to_i
        when /Page (\d+)/
          page_ind = $1.to_i
        when /(\d+)-(\D+?)\((.*)\)/
          parameters = eval($3.to_s)
          deserialize_parameters(parameters)

          @metadata.events[event_ind].pages[page_ind].list[$1.to_i].code = TARGETED_EVENT_COMMANDS.key($2)
          @metadata.events[event_ind].pages[page_ind].list[$1.to_i].parameters = parameters
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
          @metadata[id].name = eval($1.to_s)
        else
          next
        end

      end

    end

  end

  def compile_scripts

    @metadata.each_with_index  do |script, i|
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
          @metadata[ind].message1 = eval($1.to_s)
        when /^Message 2 = (".*")/
          @metadata[ind].message2 = eval($1.to_s)
        when /^Name = (".*")/
          @metadata[ind].name = eval($1.to_s)
        when /^Description = (".*")/
          @metadata[ind].description = eval($1.to_s)
        when /^Note = (".*")/
          @metadata[ind].note = eval($1.to_s)
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
          @metadata[ind].message1 = eval($1.to_s)
        when /^Message 2 = (".*")/
          @metadata[ind].message2 = eval($1.to_s)
        when /^Message 3 = (".*")/
          @metadata[ind].message3 = eval($1.to_s)
        when /^Message 4 = (".*")/
          @metadata[ind].message4 = eval($1.to_s)
        when /^Name = (".*")/
          @metadata[ind].name = eval($1.to_s)
        when /^Description = (".*")/
          @metadata[ind].description = eval($1.to_s)
        when /^Note = (".*")/
          @metadata[ind].note = eval($1.to_s)
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
          @metadata.game_title = eval($1.to_s)
        when /^Currency Unit = (".*")/
          @metadata.currency_unit = eval($1.to_s)
        when /^Title 1 Name = (".*")/
          @metadata.title1_name = eval($1.to_s)
        when /^Title 2 Name = (".*")/
          @metadata.title2_name = eval($1.to_s)
        when /^Battleback 1 Name = (".*")/
          @metadata.battleback1_name = eval($1.to_s)
        when /^Battleback 2 Name = (".*")/
          @metadata.battleback2_name = eval($1.to_s)
        when /^Battler Name = (".*")/
          @metadata.battler_name = eval($1.to_s)
        else
          next
        end

      end

    end

    File.open(join(@input_path, 'System', 'Elements.txt'), 'r:UTF-8') do |elements_file|
      offset = @metadata.elements[0].nil? ? 1 : 0

      elements_file.each_line.with_index do |line, i|
        @metadata.elements[i + offset] = eval(line.strip)
      end

    end

    File.open(join(@input_path, 'System', 'Skill Types.txt'), 'r:UTF-8') do |skill_types_file|
      offset = @metadata.skill_types[0].nil? ? 1 : 0

      skill_types_file.each_line.with_index do |line, i|
        @metadata.skill_types[i + offset] = eval(line.strip)
      end

    end

    File.open(join(@input_path, 'System', 'Weapon Types.txt'), 'r:UTF-8') do |weapon_types_file|
      offset = @metadata.weapon_types[0].nil? ? 1 : 0

      weapon_types_file.each_line.with_index do |line, i|
        @metadata.weapon_types[i + offset] = eval(line.strip)
      end

    end

    File.open(join(@input_path, 'System', 'Armor Types.txt'), 'r:UTF-8') do |armor_types_file|
      offset = @metadata.armor_types[0].nil? ? 1 : 0

      armor_types_file.each_line.with_index do |line, i|
        @metadata.armor_types[i + offset] = eval(line.strip)
      end

    end

    File.open(join(@input_path, 'System', 'Switches.txt'), 'r:UTF-8') do |switches_file|
      offset = @metadata.switches[0].nil? ? 1 : 0

      switches_file.each_line.with_index do |line, i|
        @metadata.switches[i + offset] = eval(line.strip)
      end

    end

    File.open(join(@input_path, 'System', 'Variables.txt'), 'r:UTF-8') do |variables_file|
      offset = @metadata.variables[0].nil? ? 1 : 0

      variables_file.each_line.with_index do |line, i|
        @metadata.variables[i + offset] = eval(line.strip)
      end

    end

    File.open(join(@input_path, 'System', 'Terms.txt'), 'r:UTF-8') do |terms_file|
      values = []

      terms_file.each_line do |line|
        next unless line.include?('=')
        values << eval(line.strip.split(' = ')[1])
      end

      @metadata.terms.basic = values[0..7]
      @metadata.terms.params = values[8..15]
      @metadata.terms.etypes = values[16..20]
      @metadata.terms.commands = values[21..43]

    end

  end

  def compile_troops

    File.open(join(@input_path, 'Troops.txt'), 'r:UTF-8') do |troops_file|
      troop_ind = 0
      page_ind = 0

      troops_file.each_line do |line|

        case line
        when /^Troop (\d+)/
          troop_ind = $1.to_i
        when /^Name = (".*")/
          @metadata[troop_ind].name = eval($1.to_s)
        when /Page (\d+)/
          page_ind = $1.to_i
        when /(\d+)-(\D+?)\((.*)\)/
          parameters = eval($3.to_s)
          deserialize_parameters(parameters)

          @metadata[troop_ind].pages[page_ind].list[$1.to_i].code = TARGETED_EVENT_COMMANDS.key($2)
          @metadata[troop_ind].pages[page_ind].list[$1.to_i].parameters = parameters
        else
          next

        end

      end

    end

  end

end