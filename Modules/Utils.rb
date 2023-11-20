SUPPORTED_FORMATS = %w[Actors Classes CommonEvents Enemies Items Map MapInfos Scripts Skills States System Troops Weapons Armors]

# All common events that includes text.
# TARGETED_EVENT_COMMANDS = {102 => 'ShowChoices',
#                            108 => 'Comment',
#                            320 => 'ChangeActorName',
#                            324 => 'ChangeActorNickname',
#                            355 => 'Script',
#                            401 => 'ShowText',
#                            402 => 'When',
#                            405 => 'ShowScrollingText',
#                            408 => 'CommentMore',
#                            655 => 'ScriptMore' }

TARGETED_EVENT_COMMANDS = {0 => "Empty",
                           101 => "ShowTextAttributes",
                           102 => "ShowChoices",
                           103 => "InputNumber",
                           104 => "SelectKeyItem",
                           105 => "ShowScrollingTextAttributes",
                           108 => "Comment",
                           111 => "ConditionalBranch",
                           112 => "Loop",
                           113 => "BreakLoop",
                           115 => "ExitEventProcessing",
                           117 => "CallCommonEvent",
                           118 => "Label",
                           119 => "JumpToLabel",
                           121 => "ControlSwitches",
                           122 => "ControlVariables",
                           123 => "ControlSelfSwitch",
                           124 => "ControlTimer",
                           125 => "ChangeGold",
                           126 => "ChangeItems",
                           127 => "ChangeWeapons",
                           128 => "ChangeArmor",
                           129 => "ChangePartyMember",
                           132 => "ChangeBattleBGM",
                           133 => "ChangeBattleEndME",
                           134 => "ChangeSaveAccess",
                           135 => "ChangeMenuAccess",
                           136 => "ChangeEncounter",
                           137 => "ChangeFormationAccess",
                           138 => "ChangeWindowColor",
                           201 => "TransferPlayer",
                           202 => "SetVehicleLocation",
                           203 => "SetEventLocation",
                           204 => "ScrollMap",
                           206 => "GetSwitchVehicle",
                           211 => "ChangeTransparency",
                           212 => "ShowAnimation",
                           213 => "ShotBalloonIcon",
                           214 => "EraseEvent",
                           216 => "ChangePlayerFollowers",
                           217 => "GatherFollowers",
                           221 => "FadeoutScreen",
                           222 => "FadeinScreen",
                           223 => "TintScreen",
                           224 => "FlashScreen",
                           225 => "ShakeScreen",
                           230 => "Wait",
                           231 => "ShowPicture",
                           232 => "MovePicture",
                           233 => "RotatePicture",
                           234 => "TintPicture",
                           235 => "ErasePicture",
                           236 => "SetWeatherEffects",
                           241 => "PlayBGM",
                           242 => "FadeoutBGM",
                           243 => "SaveBGM",
                           244 => "ReplayBGM",
                           245 => "PlayBGS",
                           246 => "FadeoutBGS",
                           249 => "PlayME",
                           250 => "PlaySE",
                           251 => "StopSE",
                           261 => "PlayMovie",
                           281 => "ChangeMapDisplay",
                           282 => "ChangeTileset",
                           283 => "ChangeBattleBack",
                           284 => "ChangeParallaxBack",
                           285 => "GetLocationInfo",
                           301 => "BattleProcessing",
                           302 => "ShopProcessing",
                           303 => "NameInputProcessing",
                           311 => "ChangeHP",
                           312 => "ChangeMP",
                           313 => "ChangeState",
                           314 => "RecoverAll",
                           315 => "ChangeEXP",
                           316 => "ChangeLevel",
                           317 => "ChangeParameters",
                           318 => "ChangeSkills",
                           319 => "ChangeEquipment",
                           320 => "ChangeActorName",
                           321 => "ChangeActorClass",
                           322 => "ChangeActorGraphic",
                           323 => "ChangeVehicleGraphic",
                           324 => "ChangeActorNickname",
                           331 => "ChangeEnemyHP",
                           332 => "ChangeEnemyMP",
                           333 => "ChangeEnemyState",
                           334 => "EnemyRecoverAll",
                           335 => "EnemyAppear",
                           336 => "EnemyTransform",
                           337 => "ShowBattleAnimation",
                           339 => "ForceAction",
                           340 => "AbortBattle",
                           351 => "OpenMenuScreen",
                           352 => "OpenSaveScreen",
                           353 => "GameOver",
                           354 => "ReturnToTitleScreen",
                           355 => "Script",
                           401 => "ShowText",
                           402 => "When",
                           403 => "WhenCancel",
                           404 => "ChoicesEnd",
                           405 => "ShowScrollingText",
                           408 => "CommentMore",
                           411 => "Else",
                           412 => "BranchEnd",
                           413 => "RepeatAbove",
                           601 => "IfWin",
                           602 => "IfEscape",
                           603 => "IfLose",
                           604 => "BattleProcessingEnd",
                           605 => "ShopItem",
                           655 => "ScriptMore"}

RED_COLOR = "\e[31m"
GREEN_COLOR = "\e[32m"
BLUE_COLOR = "\e[34m"
RESET_COLOR = "\e[0m"

# Convert an class attribute to a parsable string, along with unicode characters un-escaping.
def textualize(attribute)
  # attribute.inspect.gsub(/\\u([\da-fA-F]{4})/) { [$1.to_i(16)].pack("U*") }
  attribute.inspect
end

def serialize_parameters(parameters)

  parameters.each_with_index do |parameter, i|

    if parameter.class.name.to_s.start_with?('Table', 'Tone', 'Color', 'RPG::')

      attributes = parameter.class.instance_method(:initialize).parameters.map do |_, var|
        attribute = parameter.instance_variable_get("@#{var}")
        "#{var.to_s}=#{textualize(attribute)}"
      end

      parameters[i] = "#{parameter.class.name}(#{attributes.join(',')})"

    end

  end

end

def deserialize_parameters(parameters)

  parameters.each_with_index do |parameter, i|

    if parameter.to_s.start_with?('Table', 'Tone', 'Color', 'RPG::')
      class_name, attributes = parameter.match(/(.+?)\((.+)\)/).captures
      class_obj = Object.const_get(class_name)

      attribute_values = attributes.split(',').map { |attrib| eval(attrib.split('=')[-1]) }
      parameters[i] = class_obj.new(*attribute_values)
    end

  end

end

def decrypt_game(game_path)
  game_data_path = join(game_path, 'Data')

  unless Dir.exist?(game_data_path) && !Dir.empty?(game_data_path)
    rgss3a_path = join(game_path, 'Game.rgss3a')

    if File.exist?(rgss3a_path + '.old')
      File.rename(rgss3a_path + '.old', rgss3a_path)
    end

    decrypter_path =  join('Resources', 'Tools', 'RPGMakerDecrypter.exe')

    system("\"#{decrypter_path}\" \"#{rgss3a_path}\"")
    File.rename(rgss3a_path, rgss3a_path + '.old')
  end

end

def join(*paths)

  if paths[0].include?('\\')
    joined_path = File.join(paths).gsub("/", "\\")
  elsif paths[0].include?('/')
    joined_path = File.join(paths).gsub("\\", "/")
  else
    joined_path = File.join(paths)
  end

  joined_path
end