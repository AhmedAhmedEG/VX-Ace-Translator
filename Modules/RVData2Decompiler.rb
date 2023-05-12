class RVData2Decompiler

  def initialize
    @output_path = ''
    @rvdata2_data = []
  end

  attr_accessor :output_path
  attr_accessor :rvdata2_data

  def decompile(game_path, output_path='Decompiled')
    data_path = "#{game_path}/Data"
    @output_path = output_path

    Dir.foreach(data_path) do |filename|
      next if filename == '.' || filename == '..'

      file_basename = File.basename(filename, '.*')
      next unless SUPPORTED_FORMATS.any? { |s| file_basename.include?(s) }

      print "#{RED_COLOR}Decompiling #{filename}...\n#{RESET_COLOR}"
      $stdout.flush

      File.open("#{data_path}/#{filename}", 'rb') do |rvdata2_file|
        @rvdata2_data = Marshal.load(rvdata2_file.read)
      end

      Dir.mkdir(@output_path) unless Dir.exist?(@output_path)
      case file_basename

      when 'Actors'
        self.decompile_actors

      when 'Classes'
        self.decompile_classes

      when 'CommonEvents'
        self.decompile_common_events

      when 'Enemies'
        self.decompile_enemies

      when 'Items'
        self.decompile_items

      when 'MapInfos'
        self.decompile_map_infos

      when 'Scripts'
        self.decompile_scripts

      when 'Skills'
        self.decompile_skills

      when 'States'
        self.decompile_states

      when 'System'
        self.decompile_system

      when 'Troops'
        self.decompile_troops

      else

        if file_basename.match(/\AMap\d+\z/)
          self.decompile_map(file_basename)
        end

      end

      Dir.mkdir("#{@output_path}/Metadata") unless Dir.exist?("#{@output_path}/Metadata")
      File.open("#{@output_path}/Metadata/#{file_basename}.metadata", 'wb') do |metadata_file|
        metadata_file.write(Marshal.dump(@rvdata2_data))
      end

      print "#{GREEN_COLOR}Decompiled #{filename}\n#{RESET_COLOR}"
      $stdout.flush
    end

  end

  # Array of RPG::Actor class instances
  def decompile_actors

    File.open("#{@output_path}/Actors.txt", 'w:UTF-8') do |actors_file|

      @rvdata2_data.each_with_index do |actor, i|
        next if actor.nil?

        actors_file.write("Actor #{i}\n")
        actors_file.write("Nickname = #{textualize(actor.nickname)}\n")
        actors_file.write("Character Name = #{textualize(actor.character_name)}\n")
        actors_file.write("Face Name = #{textualize(actor.face_name)}\n")
        actors_file.write("Name = #{textualize(actor.name)}\n")
        actors_file.write("Description = #{textualize(actor.description)}\n")
        actors_file.write("Note = #{textualize(actor.note)}\n\n")
      end

    end

  end

  # Array of RPG::Class class instances
  def decompile_classes

    File.open("#{@output_path}/Classes.txt", 'w:UTF-8') do |classes_file|

      @rvdata2_data.each_with_index do |klass, i|
        next if klass.nil?

        classes_file.write("Class #{i}\n")
        classes_file.write("Name = #{textualize(klass.name)}\n")
        classes_file.write("Description = #{textualize(klass.description)}\n")
        classes_file.write("Note = #{textualize(klass.note)}\n\n")
      end

    end

  end

  # Array of RPG::CommonEvent class instances
  def decompile_common_events

    File.open("#{@output_path}/CommonEvents.txt", 'w:UTF-8') do |common_events_file|

      @rvdata2_data.each_with_index do |event, i|
        next if event.nil?
        current_event = i

        event.list.each_with_index do |event_command, j|
          event_code = event_command.code
          next unless TARGETED_EVENT_COMMANDS.keys.include?(event_code)

          unless current_event.nil?
            common_events_file.write("Event #{i}\n")
            current_event = nil
          end

          common_events_file.write("#{TARGETED_EVENT_COMMANDS[event_code]}#{j}(#{textualize(event_command.parameters)})\n")
        end

        if current_event.nil?
          common_events_file.write("\n")
        end

      end

    end

  end

  # Array of RPG::Enemy class instances
  def decompile_enemies

    File.open("#{@output_path}/Enemies.txt", 'w:UTF-8') do |enemies_file|

      @rvdata2_data.each_with_index do |enemy, i|
        next if enemy.nil?

        enemies_file.write("Enemy #{i}\n")
        enemies_file.write("Battler Name = #{textualize(enemy.battler_name)}\n")
        enemies_file.write("Name = #{textualize(enemy.name)}\n")
        enemies_file.write("Description = #{textualize(enemy.description)}\n")
        enemies_file.write("Note = #{textualize(enemy.note)}\n\n")
      end

    end

  end

  # Array of RPG::Item class instances
  def decompile_items

    File.open("#{@output_path}/Items.txt", 'w:UTF-8') do |items_file|

      @rvdata2_data.each_with_index do |item, i|
        next if item.nil?

        items_file.write("Item #{i}\n")
        items_file.write("Name = #{textualize(item.name)}\n")
        items_file.write("Description = #{textualize(item.description)}\n")
        items_file.write("Note = #{textualize(item.note)}\n\n")
      end

    end

  end

  # Instance of RPG::Map class
  def decompile_map(filename)

    Dir.mkdir("#{@output_path}/Maps") unless Dir.exist?("#{@output_path}/Maps")
    File.open("#{@output_path}/Maps/#{filename}.txt", 'w:UTF-8') do |map_file|
      map_file.write("Display Name = #{textualize(@rvdata2_data.display_name)}\n")
      map_file.write("Parallax Name = #{textualize(@rvdata2_data.parallax_name)}\n")
      map_file.write("Note = #{textualize(@rvdata2_data.note)}\n\n")

      keys = @rvdata2_data.events.keys.sort
      keys.each_with_index do |key|
        current_event = key

        @rvdata2_data.events[key].pages.each_with_index do |page, i|
          current_page = i

          page.list.each_with_index do |event_command, j|
            event_code = event_command.code
            next unless TARGETED_EVENT_COMMANDS.keys.include?(event_code)

            unless current_event.nil?
              map_file.write("Event #{key}\n")
              current_event = nil
            end

            unless current_page.nil?
              map_file.write("\nPage #{i}\n")
              current_page = nil
            end

            map_file.write("#{TARGETED_EVENT_COMMANDS[event_code]}#{j}(#{textualize(event_command.parameters)})\n")
          end

        end

        if current_event.nil?
          map_file.write("\n")
        end

      end

    end

  end

  # Hash of [id: RPG::MapInfo instance] pairs
  def decompile_map_infos

    File.open("#{@output_path}/MapInfos.txt", 'w:UTF-8') do |map_infos_file|
      sorted_keys = @rvdata2_data.keys.sort

      sorted_keys.each do |key|
        next if @rvdata2_data[key].nil?

        map_infos_file.write("MapInfo #{key}\n")
        map_infos_file.write("Name = #{textualize(@rvdata2_data[key].name)}\n\n")
      end

    end

  end

  # 2D Array, every row have [id, script name, zlib compressed text]
  def decompile_scripts

    @rvdata2_data.each_with_index do |script, i|
      script_path = "#{@output_path}/Scripts/#{i} - #{File.basename(script[1])}.rb"
      Dir.mkdir(File.dirname(script_path)) unless Dir.exist?(File.dirname(script_path))

      File.open(script_path, 'wb') do |script_file|
        script_file.write(Zlib::Inflate.inflate(script[2]))
      end

      script.delete_at(2)

    end

  end

  # Array of RPG::Skill class instances
  def decompile_skills

    File.open("#{@output_path}/Skills.txt", 'w:UTF-8') do |skills_file|

      @rvdata2_data.each_with_index do |skill, i|
        next if skill.nil?

        skills_file.write("Skill #{i}\n")
        skills_file.write("Message 1 = #{textualize(skill.message1)}\n")
        skills_file.write("Message 2 = #{textualize(skill.message2)}\n")
        skills_file.write("Name = #{textualize(skill.name)}\n")
        skills_file.write("Description = #{textualize(skill.description)}\n")
        skills_file.write("Note = #{textualize(skill.note)}\n\n")
      end

    end

  end

  # Array of RPG::State class instances
  def decompile_states

    File.open("#{@output_path}/States.txt", 'w:UTF-8') do |states_file|

      @rvdata2_data.each_with_index do |state, i|
        next if state.nil?

        states_file.write("State #{i}\n")
        states_file.write("Message 1 = #{textualize(state.message1)}\n")
        states_file.write("Message 2 = #{textualize(state.message2)}\n")
        states_file.write("Message 3 = #{textualize(state.message3)}\n")
        states_file.write("Message 4 = #{textualize(state.message4)}\n")
        states_file.write("Name = #{textualize(state.name)}\n")
        states_file.write("Description = #{textualize(state.description)}\n")
        states_file.write("Note = #{textualize(state.note)}\n\n")
      end

    end

  end

  # Instance of RPG::System class instances
  def decompile_system

    File.open("#{@output_path}/System.txt", 'w:UTF-8') do |system_file|
      system_file.write("Game Title = #{textualize(@rvdata2_data.game_title)}\n")
      system_file.write("Currency Unit = #{textualize(@rvdata2_data.currency_unit)}\n")
      system_file.write("Title 1 Name = #{textualize(@rvdata2_data.title1_name)}\n")
      system_file.write("Title 2 Name = #{textualize(@rvdata2_data.title2_name)}\n")
      system_file.write("Battleback 1 Name = #{textualize(@rvdata2_data.battleback1_name)}\n")
      system_file.write("Battleback 2 Name = #{textualize(@rvdata2_data.battleback2_name)}\n")
      system_file.write("Battler Name = #{textualize(@rvdata2_data.battler_name)}\n")
    end

    Dir.mkdir("#{@output_path}/System") unless Dir.exist?("#{@output_path}/System")

    File.open("#{@output_path}/System/Elements.txt", 'w:UTF-8') do |elements_file|

      @rvdata2_data.elements[0..-2].each do |element|
        next if element.nil?
        elements_file.write("#{textualize(element)}\n")
      end

      elements_file.write(textualize(@rvdata2_data.elements[-1]))
    end

    File.open("#{@output_path}/System/Skill Types.txt", 'w:UTF-8') do |skill_types_file|

      @rvdata2_data.skill_types[0..-2].each do |skill_type|
        next if skill_type.nil?
        skill_types_file.write("#{textualize(skill_type)}\n")
      end

      skill_types_file.write(textualize(@rvdata2_data.skill_types[-1]))
    end

    File.open("#{@output_path}/System/Weapon Types.txt", 'w:UTF-8') do |weapon_types_file|

      @rvdata2_data.weapon_types[0..-2].each do |weapon_type|
        next if weapon_type.nil?
        weapon_types_file.write("#{textualize(weapon_type)}\n")
      end

      weapon_types_file.write(textualize(@rvdata2_data.weapon_types[-1]))
    end

    File.open("#{@output_path}/System/Armor Types.txt", 'w:UTF-8') do |armor_types_file|

      @rvdata2_data.armor_types[0..-2].each do |armor_type|
        next if armor_type.nil?
        armor_types_file.write("#{textualize(armor_type)}\n")
      end

      armor_types_file.write(textualize(@rvdata2_data.armor_types[-1]))
    end

    File.open("#{@output_path}/System/Switches.txt", 'w:UTF-8') do |switches_file|

      @rvdata2_data.switches[0..-2].each do |switch|
        next if switch.nil?
        switches_file.write("#{textualize(switch)}\n")
      end

      switches_file.write(textualize(@rvdata2_data.switches[-1]))
    end

    File.open("#{@output_path}/System/Variables.txt", 'w:UTF-8') do |variables_file|

      @rvdata2_data.variables[0..-2].each do |variable|
        next if variable.nil?
        variables_file.write("#{textualize(variable)}\n")
      end

      variables_file.write(textualize(@rvdata2_data.variables[-1]))
    end

    File.open("#{@output_path}/System/Terms.txt", 'w:UTF-8') do |terms_file|
      basic = @rvdata2_data.terms.basic

      terms_file.write("Basic\n")
      terms_file.write("Level = #{textualize(basic[0])}\n")
      terms_file.write("Level (Short) = #{textualize(basic[1])}\n")
      terms_file.write("HP = #{textualize(basic[2])}\n")
      terms_file.write("HP (Short) = #{textualize(basic[3])}\n")
      terms_file.write("MP = #{textualize(basic[4])}\n")
      terms_file.write("MP (Short) = #{textualize(basic[5])}\n")
      terms_file.write("TP = #{textualize(basic[6])}\n")
      terms_file.write("TP (Short) = #{textualize(basic[7])}\n\n")

      params = @rvdata2_data.terms.params

      terms_file.write("Params\n")
      terms_file.write("Maximum HP = #{textualize(params[0])}\n")
      terms_file.write("Maximum MP = #{textualize(params[1])}\n")
      terms_file.write("Attack Power = #{textualize(params[2])}\n")
      terms_file.write("Defense = #{textualize(params[3])}\n")
      terms_file.write("Magic Power = #{textualize(params[4])}\n")
      terms_file.write("Magic Defense = #{textualize(params[5])}\n")
      terms_file.write("Agility = #{textualize(params[6])}\n")
      terms_file.write("Luck = #{textualize(params[7])}\n\n")

      etypes = @rvdata2_data.terms.etypes

      terms_file.write("ETypes\n")
      terms_file.write("Weapon = #{textualize(etypes[0])}\n")
      terms_file.write("Shield = #{textualize(etypes[1])}\n")
      terms_file.write("Head = #{textualize(etypes[2])}\n")
      terms_file.write("Body = #{textualize(etypes[3])}\n")
      terms_file.write("Ornaments = #{textualize(etypes[4])}\n")

      commands = @rvdata2_data.terms.commands

      terms_file.write("\nCommands\n")
      terms_file.write("Fight = #{textualize(commands[0])}\n")
      terms_file.write("Escape = #{textualize(commands[1])}\n")
      terms_file.write("Attack = #{textualize(commands[2])}\n")
      terms_file.write("Defend = #{textualize(commands[3])}\n")
      terms_file.write("Item = #{textualize(commands[4])}\n")
      terms_file.write("Skill = #{textualize(commands[5])}\n")
      terms_file.write("Equipment = #{textualize(commands[6])}\n")
      terms_file.write("Status = #{textualize(commands[7])}\n")
      terms_file.write("Sorting = #{textualize(commands[8])}\n")
      terms_file.write("Save = #{textualize(commands[9])}\n")
      terms_file.write("End of Game = #{textualize(commands[10])}\n")
      terms_file.write("(Missing Number) = #{textualize(commands[11])}\n")
      terms_file.write("Weapons = #{textualize(commands[12])}\n")
      terms_file.write("Armor = #{textualize(commands[13])}\n")
      terms_file.write("Valuables = #{textualize(commands[14])}\n")
      terms_file.write("Change Equipment = #{textualize(commands[15])}\n")
      terms_file.write("Best Equipment = #{textualize(commands[16])}\n")
      terms_file.write("Remove All = #{textualize(commands[17])}\n")
      terms_file.write("New Game = #{textualize(commands[18])}\n")
      terms_file.write("Continue = #{textualize(commands[19])}\n")
      terms_file.write("Shutdown = #{textualize(commands[20])}\n")
      terms_file.write("Go to Title = #{textualize(commands[21])}\n")
      terms_file.write("Quit = #{textualize(commands[22])}\n")

    end

  end

  # Array of RGP::Troops class instances
  def decompile_troops

    File.open("#{@output_path}/Troops.txt", 'w:UTF-8') do |troops_file|
      @rvdata2_data.each_with_index do |troop, i|
        next if troop.nil?

        troops_file.write("Troop #{i}\n")
        troops_file.write("Name = #{textualize(troop.name)}\n\n")

        troop.pages.each_with_index do |page, j|
          next if page.nil?
          current_page = i

          page.list.each_with_index do |event_command, k|
            event_code = event_command.code
            next unless TARGETED_EVENT_COMMANDS.keys.include?(event_code)

            unless current_page.nil?
              troops_file.write("Page #{j}\n")
              current_page = nil
            end

            troops_file.write("#{TARGETED_EVENT_COMMANDS[event_code]}#{k}(#{textualize(event_command.parameters)})\n")
          end

          if current_page.nil?
            troops_file.write("\n")
          end

        end

      end

    end

  end

end