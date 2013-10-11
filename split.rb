# Frin https://gist.github.com/bertspaan/6229816
require 'json'
require 'fileutils'
require 'active_support/inflector'
 
def to_geojson(feature)
  single_geojson = {
    "type" => "FeatureCollection",
    "features" => [feature]
  }

  JSON.pretty_generate(single_geojson)
end

def to_osm(feature)
  nodes = []
  way_nodes = []
  properties = []
  n = -1

  properties << "<tag k=\"name\" v=\"#{feature["properties"]["SUBURB"].titleize}\" />"
  properties << "<tag k=\"boundary\" v=\"administrative\" />"
  properties << '<tag k="admin_level" v="10" />'
  

  feature["geometry"]["coordinates"].first.each do |coord|
    if n < -1
      nodes << "<node visible=\"true\" id=\"#{n}\" lat=\"#{coord[1]}\" lon=\"#{coord[0]}\" />"
      way_nodes << "<nd ref=\"#{n}\"/>"
    end
    


    n -= 1
  end
  

  %Q{<?xml version="1.0" encoding="UTF-8"?>
  <osm version='0.6' generator='CloCkWeRX'>    
    #{nodes.join("\n")}
    <way visible=\"true\" id="-1">
      <nd ref=\"#{n+1}\"/>
      #{way_nodes.join("\n")}
    #{properties.join("\n")}
    </way>
  </osm>
  }
end


ARGV.select{ |file| [".json", ".geojson"].include? File.extname(file) }.each do |file|
  basename = File.basename(file, File.extname(file))
  geojson = JSON.parse(File.open(file).read)
  if geojson.has_key? "features"
    
    # Create directory if not exists:
    unless Dir.exists?(basename)
      Dir.mkdir(basename)
    end
    
    geojson["features"].each_with_index { |feature, index|    

      name = feature["properties"]["SUBURB"]

      single_file = "#{basename}/#{basename}_#{index}_#{name.gsub(/\ /, '_')}.geojson"
      puts "Writing file #{index + 1}/#{geojson["features"].length}: #{single_file}"
      
      File.open(single_file, 'w') { |file| file.write(to_geojson(feature)) }

      single_file = "#{basename}/#{basename}_#{index}_#{name.gsub(/\ /, '_')}.osm"
      puts "Writing file #{index + 1}/#{geojson["features"].length}: #{single_file}"
      
      File.open(single_file, 'w') { |file| file.write(to_osm(feature)) }      
    }
  end
end
