/**
 * Created by liumengjun on 1/12/16.
 */

$(function(){
    var defaultErrMsg = '请求失败,请稍后重试,或联系管理员!';

    $("select[name=province]").change(function(e){
        var pro_id = $(this).val(), $city_sel = $("select[name=city]"), $dist_sel = $("select[name=district]");
        $.getJSON('/staff/teachers/action/', {'action': 'list-region', 'sid': pro_id}, function(json){
            if (json && json.list) {
                $city_sel.find('option:gt(0)').remove();
                $dist_sel.find('option:gt(0)').remove();
                for (var i in json.list) {
                    var reg = json.list[i];
                    $city_sel.append('<option value="'+reg.id+'">'+reg.name+'</option>');
                }
            }
        });
    });
    $("select[name=city]").change(function(e){
        var dist_id = $(this).val(), $dist_sel = $("select[name=district]");
        $.getJSON('/staff/teachers/action/', {'action': 'list-region', 'sid': dist_id}, function(json){
            if (json && json.list) {
                $dist_sel.find('option:gt(0)').remove();
                for (var i in json.list) {
                    var reg = json.list[i];
                    $dist_sel.append('<option value="'+reg.id+'">'+reg.name+'</option>');
                }
            }
        });
    });

    $('a[data-action=show-avatar]').click(function(e){
        var url = $(this).attr('url');
        var $modal = $("#avatarModal");
        $modal.find('img').attr('src', url);
        $modal.modal();
    });

});
