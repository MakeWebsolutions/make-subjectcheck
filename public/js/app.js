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

          icon = item.status.split(' ')[0];

          li = $('<div/>')
            .addClass('alert alert-'+item.status)
            .html('<i class="fa fa-'+icon+'" aria-hidden="true"></i>&nbsp;<strong class="word">'+item.word+'</strong>' + ' - ' + item.comment);
          
          $('.'+remarks).append(li);
        });
      }
    });
  }



  /* SUBJECT */
	$('#ai').on('submit', function(e) {
		e.preventDefault();
    e.stopPropagation();

		$('.remarks').empty();

		var obj = {
			subject: $("#subject").val().replace(/\?+/, '?')
		};

    analyze(obj, 'remarks');
	});



})();
