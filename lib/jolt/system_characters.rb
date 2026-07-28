# frozen_string_literal: true

module Jolt
  module SystemCharacters
    def __register_character(character, shape)
      @character_registry << character
      @shapes[shape.object_id] = shape
    end

    def __destroy_character(character)
      return if character.destroyed?

      __check_alive!
      removed = @character_registry.delete(character)
      raise InvalidArgumentError, "virtual character does not belong to this system" unless removed

      character.__destroy_native
      nil
    end

    def __destroy_all_characters
      @character_registry.dup.each(&:destroy)
    end
  end
end
