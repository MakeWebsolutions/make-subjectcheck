;(function() {
  'use strict';

  function analyze(obj, remarks) {
    $.ajax({
      type: "POST",
      url: "/",
      dataType: 'json',
      data: JSON.stringify(obj),
      success: function(data) {
        
        data.result.forEach(function(item) {
          var icon, li;

          if(item.status === 'danger') {
            icon = 'thumbs-o-down';
          }else if (item.status === 'warning') {
            icon = 'exclamation-triangle';
          }else if(item.status === 'info') {
            icon = 'info-circle';
          }else{
            icon = 'thumbs-o-up';
          }

          li = $('<div/>').addClass('alert alert-'+item.status).html('<i class="fa fa-'+icon+'" aria-hidden="true"></i><strong class="word">'+item.word+'</strong>' + item.comment);
          $('.'+remarks).append(li);
        });
      }
    });
  }



  /* SUBJECT */
	$('#ai').on('submit', function(e) {
		e.preventDefault();
		$('.remarks').empty();

		var obj = {
			subject: $("#subject").val().replace(/\?+/, '?')
		};

    analyze(obj, 'remarks');
	});

  /* PREHADER */
  $('#aj').on('submit', function(e) {
    e.preventDefault();
    $('.remarks2').empty();

    var obj = {
      subject: $('#preheader').val().replace(/\?+/, '?')
    }

    analyze(obj, 'remarks2');
  });

  //Attach event for emailsubmit
  $('body').on('click', '#user_submit', function(e) {
    e.preventDefault();
    e.stopPropagation()

    var $user_email = $('#user_email'),
        $user_phone = $('#user_phone');

    if(!$user_email.val()) {
      $user_email.addClass('user_error');
      return;
    }

    if(!$user_phone.val()) {
      $user_phone.addClass('user_error');
      return;
    }

    $.ajax({
      type: 'POST',
      url: 'https://www.make.as/make-spamtester.php',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      data: {
        email: $user_email.val(),
        phone: $user_phone.val(),
        page_name: 'Nyhetsbrev Emnetester - Make AS',
        page_url: 'https://emnefelt.make.as',
        app_name: 'Newsletter'
      },
      success: function(data, textStatus, request){
        var $s = $('<div class="toastr">Vi har registrert din henvendelse!</div>');
          $('body').append($s);

        setTimeout(function() {
          $s.remove();
        }, 3000);       
      },
      error: function (request, textStatus, errorThrown) {
       console.log('error');
       
      }
    });

  });

})();
