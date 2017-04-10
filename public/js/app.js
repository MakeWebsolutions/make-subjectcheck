;(function() {

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

	/* SENDER */
	$('#av').on('submit', function(e) {
		e.preventDefault();

		$.ajax({
      type: "GET",
      url: "https://make-dnscheck.herokuapp.com?d=" + $("#sender").val(),
      success: function(data) {
				console.log(data);
      }
     });
	});

})();
