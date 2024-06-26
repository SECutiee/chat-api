# frozen_string_literal: true

module ScanChat
  # Add a message to chatroom
  class AddMessageToChatroom
    # Error for  cannot add messages
    class ForbiddenError < StandardError
      def message
        'You are not allowed to add a message'
      end
    end

    # Error for requests with illegal attributes
    class IllegalRequestError < StandardError
      def message
        'Cannot add a message with those attributes'
      end
    end

    def self.call(auth:, chatroom:, message_data:)
      policy = ChatroomPolicy.new(auth[:account], chatroom, auth[:scope])
      raise ForbiddenError unless policy.can_add_messages?

      # message_data.delete('sender_username') unless message_data['sender_username'].nil?
      # message_data.delete('thread_name') unless message_data['thread_name'].nil?
      msg_data = {}
      msg_data['content'] = message_data['content']
      msg_data['sender_id'] = auth[:account].id

      chatroom.add_message(msg_data)
    rescue Sequel::MassAssignmentRestriction
      raise IllegalRequestError
    end
  end
end
