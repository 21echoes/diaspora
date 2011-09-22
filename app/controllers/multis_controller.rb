#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require File.join(Rails.root, 'lib', 'stream', 'multi')

class MultisController < ApplicationController
  before_filter :authenticate_user!
  before_filter :save_sort_order, :only => :index
  before_filter :save_filter_options, :only => :index
  before_filter :ensure_page, :only => :index

  def index
    #TODO(dk): eventually, pash a hash of filter options here
    #TODO(dk): refactor all the other children of BaseStream as instantiations/cached versions of Strainer ?
    aspects = (session[:a_ids] ? session[:a_ids] : [])
    tags = (session[:tag_ids] ? session[:tag_ids] : [])
    @stream = Stream::Multi.new(current_user, aspects, tags,
                               :order => sort_order,
                               :max_time => max_time,
                               :all_aspects => (session[:fresh] || params[:all_aspects]),
                               :all_tags => (session[:fresh] || params[:all_tags]))
    default_stream_action(@stream)
  end


  def ensure_page
    params[:max_time] ||= Time.now + 1
  end

  private

  def save_filter_options
    session[:fresh] = (params[:only_posts] or session[:a_ids] or params[:a_ids] or session[:tag_ids] or params[:tag_ids]) ? false : true
    if params[:only_posts] or params[:_]
      session[:a_ids] = params[:a_ids]
      session[:tag_ids] = params[:tag_ids]
    end
  end
end