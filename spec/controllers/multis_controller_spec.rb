require 'spec_helper'

describe MultisController do
  #describe "custom logging"  TODO(dk): does this still apply?
  #describe "custom logging on success" do
  #  before do
  #    @action = :index
  #  end
  #  it_should_behave_like "it overrides the logs on success"
  #end
  #
  #describe "custom logging on error" do
  #  class FakeError < RuntimeError;
  #    attr_accessor :original_exception;
  #  end
  #  before do
  #    @action = :index
  #    @desired_error_message = "I love errors"
  #    @error = FakeError.new(@desired_error_message)
  #    @orig_error_message = "I loooooove nested errors!"
  #    @error.original_exception = NoMethodError.new(@orig_error_message)
  #    @controller.stub(:index).and_raise(@error)
  #  end
  #  it_should_behave_like "it overrides the logs on error"
  #end
  #
  #describe "custom logging on redirect" do
  #  before do
  #    @action = :show
  #    @action_params = {'id' => @alices_aspect_1.id.to_s}
  #  end
  #  it_should_behave_like "it overrides the logs on redirect"
  #end
  #end

  #describe "aspect viewing" do
  describe "#index" do
    before do
      sign_in :user, alice
      @alices_aspect_1 = alice.aspects.where(:name => "generic").first
      @alices_aspect_2 = alice.aspects.create(:name => "another aspect")

      @controller.stub(:current_user).and_return(alice)
      request.env["HTTP_REFERER"] = 'http://' + request.host
    end

    context 'jasmine fixtures' do
      before do
        Stream::Multi.any_instance.stub(:ajax_stream?).and_return(false)
      end

      it "generates a jasmine fixture", :fixture => true do
        get :index
        save_fixture(html_for("body"), "aspects_index")
      end

      it "generates a jasmine fixture with a prefill", :fixture => true do
        get :index, :prefill => "reshare things"
        save_fixture(html_for("body"), "aspects_index_prefill")
      end

      it 'generates a jasmine fixture with services', :fixture => true do
        alice.services << Services::Facebook.create(:user_id => alice.id)
        alice.services << Services::Twitter.create(:user_id => alice.id)
        get :index, :prefill => "reshare things"
        save_fixture(html_for("body"), "aspects_index_services")
      end

      it 'generates a jasmine fixture with posts', :fixture => true do
        bob.post(:status_message, :text => "Is anyone out there?", :to => @bob.aspects.where(:name => "generic").first.id)
        message = alice.post(:status_message, :text => "hello "*800, :to => @alices_aspect_2.id)
        5.times { bob.comment("what", :post => message) }
        get :index
        save_fixture(html_for("body"), "aspects_index_with_posts")
      end

      it "generates a jasmine fixture with a post with comments", :fixture => true do
        message = bob.post(:status_message, :text => "HALO WHIRLED", :to => @bob.aspects.where(:name => "generic").first.id)
        5.times { bob.comment("what", :post => message) }
        get :index
        save_fixture(html_for("body"), "aspects_index_post_with_comments")
      end

      it 'generates a jasmine fixture with a followed tag', :fixture => true do
        @tag = ActsAsTaggableOn::Tag.create!(:name => "partytimeexcellent")
        TagFollowing.create!(:tag => @tag, :user => alice)
        get :index
        save_fixture(html_for("body"), "aspects_index_with_one_followed_tag")
      end

      it "generates a jasmine fixture with a post containing a video", :fixture => true do
        stub_request(
          :get,
          "http://gdata.youtube.com/feeds/api/videos/UYrkQL1bX4A?v=2"
        ).with(
          :headers => {'Accept'=>'*/*'}
        ).to_return(
          :status  => 200,
          :body    => "<title>LazyTown song - Cooking By The Book</title>",
          :headers => {}
        )

        stub_request(
          :get,
          "http://www.youtube.com/oembed?format=json&frame=1&iframe=1&maxheight=420&maxwidth=420&url=http://www.youtube.com/watch?v=UYrkQL1bX4A"
        ).with(
          :headers => {'Accept'=>'*/*'}
        ).to_return(
          :status  => 200,
          :body    => "{ title: 'LazyTown song - Cooking By The Book' }",
          :headers => {}
        )

        alice.post(:status_message, :text => "http://www.youtube.com/watch?v=UYrkQL1bX4A", :to => @alices_aspect_2.id)
        get :index
        save_fixture(html_for("body"), "aspects_index_with_video_post")
      end

      it "generates a jasmine fixture with a post that has been liked", :fixture => true do
        message = alice.post(:status_message, :text => "hello "*800, :to => @alices_aspect_2.id)
        alice.build_like(:positive => true, :target => message).save
        bob.build_like(:positive => true, :target => message).save

        get :index
        save_fixture(html_for("body"), "aspects_index_with_a_post_with_likes")
      end
    end

    it 'renders just the stream with the infinite scroll param set' do
      get :index, :only_posts => true
      response.should render_template('shared/_stream')
    end

    it 'assigns an Stream::Multi' do
      get :index
      assigns(:stream).class.should == Stream::Multi
    end

    describe 'filtering by aspect' do
      before do
        @aspect1 = alice.aspects.create(:name => "test aspect")
        @stream = Stream::Multi.new(alice, [], [])
      end

      it 'respects a single aspect' do
        Stream::Multi.should_receive(:new).with(alice, [@aspect1.id], anything, anything).and_return(@stream)
        get :index, :a_ids => [@aspect1.id]
      end

      it 'respects multiple aspects' do
        aspect2 = alice.aspects.create(:name => "test aspect two")
        Stream::Multi.should_receive(:new).with(alice, [@aspect1.id, aspect2.id], anything, anything).and_return(@stream)
        get :index, :a_ids => [@aspect1.id, aspect2.id]
      end
    end

    describe 'performance', :performance => true do
      before do
        require 'benchmark'
        8.times do |n|
          user = Factory.create(:user)
          aspect = user.aspects.create(:name => 'people')
          connect_users(alice, @alices_aspect_1, user, aspect)
          post = alice.post(:status_message, :text => "hello#{n}", :to => @alices_aspect_2.id)
          8.times do |n|
            user.comment "yo#{post.text}", :post => post
          end
        end
      end
      it 'takes time' do
        Benchmark.realtime {
          get :index
        }.should < 1.5
      end
    end


  end

  describe "mobile site" do
    before do
      ap = alice.person
      posts = []
      posts << alice.post(:reshare, :root_guid => Factory(:status_message, :public => true).guid, :to => 'all')
      posts << alice.post(:status_message, :text => 'foo', :to => alice.aspects)
      photo = Factory(:activity_streams_photo, :public => true, :author => ap)
      posts << photo
      posts.each do |p|
        alice.build_like(:positive => true, :target => p).save
      end
      alice.add_to_streams(photo, alice.aspects)
      sign_in alice
    end

    it 'should not 500' do
      get :index, :format => :mobile
      response.should be_success
    end
  end
  #end

end
