# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/rg'
require 'rack/test'
require 'yaml'

require_relative '../app/controllers/app'
require_relative '../app/models/chat'

def app
  Chats::Api
end

DATA = YAML.safe_load File.read('app/db/seeds/chats_seeds.yml')

describe 'Test Chats Web API' do
  include Rack::Test::Methods

  before do
    # Wipe database before each test
    Dir.glob("#{Chats::STORE_DIR}/*.txt").each { |filename| FileUtils.rm(filename) }
  end

  it 'should find the root route' do
    get '/'
    _(last_response.status).must_equal 200
  end

  describe 'Handle chats' do
    it 'HAPPY: should be able to get list of all chats' do
      Chats::Chatroom.new(DATA[0]).save
      Chats::Chatroom.new(DATA[1]).save

      get 'api/v1/chatrooms'
      result = JSON.parse last_response.body
      _(result['chatroom_ids'].count).must_equal 2
    end

    it 'HAPPY: should be able to get details of a single chatroom' do
      Chats::Chatroom.new(DATA[1]).save
      id = Dir.glob("#{Chats::STORE_DIR}/*.txt").first.split(%r{[/.]})[1]

      get "/api/v1/chatrooms/#{id}"
      result = JSON.parse last_response.body

      _(last_response.status).must_equal 200
      _(result['id']).must_equal id
    end

    it 'SAD: should return error if unknown chatrooms requested' do
      get '/api/v1/chatrooms/foobar'

      _(last_response.status).must_equal 404
    end

    it 'HAPPY: should be able to create new chatrooms' do
      req_header = { 'CONTENT_TYPE' => 'application/json' }
      post 'api/v1/chatrooms', DATA[1].to_json, req_header

      _(last_response.status).must_equal 201
    end
  end
end
