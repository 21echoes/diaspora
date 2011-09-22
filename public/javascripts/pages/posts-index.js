Diaspora.Pages.PostsIndex = function() {
  var self = this;

  this.subscribe("page/ready", function(evt, document) {

    self.strainerNavigation = self.instantiate("StrainerNavigation", document.find("ul#aspect_nav"), document.find("ul#tag_nav"));
    self.stream = self.instantiate("Stream", document.find("#aspect_stream_container"));
    self.infiniteScroll = self.instantiate("InfiniteScroll");
  });
};
