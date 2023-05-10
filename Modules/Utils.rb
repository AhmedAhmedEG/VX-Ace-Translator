SUPPORTED_FORMATS = %w[Actors Classes CommonEvents Enemies Items Map MapInfos Scripts Skills States System Troops]
TARGETED_EVENT_COMMANDS = {102 => 'ShowChoices',
                           108 => 'Comment',
                           320 => 'ChangeActorName',
                           324 => 'ChangeActorNickname',
                           355 => 'Script',
                           401 => 'ShowText',
                           402 => 'When',
                           405 => 'ShowScrollingText',
                           408 => 'CommentMore',
                           655 => 'ScriptMore' }

RED_COLOR = "\e[31m"
GREEN_COLOR = "\e[32m"
BLUE_COLOR = "\e[34m"
RESET_COLOR = "\e[0m"

# Convert an class attribute to a parsable string, along with unicode characters un-escaping.
def textualize(attribute)
  attribute.inspect.gsub(/\\u([\da-fA-F]{4})/) { [$1.to_i(16)].pack("U*") }
end