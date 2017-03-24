#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "nokogiri"
# require "pp"

file_name = "temp-dude2nag.xml"
output_dir = "host_configs"

unless File.exists?(file_name)
  puts "Unable to find input xml file: #{file_name}"
  exit 1
end

data = {}
doc = Nokogiri::XML(File.open(file_name))
doc.search("Device", "NetworkMapElement").each do |e|
  case e.name
  when "NetworkMapElement"
    item_raw = e.at("itemID")
    next unless item_raw
    item_id = item_raw.text
    cords = [e.at("itemX"), e.at("itemY")].map(&:text).join(",")
    if data.key?(item_id)
      data[item_id][:cords] = cords
    else
      puts "Unable to find data for: #{item_id}"
    end

  when "Device"
    sys_id = e.at("sys-id").text
    sys_name = e.at("sys-name").text
    addresses = e.at("addresses").text rescue "brak"
    parent_ids = e.at("parentIDs").text rescue "brak"

    data[sys_id] = {
      name: sys_name,
      addresses: addresses,
      parent_ids: parent_ids
    }
  else
    raise "Unknown main tag: #{e.name}"
  end
end

FileUtils.mkdir_p output_dir

data.each_pair do |dev_id, dev_data|
  puts(<<-END_INFO)
id: #{dev_id}
Nazwa #{dev_data[:name]}
ip #{dev_data[:addresses]}
parent #{dev_data[:parent]}
Koordynaty #{dev_data[:cords]}
END_INFO

  host_cfg_file = File.join(output_dir, ["host_", dev_id, ".cfg"].join)

  File.open(host_cfg_file, "w") do |file|
    file.puts(<<-END_FILE)
define host {
  use host-template
  host_name #{dev_data[:name]}
  alias #{dev_data[:name]}
  addresses #{dev_data[:addresses]}
  parents #{dev_data[:parent]}
  2d_coords #{dev_data[:cords]}
  tcontact_groups admins
}
END_FILE
  end
end
