(function() {
  Danbooru.Favorite = {};
  
  Danbooru.Favorite.initialize_all = function() {
    this.hide_or_show_add_to_favorites_link();
  }
  
  Danbooru.Favorite.hide_or_show_add_to_favorites_link = function() {
    var favorites = Danbooru.meta("favorites");
    var current_user_id = Danbooru.meta("current-user-id");
    if (current_user_id == "") {
      $("a#add-to-favorites").hide();
      $("a#remove-from-favorites").hide();
      return;
    }
    var regexp = new RegExp("\\bfav:" + current_user_id + "\\b");
    if ((favorites != undefined) && (favorites.match(regexp))) {
      $("a#add-to-favorites").hide();
    } else {
      $("a#remove-from-favorites").hide();      
    }
  }
  
  Danbooru.Favorite.create = function(post_id) {
    Danbooru.Post.notice_update("inc");
    
    $.ajax({
      type: "POST",
      url: "/favorites",
      data: {
        post_id: post_id
      },
      complete: function() {
        Danbooru.Post.notice_update("dec");
      },
      error: function(data, status, xhr) {
        Danbooru.j_alert("Error: " + data.reason);
      }
    });
  }
  
  Danbooru.Favorite.destroy = function(post_id) {
    Danbooru.Post.notice_update("inc");
    
    $.ajax({
      type: "DELETE",
      url: "/favorites/" + post_id,
      complete: function() {
        Danbooru.Post.notice_update("dec");
      }
    });
  }
})();

$(document).ready(function() {
  Danbooru.Favorite.initialize_all();
});
