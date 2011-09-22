#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require 'spec_helper'

describe StreamHelper do
  before do
    @post = Factory(:status_message)
  end
  describe "#time_for_sort" do
    it "returns sort_order for an aspectscontroller or multiscontroller" do
      sort_order = :stored_in_session
      stub!(:controller).and_return(AspectsController.new)
      stub!(:session).and_return({:sort_order => sort_order})
      @post.should_receive(sort_order)
      time_for_sort(@post)

      stub!(:controller).and_return(MultisController.new)
      stub!(:session).and_return({:sort_order => sort_order})
      @post.should_receive(sort_order)
      time_for_sort(@post)
    end
    it "returns post.created_at otherwise" do
      stub!(:controller).and_return(mock())
      time_for_sort(@post).should == @post.created_at
    end
  end

  describe '#next_page_path' do
    it 'works for apps page' do
      stub!(:controller).and_return(AppsController.new) #TODO(dk):this apparently doesn't load anything for @posts
      @posts = [Factory(:activity_streams_photo)]
      next_page_path.should include '/apps/1'
    end
  end
end
