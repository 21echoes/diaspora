#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

module StreamHelper
  #TODO(dk):next_page_path should be defined by the Stream itself, not this helper (but: some things aren't streams??)
  def next_page_path(opts={}, pass_through_params={})
    if [AppsController, PeopleController].include? controller.class
      parameters = pass_through_params.merge({:max_time => @posts.last.created_at.to_i})
    else
      parameters = pass_through_params.merge({:max_time => time_for_scroll(opts[:ajax_stream], @stream), :sort_order => session[:sort_order]})
    end

    if controller.instance_of?(TagsController)
      tag_path(@tag, parameters)
    elsif controller.instance_of?(AppsController)
      "/apps/1?#{parameters.to_param}"
    elsif controller.instance_of?(PeopleController)
      person_path(@person, parameters)
    elsif [MultisController,AspectsController,TagFollowingsController].include? controller.class
      multi_path(parameters.merge({:a_ids => @stream.aspect_ids, :tag_ids => @stream.tag_ids}))
    elsif controller.instance_of?(CommunitySpotlightController)
      spotlight_path(parameters)
    elsif controller.instance_of?(MentionsController)
      mentions_path(parameters)
    elsif controller.instance_of?(PostsController) 
      public_stream_path(parameters)
    else
      raise 'in order to use pagination for this new controller, update next_page_path in stream helper'
    end
  end

  def time_for_scroll(ajax_stream, stream)
    if ajax_stream || stream.stream_posts.empty?
      (Time.now() + 1).to_i
    else
      stream.stream_posts.last.send(stream.order.to_sym).to_i
    end
  end

  def time_for_sort(post)
    if [AspectsController,MultisController].include? controller
      post.send(session[:sort_order].to_sym)
    else
      post.created_at
    end
  end

  def comments_expanded
    false
  end

  def reshare?(post)
    post.instance_of?(Reshare)
  end
end
