# frozen_string_literal: true

module ScanChat
  # Add a member to another owner's existing chatroom
  class AddMemberToChatroom
    # Error for owner cannot be member
    class ForbiddenError < StandardError
      def message
        'You are not allowed to invite that person as member'
      end
    end

    def self.call(auth:, chatroom:, member_username:)
      invitee = Account.first(username: member_username)
      policy = ChatroomJoinRequestPolicy.new(
        chatroom, auth[:account], invitee, auth[:scope]
      )
      raise ForbiddenError unless policy.can_invite?

      chatroom.add_member(invitee)
      invitee
    end
  end
end
