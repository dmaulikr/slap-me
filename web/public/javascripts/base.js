( function () {
   "use-strict"

    var nextPageToken = '',
        maxResults = 2,
        isLoading = false,
        $window =  $(window),
        moreData = function () {
            //var url = 'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=' + maxResults + '&pageToken=' + nextPageToken + '&playlistId=UUHttLxxgurd_NcRmWqn3cvg&key=AIzaSyBFZlfcJVs-t72kp-cg8VF4szWDYRutp4M';
            var url = 'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=' + maxResults + '&pageToken=' + nextPageToken + '&playlistId=UU9QkEr96mSIXxDzZXfz7tww&key=AIzaSyDHnZXXzp6NO4ND5Fi6gADEjxytJysihuc';
            isLoading = true;
            $('.la-anim-10').addClass('la-animate');
            $.ajax({
                url: url,
                dataType: "jsonp"
            }).done(function( data ) {
                if (typeof data.items !== 'undefined') {
                    $.each(data.items, function (i, val) {
                        var video = val.snippet,
                            html= '';
                        html += '<div class="item-plain bottom">';
                        html += '<div class="video-wrapper"><iframe width="560" height="315"src="//www.youtube.com/embed/' + video.resourceId.videoId +'" frameborder="0" allowfullscreen></iframe></div>';
                        html += '<h3>' + video.title + '</h3>';
                        html += '</div>';

                        $('.items-container').append(html);
                    });
                    nextPageToken = data.nextPageToken || 'finish';
                    isLoading = false;
                    if ( 'finish' === nextPageToken ) {
                        $window.off('scroll');
                    }
                }
                setTimeout(function () { $('.la-anim-10').removeClass('la-animate'); }, 1000);

            });
        };

    $('.cbp-vm-icon').on('click', function (e) {
        e.preventDefault();
        $('.cbp-vm-selected').removeClass('cbp-vm-selected');
        $(this).addClass('cbp-vm-selected');
        $('.cbp-vm-view').hide();
        $('.' + $(this).data('view')).show();
    });

    $window.scroll(function () {
        var winValues = {
            scrollTop: $window.scrollTop(),
            height: $window.height()
        },
        docHeight = $(document).height();

        if( !isLoading && (winValues.scrollTop + winValues.height) > (docHeight -30) ) {
            moreData();
        }
    });

    moreData();

}());