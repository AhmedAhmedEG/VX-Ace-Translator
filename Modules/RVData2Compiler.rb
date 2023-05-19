class RVData2Compiler

  def initialize
    @output_path = ''
    @metadata = []
  end

  attr_accessor :output_path
  attr_accessor :metadata

  def compile(decompiled_path, output_path = 'Compiled')
    metadata_path = join(decompiled_path, 'Metadata')
    @output_path = output_path

    Dir.foreach(metadata_path) do |filename|
      next if filename == '.' || filename == '..'

      file_basename = File.basename(filename, '.*')
      next unless SUPPORTED_FORMATS.any? { |s| file_basename.include?(s) }

      print "#{RED_COLOR}Compiling #{file_basename}.rvdata2...\n#{RESET_COLOR}"
      $stdout.flush

      File.open("#{metadata_path}/#{filename}", "rb") do |metadata_file|
        @metadata = Marshal.load(metadata_file.read)
      end

      Dir.mkdir(@output_path) unless Dir.exist?(@output_path)
      case file_basename

      when 'Actors'
        self.compile_actors(decompiled_path)

      when 'Classes'
        self.compile_classes(decompiled_path)

      when 'CommonEvents'
        self.compile_common_events(decompiled_path)

      when 'Enemies'
        self.compile_enemies(decompiled_path)

      when 'Items'
        self.compile_items(decompiled_path)

      when 'MapInfos'
        self.compile_map_infos(decompiled_path)

      when 'Scripts'
        self.compile_scripts(decompiled_path)

      when 'Skills'
        self.compile_skills(decompiled_path)

      when 'States'
        self.compile_states(decompiled_path)

      when 'System'
        self.compile_system(decompiled_path)

      when 'Troops'
        self.compile_troops(decompiled_path)

      else

        if file_basename.match(/\AMap\d+\z/)
          self.compile_map(decompiled_path, file_basename)
        end

      end

      File.open("#{@output_path}/#{file_basename}.rvdata2", "wb") do |rvdata2_file|
        rvdata2_file.write(Marshal.dump(@metadata))
      end

      print "#{GREEN_COLOR}Compiled #{file_basename}.rvdata2\n#{RESET_COLOR}"
      $stdout.flush
    end

  end

  def compile_actors(path)

    File.open(join(path, 'Actors.txt'), 'r:UTF-8') do |actors_file|
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

  def compile_classes(path)

    File.open(join(path, 'Classes.txt'), 'r:UTF-8') do |classes_file|
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

  def compile_common_events(path)

    File.open(join(path, 'CommonEvents.txt'), 'r:UTF-8') do |common_events_file|
      event_ind = 0

      common_events_file.each_line do |line|

        case line
        when /^Event (\d+)/
          event_ind = $1.to_i
        when /\w+(\d+)\((.*)\)/
          @metadata[event_ind].list[$1.to_i].parameters = eval($2.to_s)
        else
          next
        end

      end

    end

  end

  def compile_enemies(path)

    File.open(join(path, 'Enemies.txt'), 'r:UTF-8') do |enemies_file|
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

  def compile_items(path)

    File.open(join(path, 'Items.txt'), 'r:UTF-8') do |items_file|
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

  def compile_map(path, file_basename)

    File.open(join(path, 'Maps', "#{file_basename}.txt"), 'r:UTF-8') do |map_file|
      event_ind = 0
      page_ind = 0

      map_file.each_line do |line|

        case line
        when /^Display Name = (".*")/
          @metadata.display_name = eval($1.to_s)
        when /^Parallax Name = (".*")/
          @metadata.parallax_name = eval($1.to_s)
        when /^Note = (".*")/
          @metadata.note = eval($1.to_s)
        when /^Event (\d+)/
          event_ind = $1.to_i
        when /^Page (\d+)/
          page_ind = $1.to_i
        when /\w+(\d+)\((.*)\)/
          @metadata.events[event_ind].pages[page_ind].list[$1.to_i].parameters = eval($2.to_s)
        else
          next
        end

      end

    end

  end

  def compile_map_infos(path)

    File.open(join(path, 'MapInfos.txt'), 'r:UTF-8') do |map_infos_file|
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

  def compile_scripts(path)

    @metadata.each_with_index  do |script, i|
      script_path =  join(path, 'Scripts', "#{i} - #{File.basename(script[1])}.rb")

      File.open(script_path, 'rb') do |script_file|
        script << Zlib::Deflate.deflate(script_file.read)
      end

    end

  end

  def compile_skills(path)

    File.open(join(path, 'Skills.txt'), 'r:UTF-8') do |skills_file|
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

  def compile_states(path)

    File.open(join(path, 'States.txt'), 'r:UTF-8') do |states_file|
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

  def compile_system(path)

    File.open(join(path, 'System.txt'), 'r:UTF-8') do |system_file|

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

    File.open(join(path, 'System', 'Elements.txt'), 'r:UTF-8') do |elements_file|

      elements_file.each_line.with_index do |line, i|
        @metadata.elements[i + 1] = eval(line.strip)
      end

    end

    File.open(join(path, 'System', 'Skill Types.txt'), 'r:UTF-8') do |skill_types_file|

      skill_types_file.each_line.with_index do |line, i|
        @metadata.skill_types[i + 1] = eval(line.strip)
      end

    end

    File.open(join(path, 'System', 'Weapon Types.txt'), 'r:UTF-8') do |weapon_types_file|

      weapon_types_file.each_line.with_index do |line, i|
        @metadata.weapon_types[i + 1] = eval(line.strip)
      end

    end

    File.open(join(path, 'System', 'Armor Types.txt'), 'r:UTF-8') do |armor_types_file|

      armor_types_file.each_line.with_index do |line, i|
        @metadata.armor_types[i + 1] = eval(line.strip)
      end

    end

    File.open(join(path, 'System', 'Switches.txt'), 'r:UTF-8') do |switches_file|

      switches_file.each_line.with_index do |line, i|
        @metadata.switches[i + 1] = eval(line.strip)
      end

    end

    File.open(join(path, 'System', 'Variables.txt'), 'r:UTF-8') do |variables_file|

      variables_file.each_line.with_index do |line, i|
        @metadata.variables[i + 1] = eval(line.strip)
      end

    end

    File.open(join(path, 'System', 'Terms.txt'), 'r:UTF-8') do |terms_file|
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

  def compile_troops(path)

    File.open(join(path, 'Troops.txt'), 'r:UTF-8') do |troops_file|
      troop_ind = 0
      page_ind = 0

      troops_file.each_line do |line|

        case line
        when /^Troop (\d+)/
          troop_ind = $1.to_i
        when /^Name = (".*")/
          @metadata[troop_ind].name = eval($1.to_s)
        when /^Page (\d+)/
          page_ind = $1.to_i
        when /\w+(\d+)\((.*)\)/
          @metadata[troop_ind].pages[page_ind].list[$1.to_i].parameters = eval($2.to_s)
        else
          next
        end

      end

    end

  end

end