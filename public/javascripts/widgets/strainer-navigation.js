/*   Copyright (c) 2010, Diaspora Inc.  This file is
 *   licensed under the Affero General Public License version 3 or later.  See
 *   the COPYRIGHT file.
 */

(function() {
  Diaspora.Widgets.StrainerNavigation = function() {
    var self = this;

    this.subscribe("widget/ready", function(evt, aspectNavigation, tagNavigation) {
      $.extend(self, {
        aspectNavigation: aspectNavigation,
        aspectLis: aspectNavigation.find("li[data-aspect_id]"),
        aspectSelectors: aspectNavigation.find("a.aspect_selector[data-guid]"),
        aspectsToggle: aspectNavigation.find("a.toggle_selector"),
        tagNavigation: tagNavigation,
        tagLis: tagNavigation.find("li[data-tag_id]"),
        tagSelectors: tagNavigation.find("a.tag_selector[data-guid]"),
        tagsToggle: tagNavigation.find("a.toggle_selector")
      });

      self.aspectSelectors.click(self.toggleSelector);
      self.tagSelectors.click(self.toggleSelector);
      self.aspectsToggle.click(self.toggleAllAspects);
      self.tagsToggle.click(self.toggleAllTags);
    });

    this.selectedAspects = function() {
      return self.aspectNavigation.find("li.active[data-aspect_id]").map(function() { return $(this).data('aspect_id') });
    };

    this.toggleSelector = function(evt) {
      evt.preventDefault();

      $(this).parent().toggleClass("active");
      self.perform();
    };

    this.toggleAllAspects = function(evt) {
      evt.preventDefault();

      if (self.allAspectsSelected()) {
        self.aspectLis.removeClass("active");
      } else {
        self.aspectLis.addClass("active");
      }
      self.perform();
    };

    this.toggleAllTags = function(evt) {
      evt.preventDefault();

      if (self.allTagsSelected()) {
        self.tagLis.removeClass("active");
      } else {
        self.tagLis.addClass("active");
      }
      self.perform();
    };

    this.perform = function() {
      if (self.noneSelected()) {
        self.abortAjax();
        Diaspora.page.stream.empty();
        Diaspora.page.stream.setHeaderTitle(Diaspora.I18n.t('strainer_navigation.no_strainers'));
        self.fadeIn();
      } else {
        self.performAjax();
      }
      self.calculateToggleText();
    };

    this.calculateToggleText = function() {
      if (self.allAspectsSelected()) {
        self.aspectsToggle.text(Diaspora.I18n.t('aspect_navigation.deselect_all'));
      } else {
        self.aspectsToggle.text(Diaspora.I18n.t('aspect_navigation.select_all'));
      }

      if (self.allTagsSelected()) {
        self.tagsToggle.text(Diaspora.I18n.t('aspect_navigation.deselect_all'));
      } else {
        self.tagsToggle.text(Diaspora.I18n.t('aspect_navigation.select_all'));
      }
    };

    this.generateURL = function() {
      var baseURL = 'stream';

      // TODO(dk): there's gotta be a way to pass params in POST for real...
      // generate new url
      baseURL = baseURL.replace('#','');
      baseURL += '?';

      self.aspectLis.each(function() {
        var aspectLi = $(this);
        if (aspectLi.hasClass("active")) {
          baseURL += "a_ids[]=" + aspectLi.data("aspect_id") + "&";
        }
      });

      self.tagLis.each(function() {
        var tagLi = $(this);
        if (tagLi.hasClass("active")) {
          baseURL += "tag_ids[]=" + tagLi.data("tag_id") + "&";
        }
      });

      if(!$("#publisher").hasClass("closed")) {
        // open publisher
        baseURL += "op=true";
      } else {
        // slice last '&'
        baseURL = baseURL.slice(0,baseURL.length-1);
      }
      return baseURL;
    };

    this.performAjax = function() {
      var post = $("#publisher textarea#status_message_fake_text").val(),
        newURL = self.generateURL(),
        photos = {};

      //pass photos
   	  $('#photodropzone img').each(function() {
        var img = $(this);
        photos[img.attr("data-id")] = img.attr("src");
      });

      self.abortAjax();
      self.fadeOut();

      self.jXHR = $.getScript(newURL, function(data) {
        var textarea = $("#publisher textarea#status_message_fake_text"),
          photozone = $("#photodropzone");

        if( post !== "" ) {
          textarea.val(post).focus();
        }

        $.each(photos, function(GUID, URL) {
          photozone.append([
            '<li style="position: relative;">',
              '<img src="' + URL + ' data-id="' + GUID + '/>',
            '</li>'
          ].join(""));
        });

        self.globalPublish("stream/reloaded");
        if( post !== "" ) {
          Publisher.open();
        }
        self.fadeIn();
      });
    };

    this.abortAjax = function() {
      if (self.jXHR) {
        self.jXHR.abort();
        self.jXHR = null;
      }
    };

    this.noneSelected = function() {
      return self.aspectLis.filter(".active").length === 0 && self.tagLis.filter(".active").length === 0;
    }

    this.allAspectsSelected = function() {
      return self.aspectLis.not(".active").length === 0;
    }

    this.allTagsSelected = function() {
      return self.tagLis.not(".active").length === 0;
    }

    this.fadeOut = function() {
      $("#aspect_stream_container").fadeTo(100, 0.4);
      $("#selected_aspect_contacts").fadeTo(100, 0.4);
    };

    this.fadeIn = function() {
      $("#aspect_stream_container").fadeTo(100, 1);
      $("#selected_aspect_contacts").fadeTo(100, 1);
    };
  };
})();
