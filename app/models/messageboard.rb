# frozen_string_literal: true

require 'json'
require 'base64'
require 'rbnacl'
require 'time'
require 'sequel'

module ScanChat
  # represents a thread in the system
  class MessageBoard < Sequel::Model
    one_to_one :thread
    plugin :association_dependencies, thread: :destroy

    plugin :uuid, field: :id
    plugin :timestamps
    plugin :whitelist_security
    set_allowed_columns :is_anonymous

    # Secure getters and setters

    # rubocop:disable Metrics/MethodLength
    def to_json(options = {})
      JSON(
        {
          data: {
            type: 'messageboard',
            attributes: {
              id:,
              is_anonymous:
            }
          }
        }, options
      )
    end
    # rubocop:enable Metrics/MethodLength
  end
end
