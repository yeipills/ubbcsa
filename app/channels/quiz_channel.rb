# app/channels/quiz_channel.rb
class QuizChannel < ApplicationCable::Channel
  def subscribed
    stream_from "quiz_#{params[:quiz_id]}"
  end

  def unsubscribed
    stop_all_streams
  end
end