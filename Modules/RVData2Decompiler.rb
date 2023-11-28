require 'stringio'

class RVData2Decompiler

  def initialize
    @output_path = ''
    @rvdata2_data = []
    @indentation = ' ' * 2
  end

  attr_accessor :output_path
  attr_accessor :rvdata2_data
  attr_accessor :indentation

  def decompile(game_path, output_path='', target_basename='', indexless=true, force_decrypt=false)
    input_path = join(game_path, 'Data')

    decrypt_game(game_path, forced=force_decrypt, remove_ex=false)
    if output_path.empty?
      @output_path = "Decompiled"
    else
      @output_path = output_path
    end

    FileUtils.mkdir_p(@output_path) unless Dir.exist?(@output_path)

    Dir.foreach(input_path) do |filename|
      next if %w[. ..].include?(filename) || File.directory?(join(input_path, filename))

      file_basename = File.basename(filename, '.*')
      next unless SUPPORTED_FORMATS.any? { |s| file_basename.include?(s) }

      unless target_basename.empty?
        next unless file_basename.include?(target_basename)
      end

      print "#{BLUE_COLOR}Reading #{filename}...#{RESET_COLOR}"

      File.open(join(input_path, filename), 'rb') do |rvdata2_file|
        @rvdata2_data = Marshal.load(rvdata2_file.read)
      end

      clear_line
      print "\r#{BLUE_COLOR}Decompiling #{filename}...#{RESET_COLOR}"

      Dir.mkdir(@output_path) unless Dir.exist?(@output_path)
      case file_basename

      when 'Actors'
        self.decompile_actors

      when 'Classes'
        self.decompile_classes

      when 'CommonEvents'
        self.decompile_common_events(indexless=indexless)

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
        self.decompile_troops(indexless=indexless)

      when 'Weapons'
        self.decompile_weapons

      when 'Armors'
        self.decompile_armors

      else

        if file_basename.match(/\AMap\d+\z/)
          self.decompile_map(file_basename, indexless=indexless)
        end

      end

      clear_line
      print "\r#{GREEN_COLOR}Decompiled #{filename}.#{RESET_COLOR}\n"

    end

  end

  # Array of RPG::Actor class instances
  def decompile_actors

    File.open(join(@output_path, 'Actors.txt'), 'w:UTF-8') do |actors_file|

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

    File.open(join(@output_path, 'Classes.txt'), 'w:UTF-8') do |classes_file|

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
  def decompile_common_events(indexless=true)
    Dir.mkdir(join(@output_path, 'CommonEvents')) unless Dir.exist?(join(@output_path, 'CommonEvents'))

    @rvdata2_data.each_with_index do |event, i|
      next if event.nil? || event.list.empty?
      common_events_file = StringIO.new('')

      common_events_file.write("CommonEvent #{i}\n")
      common_events_file.write("Name = #{textualize(event.name)}\n\n")

      last_indentation = 0
      event.list.each_with_index do |event_command, j|
        event_command_code = event_command.code

        unless indexless
          next unless TARGETED_EVENT_COMMANDS.keys.include?(event_command_code) && !event_command.parameters.empty?
        end

        if event_command.indent < last_indentation
          common_events_file.write("\n")
        end

        last_indentation = event_command.indent

        event_command_name = TARGETED_EVENT_COMMANDS[event_command_code]
        if event_command_name == 'ShowText' && event_command.parameters[0].empty?
          event_command.parameters[0] = ' '
        end

        serialize_parameters(event_command.parameters)

        if indexless
          common_events_file.write(@indentation * (event_command.indent + 1) +
                                     "#{event_command_name}(#{textualize(event_command.parameters)})\n")

        else
          common_events_file.write(@indentation * (event_command.indent + 1) +
                                   "#{j}-#{event_command_name}(#{textualize(event_command.parameters)})\n")

        end

      end

      common_events_file.rewind
      if common_events_file.each_line.count > 3

        File.open(join(@output_path, 'CommonEvents', "CommonEvent#{i}.txt"), 'w:UTF-8') do |o|
          o.write(common_events_file.string)
        end

      end

    end

  end

  # Array of RPG::Enemy class instances
  def decompile_enemies

    File.open(join(@output_path, 'Enemies.txt'), 'w:UTF-8') do |enemies_file|

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

    File.open(join(@output_path, 'Items.txt'), 'w:UTF-8') do |items_file|

      @rvdata2_data.each_with_index do |item, i|
        next if item.nil?

        items_file.write("Item #{i}\n")
        items_file.write("Name = #{textualize(item.name)}\n")
        items_file.write("Description = #{textualize(item.description)}\n")
        items_file.write("Note = #{textualize(item.note)}\n\n")
      end

    end

  end

  # Array of RPG::Weapon class instances
  def decompile_weapons

    File.open(join(@output_path, 'Weapons.txt'), 'w:UTF-8') do |weapons_file|

      @rvdata2_data.each_with_index do |weapon, i|
        next if weapon.nil?

        weapons_file.write("Weapon #{i}\n")
        weapons_file.write("Name = #{textualize(weapon.name)}\n")
        weapons_file.write("Description = #{textualize(weapon.description)}\n")
        weapons_file.write("Note = #{textualize(weapon.note)}\n\n")
      end

    end

  end

  # Array of RPG::Armor class instances
  def decompile_armors

    File.open(join(@output_path, 'Armors.txt'), 'w:UTF-8') do |armors_file|

      @rvdata2_data.each_with_index do |armor, i|
        next if armor.nil?

        armors_file.write("Armor #{i}\n")
        armors_file.write("Name = #{textualize(armor.name)}\n")
        armors_file.write("Description = #{textualize(armor.description)}\n")
        armors_file.write("Note = #{textualize(armor.note)}\n\n")
      end

    end

  end

  # Instance of RPG::Map class
  def decompile_map(filename, indexless=true)
    Dir.mkdir(join(@output_path, 'Maps')) unless Dir.exist?(join(@output_path, 'Maps'))

    File.open(join(@output_path, 'Maps', "#{filename}.txt"), 'w:UTF-8') do |map_file|
      map_file.write("Display Name = #{textualize(@rvdata2_data.display_name)}\n")
      map_file.write("Parallax Name = #{textualize(@rvdata2_data.parallax_name)}\n")
      map_file.write("Note = #{textualize(@rvdata2_data.note)}\n")

      event_keys = @rvdata2_data.events.keys.sort
      event_keys.each do |event_key|
        event = @rvdata2_data.events[event_key]

        map_file.write("\nCommonEvent #{event_key}\n")
        map_file.write("Name = #{textualize(event.name)}\n")

        event.pages.each_with_index do |page, i|
          next if page.nil?

          lines = ["\n#{@indentation}Page #{i}\n"]
          last_indentation = 0

          page.list.each_with_index do |event_command, j|
            event_command_code = event_command.code

            unless indexless
              next unless TARGETED_EVENT_COMMANDS.keys.include?(event_command_code) && !event_command.parameters.empty?
            end

            if event_command.indent != last_indentation && event_command.indent == 0
              lines.append("\n")
            end

            last_indentation = event_command.indent

            event_command_name = TARGETED_EVENT_COMMANDS[event_command_code]
            if event_command_name == 'ShowText' && event_command.parameters[0].empty?
              event_command.parameters[0] = ' '
            end

            serialize_parameters(event_command.parameters)

            if indexless
              lines.append(@indentation * (event_command.indent + 2) +
                           "#{event_command_name}(#{textualize(event_command.parameters)})\n")

            else
              lines.append(@indentation * (event_command.indent + 2) +
                           "#{j}-#{event_command_name}(#{textualize(event_command.parameters)})\n")

            end

          end

          if lines.length > 1
            map_file.write(*lines)
          end

        end

      end

    end

  end

  # Hash of [id: RPG::MapInfo instance] pairs
  def decompile_map_infos

    File.open(join(@output_path, 'MapInfos.txt'), 'w:UTF-8') do |map_infos_file|
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
      script_path = join(@output_path, 'Scripts', File.dirname(script[1]))
      FileUtils.mkdir_p(script_path) unless Dir.exist?(script_path)

      script_filename = "#{i} - #{File.basename(script[1])}.rb"
      File.open(join(script_path, script_filename), 'wb') do |script_file|
        script_file.write(Zlib::Inflate.inflate(script[2]))
      end

    end

  end

  # Array of RPG::Skill class instances
  def decompile_skills

    File.open(join(@output_path, 'Skills.txt'), 'w:UTF-8') do |skills_file|

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

    File.open(join(@output_path, 'States.txt'), 'w:UTF-8') do |states_file|

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

    File.open(join(@output_path, 'System.txt'), 'w:UTF-8') do |system_file|
      system_file.write("Game Title = #{textualize(@rvdata2_data.game_title)}\n")
      system_file.write("Currency Unit = #{textualize(@rvdata2_data.currency_unit)}\n")
      system_file.write("Title 1 Name = #{textualize(@rvdata2_data.title1_name)}\n")
      system_file.write("Title 2 Name = #{textualize(@rvdata2_data.title2_name)}\n")
      system_file.write("Battleback 1 Name = #{textualize(@rvdata2_data.battleback1_name)}\n")
      system_file.write("Battleback 2 Name = #{textualize(@rvdata2_data.battleback2_name)}\n")
      system_file.write("Battler Name = #{textualize(@rvdata2_data.battler_name)}\n")
    end

    Dir.mkdir(join(@output_path, 'System')) unless Dir.exist?(join(@output_path, 'System'))

    File.open(join(@output_path, 'System', 'Elements.txt'), 'w:UTF-8') do |elements_file|

      @rvdata2_data.elements[0..-2].each do |element|
        next if element.nil?
        elements_file.write("#{textualize(element)}\n")
      end

      elements_file.write(textualize(@rvdata2_data.elements[-1]))
    end

    File.open(join(@output_path, 'System', 'Skill Types.txt'), 'w:UTF-8') do |skill_types_file|

      @rvdata2_data.skill_types[0..-2].each do |skill_type|
        next if skill_type.nil?
        skill_types_file.write("#{textualize(skill_type)}\n")
      end

      skill_types_file.write(textualize(@rvdata2_data.skill_types[-1]))
    end

    File.open(join(@output_path, 'System', 'Weapon Types.txt'), 'w:UTF-8') do |weapon_types_file|

      @rvdata2_data.weapon_types[0..-2].each do |weapon_type|
        next if weapon_type.nil?
        weapon_types_file.write("#{textualize(weapon_type)}\n")
      end

      weapon_types_file.write(textualize(@rvdata2_data.weapon_types[-1]))
    end

    File.open(join(@output_path, 'System', 'Armor Types.txt'), 'w:UTF-8') do |armor_types_file|

      @rvdata2_data.armor_types[0..-2].each do |armor_type|
        next if armor_type.nil?
        armor_types_file.write("#{textualize(armor_type)}\n")
      end

      armor_types_file.write(textualize(@rvdata2_data.armor_types[-1]))
    end

    File.open(join(@output_path, 'System', 'Switches.txt'), 'w:UTF-8') do |switches_file|

      @rvdata2_data.switches[0..-2].each do |switch|
        next if switch.nil?
        switches_file.write("#{textualize(switch)}\n")
      end

      switches_file.write(textualize(@rvdata2_data.switches[-1]))
    end

    File.open(join(@output_path, 'System', 'Variables.txt'), 'w:UTF-8') do |variables_file|

      @rvdata2_data.variables[0..-2].each do |variable|
        next if variable.nil?
        variables_file.write("#{textualize(variable)}\n")
      end

      variables_file.write(textualize(@rvdata2_data.variables[-1]))
    end

    File.open(join(@output_path, 'System', 'Terms.txt'), 'w:UTF-8') do |terms_file|
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
  def decompile_troops(indexless=true)

    File.open(join(@output_path, 'Troops.txt'), 'w:UTF-8') do |troops_file|

      @rvdata2_data.each_with_index do |troop, i|
        next if troop.nil?

        troops_file.write("Troop #{i}\n")
        troops_file.write("Name = #{textualize(troop.name)}\n")

        troop.pages.each_with_index do |page, j|
          next if page.nil?

          lines = ["\nPage #{j}\n"]
          last_indentation = 0

          page.list.each_with_index do |event_command, k|
            event_command_code = event_command.code

            unless indexless
              next unless TARGETED_EVENT_COMMANDS.keys.include?(event_command_code) && !event_command.parameters.empty?
            end

            if event_command.indent != last_indentation && event_command.indent == 0
              lines.append("\n")
            end

            last_indentation = event_command.indent

            event_command_name = TARGETED_EVENT_COMMANDS[event_command_code]
            if event_command_name == 'ShowText' && event_command.parameters[0].empty?
              event_command.parameters[0] = ' '
            end

            serialize_parameters(event_command.parameters)

            if indexless
              lines.append(@indentation * (event_command.indent + 1) + "#{event_command_name}(#{textualize(event_command.parameters)})\n")

            else
              lines.append(@indentation * (event_command.indent + 1) + "#{k}-#{event_command_name}(#{textualize(event_command.parameters)})\n")

            end

          end

          if lines.length > 1
            troops_file.write(*lines)
          end

        end

        if i != @rvdata2_data.length - 1
          troops_file.write("\n")
        end

      end

    end

  end

end