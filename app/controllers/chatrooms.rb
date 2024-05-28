# frozen_string_literal: true

require 'roda'
require_relative 'app'

module ScanChat
  # Web controller for ScanChat API
  class Api < Roda
    route('chatrooms') do |r|
      @chatroom_route = "#{@api_root}/chatrooms"

      r.on String do |thread_id|
        r.on 'messages' do
          @mes_route = "#{@api_root}/chatrooms/#{thread_id}/messages"

          # GET api/v1/chatrooms/[thread_id]/messages/[mes_id]
          r.get String do |mes_id|
            mes = Message.where(thread_id:, id: mes_id).first
            mes ? mes.to_json : raise('Message not found')
          rescue StandardError => e
            r.halt 404, { message: e.message }.to_json
          end

          # GET api/v1/chatrooms/[thread_id]/messages
          r.get do
            output = { data: Thread.first(id: thread_id).messages }
            JSON.pretty_generate(output)
          rescue StandardError
            r.halt 404, { message: 'Could not find messages' }.to_json
          end

          # POST api/v1/chatrooms/[thread_id]/messages
          r.post do
            new_data = JSON.parse(r.body.read)
            thread = Thread.first(id: thread_id)
            new_mes = thread.add_message(new_data)
            raise 'Could not create Message' unless new_mes

            response.status = 201
            response['Location'] = "#{@mes_route}/#{new_mes.id}"
            { message: 'Message sended', data: new_mes }.to_json
          rescue Sequel::MassAssignmentRestriction
            Api.logger.warn "MASS-ASSIGNMENT: #{new_data.keys}"
            r.halt 400, { message: 'Illegal Attributes' }.to_json
          rescue StandardError => e
            Api.logger.error "UNKNOWN ERROR: #{e.message}"
            r.halt 500, { message: e.message }.to_json
          end
        end

        # GET api/v1/chatrooms/[thread_id]
        r.get do
          chatroom = Chatroom.first(thread_id:)
          raise 'Chatroom not found' unless chatroom

          output = chatroom
          JSON.pretty_generate(output)
        rescue StandardError => e
          Api.logger.error "UNKNOWN ERROR: #{e.message}"
          r.halt 404, { message: e.message }.to_json
        end
      end

      # TODO: problem is that we only get chatrooms and not the attributes in threads
      # maybe it doesn't matter since we will never use this function actually

      # GET api/v1/chatrooms/
      r.get do
        account = Account.first(username: @auth_account['username'])
        chatrooms = account.chatrooms
        JSON.pretty_generate(data: chatrooms)
      rescue StandardError
        r.halt 403, { message: 'Could not find any chatrooms' }.to_json
      end

      # POST api/v1/chatrooms
      r.post do
        new_data = JSON.parse(routing.body.read)
        new_chatr = Chatroom.new(new_data)
        raise('Could not save chatroom') unless new_chatr.save

        response.status = 201
        response['Location'] = "#{@chatr_route}/#{new_chatr.id}"
        { message: 'Chatroom saved', data: new_chatr }.to_json
      rescue Sequel::MassAssignmentRestriction
        Api.logger.warn "MASS-ASSIGNMENT: #{new_data.keys}"
        r.halt 400, { message: 'Illegal Attributes' }.to_json
      rescue StandardError => e
        Api.logger.error "UNKOWN ERROR: #{e.message}"
        r.halt 500, { message: 'Unknown server error' }.to_json
      end
    end
  end
end
