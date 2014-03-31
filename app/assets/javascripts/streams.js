function timeAgoFormat() {
  $("span[data-time]").each(function() {
    var utcms     = this.dataset.time,
  localDate = new Date(parseInt(utcms));

  this.title = localDate.toString();
  this.innerHTML = moment(localDate).fromNow();
  });
}

$(document).ready(timeAgoFormat)

function startStream() {
  $(document).ready(function() {
    var messages = $("#messages");
    var streamUrl = $("#output").data("streamUrl");
    var source = new EventSource(streamUrl);

    var addLine = function(data) {
      var msg = JSON.parse(data).msg;
      messages.append(msg);
      if (following) {
        messages.scrollTop(messages[0].scrollHeight);
      }
    };

    source.addEventListener('append', function(e) {
      addLine(e.data);
    }, false);

    source.addEventListener('viewers', function(e) {
      var users = JSON.parse(e.data);

      if(users.length > 0) {
        var viewers = $.map(users, function(user) {
          return user.name;
        }).join(', ') + '.';

        $('#viewers-link .badge').html(users.length);
        $("#viewers").html('Other viewers: ' + viewers);
      } else {
        $('#viewers-link .badge').html(0);
        $("#viewers").html('No other viewers.');
      }
    }, false);

    source.addEventListener('replace', function(e) {
      messages.children().last().remove();
      addLine(e.data);
    }, false);

    source.addEventListener('finished', function(e) {
      var data = JSON.parse(e.data);

      $('#header').html(data.html);
      window.document.title = data.title;

      toggleOutputToolbar();
      timeAgoFormat();

      source.close();
    }, false);
  });
}
