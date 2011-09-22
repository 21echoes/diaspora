#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require 'spec_helper'
require File.join(Rails.root, 'spec', 'shared_behaviors', 'stream')

describe Stream::Multi do
  context "aspect filtering" do
    before do
      @alices_aspect_1 = alice.aspects.where(:name => "generic").first
      @alices_aspect_2 = alice.aspects.create(:name => "another aspect")
    end

    describe '#aspects' do
      it "returns the intersection of a users aspects and the inputted aspect ids" do
        stream = Stream::Multi.new(alice, [1,2,3], [])
        stream.aspects.should == alice.aspects.select{|a| [1,2,3].include?(a.id)}
      end
    end

    describe '#aspect_ids' do
      it 'maps ids from aspects' do
        stream = Stream::Multi.new(alice, [1,2,3], [])
        stream.aspect_ids.should == alice.aspects.select{|a| [1,2,3].include?(a.id)}.map{|a| a.id}
      end
    end
  end

  context "tag filtering" do
    before do
      alice.post(:status_message, :text => "#cats", :to => 'all')
      bob.post(:status_message, :text => "#cats", :to => 'all')
      alice.post(:status_message, :text => "#dog", :to => 'all')
      bob.post(:status_message, :text => "#dogs", :to => 'all')

      @tag = ActsAsTaggableOn::Tag.find_or_create_by_name("cats")
      @tag_following = alice.tag_followings.create(:tag_id => @tag.id)
    end

    describe '#tags' do
      it "returns the intersection of a users followed tags inputted tag ids" do
        input_tags = [@tag.id,@tag.id+1,@tag.id+2]
        stream = Stream::Multi.new(alice, [1,2,3], input_tags)
        stream.send(:tags).should == alice.followed_tags.select{|a| input_tags.include?(a.id)}
      end
    end

    describe '#tag_ids' do
      it 'maps ids from tags' do
        input_tags = [@tag.id,@tag.id+1,@tag.id+2]
        stream = Stream::Multi.new(alice, [1,2,3], input_tags)
        stream.tag_ids.should == alice.followed_tags.select{|a| input_tags.include?(a.id)}.map{|a| a.id}
      end
    end
  end

  #TODO(dk) : what is really being tested here?
  describe '#posts' do
    before do
      @alice = stub.as_null_object
    end

    it 'calls visible posts for the given user' do
      stream = Stream::Multi.new(@alice, [1,2], [])
      stream.stub(:tags_post_ids).and_return([1,2])

      @alice.should_receive(:visible_shareable_ids).and_return(stub.as_null_object)
      stream.posts
    end

    it 'respects ordering' do
      stream = Stream::Multi.new(@alice, [1,2], [], :order => 'created_at')
      stream.stub(:tags_post_ids).and_return([1,2])
      stream.stub(:mentioned_post_ids).and_return([1,2])
      @alice.should_receive(:visible_shareable_ids).with(Post, hash_including(:order => 'created_at DESC')).and_return([1,2])
      stream.posts
    end

    it 'respects max_time' do
      stream = Stream::Multi.new(@alice, [1,2], [], :max_time => 123)
      stream.stub(:tags_post_ids).and_return([1,2])
      stream.stub(:mentioned_post_ids).and_return([1,2])
      @alice.should_receive(:visible_shareable_ids).with(Post, hash_including(:max_time => instance_of(Time))).and_return([1,2])
      stream.posts
    end

    it 'passes aspect_ids to visible posts' do
      stream = Stream::Multi.new(@alice, [1,2], [], :max_time => 123)
      stream.stub(:tags_post_ids).and_return([1,2])
      stream.stub(:mentioned_post_ids).and_return([1,2])
      stream.stub(:aspect_ids).and_return([1,2])
      @alice.should_receive(:visible_shareable_ids).with(Post, hash_including(:by_members_of => [1,2])).and_return([1,2])
      stream.posts
    end
  end

  describe '#people' do
    it 'should list everyone in the stream and everyone in the selected aspects' do
      pending 'make some peeps, make some posts, check everyones in position' # TODO(dk)
    end
  end

  describe 'for_all_aspects?' do
    before do
      alice = stub.as_null_object
      alice.aspects.stub(:size).and_return(2)
      @stream = Stream::Multi.new(alice, [1,2], [])
    end

    it "is true if the count of aspect_ids is equal to the size of the user's aspect count" do
      @stream.should be_for_all_aspects
    end

    it "is false if the count of aspect_ids is not equal to the size of the user's aspect count" do
      @stream.stub(:aspects).and_return([1])
      @stream.should_not be_for_all_aspects
    end
  end

  # TODO(dk): for_everything, for_all_tags

  describe "fresh soup" do
    before do
      @alices_aspect_1 = alice.aspects.where(:name => "generic").first
      @alices_aspect_2 = alice.aspects.create(:name => "another aspect")
    end

    it "when nothing is passed in, it returns all the user's aspects if all_aspects, and all tags if the all_tags" do
      stream = Stream::Multi.new(alice, alice.aspects.map{|a| a.id}, [], :all_aspects => true, :all_tags => true)
      stream.should be_for_everything

      stream = Stream::Multi.new(alice, [@alices_aspect_1.id], [], :all_aspects => false, :all_tags => false)
      stream.should_not be_for_everything
    end
  end

  describe '.ajax_stream?' do
    before do
      @original_value = AppConfig[:redis_cache]
      @stream = Stream::Multi.new(stub, stub, stub)
    end

    after do
      AppConfig[:redis_cache] = @original_value
    end

    context 'if we are not caching with redis' do
      before do
        AppConfig[:redis_cache] = false
      end

      it 'is true if stream is for all everything' do
        @stream.stub(:for_everything?).and_return(true)
        @stream.ajax_stream?.should be_true
      end

      it 'is false if it is not for everything' do
        @stream.stub(:for_everything?).and_return(false)
        @stream.ajax_stream?.should be_false
      end
    end

    context 'if we are caching with redis' do
      it 'returns false' do
        AppConfig[:redis_cache] = true
        @stream.ajax_stream?.should be_false
      end
    end
  end

  describe 'shared behaviors: aspects' do
    before do
      @stream = Stream::Multi.new(alice, [], [])
    end
    it_should_behave_like 'it is a stream'
  end
end
