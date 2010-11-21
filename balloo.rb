
# @url http://labs.infocity.co.jp/blog/2008/07/balloojp.html

require 'rexml/document'
require 'net/http'
require 'uri'

$KCODE = 'u'

class Balloo

  def initialize()
    @lastno = 0
    @channel_code = 'livenhk_'
    @channel_list = [
      'livenhk_', # NHK総合
      'liveetv_', # NHK教育
      'liventv_', # 日本テレビ
      'livetbs_', # 東京放送
      'livecx_',  # フジテレビ
      'liveanb_', # テレビ朝日
      'livetx_',  # テレビ東京'
    ]
  end

#def boardlist
#url = 'http://balloo.jp/balloo/cgi/boardlist.php';
#$re = file_get_contents($url);
#var_dump($re);
#end
        
  def fetch()
    source = ''
    hostname = "balloo.jp";
    url = "/balloo/cgi/getthread.php?thread_id=#{@channel_code}&lastno=#{@lastno}";

    Net::HTTP.new(hostname).start do |w|
      source = w.get(url).body
    end

    return source
  end

  def parse_xml(source)
    items = []
    doc = REXML::Document.new(source)
    doc.elements['/board/thread'].each do |element|
      if element != "\n"
        @lastno = element.attributes["no"].to_i
        item = element.attributes
        item["text"] = element.text.split("\n").join(' ').gsub(/<\/?[^>]*>/, "").strip

        one_minuts_ago = (Time.now - 30).strftime("%Y%m%d%H%M%S")
        if one_minuts_ago.to_i <= item["timestamp"].to_i
          items << item
        end
      end
    end

    return items
  end

  def set_channel(channel_code)
    if !@channel_list.index(channel_code)
      return
    end
    @lastno = 0
    @channel_code = channel_code
  end
end

def send(text, color = 1)
  text = URI.encode(text).strip
  if text.empty?
    return
  end

  url = "http://192.168.1.25/user.cgi?data=#{text}&color=#{color}"
  begin
    open(url)
    sleep 0.2
  rescue
  end
end

channel_code = ARGV.shift
if channel_code.empty?
  channel_code = 'liventv_'
end

balloo = Balloo.new
balloo.set_channel(channel_code)

while true do
  source = balloo.fetch
  items = balloo.parse_xml(source)
  items.each do |item|
    color = 2
    if (item["location"] != "2ch")
      color = 3
      item["text"] = "[#{item['location']}]#{item['text']}"
    end
    send("#{item['text']}", color)
  end
  sleep 5
end

=begin
#API test data
source = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<board name="tv-jikkyo">
<thread channel="livenhk" regist="20101121141143" serial="7816" title="ＮＨＫアーカイブス" update="20101121145858">
<speak location="2ch" no="54726" originalID="3805201" originalNum="990" timestamp="20101121145858" who="w+TPZ0Ww"> ギルガメッシュナイト </speak>
<speak location="2ch" no="54727" originalID="3805201" originalNum="991" timestamp="20101121145858" who="Doud+i5j"> &#60;a id=&quot;tanchor_54727-0&quot; href=&quot;javascript:showRelation(54714, '54727-0')&quot;&#62;&amp;gt;&amp;gt;978&#60;/a&#62;( １１ＰＭのスキャットの人と、アルプスの少女ハイジ...)
 伊集加代子だろ </speak>
</thread>
</board>
EOF
=end
