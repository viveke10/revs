function last_item_is_visible(container) {
	var this_filmstrip = $(".filmstrip", container);
	var last_item_offset = $("li.last", this_filmstrip).offset().left + $("li.last", this_filmstrip).width();
	var filmstrip_offset = this_filmstrip.offset().left + this_filmstrip.width();
	return (last_item_offset < filmstrip_offset);
}

$(window).resize(function(){
	$(".filmstrip-container").each(function(){
		if(last_item_is_visible($(this))){
		  $("[data-direction=right]", $(this)).addClass("disabled");	
		}else{
			$("[data-direction=right]", $(this)).removeClass("disabled");	
		}
	});
});
 
$(document).on('ready', function(){
  $(".filmstrip-container").each(function(){
	  var container = $(this);
	  var filmstrip = $(".filmstrip", container);
	  $(".scroll-control", container).each(function(){		  
		  $(this).click(function(){
				if(!$(this).hasClass("disabled") && !$("ul", filmstrip).is(":animated")){
	  			var direction = $(this).attr("data-direction");  
					var travel_amount = (direction == "left" ? "+=" : "-=") + "108";
					$("#pointer").animate({left: travel_amount}, "slow");
					$("ul", filmstrip).animate({left: travel_amount }, "slow", function(){
						if($("ul", filmstrip).position().left == "0"){
							$("[data-direction=left]", container).addClass("disabled");
						}else{
							$("[data-direction=left]", container).removeClass("disabled");
						}
						if(last_item_is_visible(container)){
							$("[data-direction=right]", container).addClass("disabled");
						}else{
							$("[data-direction=right]", container).removeClass("disabled");
						}
					});
				}
			  return false;
		  });
	  });
  });
});
