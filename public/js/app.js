;(function() {

  $res = $('#res');
  $err = $('#err');
  $res.hide();
  $err.hide();

	/* SUBJECT */
	$('#ai').on('submit', function(e) {
		e.preventDefault();
		$('.remarks').empty();

		var obj = {
			subject: $("#subject").val()
		};
		
		$.ajax({
      type: "POST",
      url: "/",
      dataType: 'json',
      data: JSON.stringify(obj),
      success: function(data) {
				
				data.result.forEach(function(item) {
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
					$('.remarks').append(li);
				});
			}
   });
	});

  $('#sendLead').on('click', function(e) {
    var em = $('#lead').val();
    $res.hide();
    $err.hide();
    
    var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        
    if(!re.test(String(em).toLowerCase())) {
      $err.show();
      return false;
    }

    var r = $.get('https://www.menteduegentlig.tech/suggest?e=' + em, function(res) {
      return res;
    });

    r.then(function(res) {
      if(res.corrected) {
        $('#response').html('Mente du egentlig: ' + '<a style="cursor:pointer;" id="suggest">'+res.email_suggest + '</a>');
        return;
      }else{
        var reqObj = {
          text: em + ' har sjekket ut emnefelt-app og ønsker å bli kontaktet!'
        }

        $.ajax({
          type: "POST",
          url: "https://hooks.slack.com/services/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",
          dataType: 'JSON',
          data: JSON.stringify(reqObj)
        });

        $res.show();
       
      }
    });
  });

  $(document).on('click', '#suggest', function(e) {
    em.val($(this).text())
  });

})();
