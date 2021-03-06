#!/usr/bin/env ruby
require 'hiera'

ENV['LANG'] = 'C'

hiera = Hiera.new(:config => '/etc/hiera.yaml')
test_vm_images = hiera.lookup 'test_vm_image', {}, {}

raise 'Not test_vm_image data!' unless [Array, Hash].include?(test_vm_images.class) && test_vm_images.any?

test_vm_images = [test_vm_images] unless test_vm_images.is_a? Array

test_vm_images.each do |image|
  %w(
  disk_format
  img_path
  img_name
  os_name
  public
  container_format
  min_ram
  ).each do |f|
    raise "Data field '#{f}' is missing!" unless image[f]
  end
end

def image_list
  stdout = `. /root/openrc && glance image-list`
  return_code = $?.exitstatus
  images = []
  stdout.split("\n").each do |line|
    fields = line.split('|').map { |f| f.chomp.strip }
    next if fields[1] == 'ID'
    next unless fields[2]
    images << fields[2]
  end
  {:images => images, :exit_code => return_code}
end

def image_create(image_hash)
  command = <<-EOF
. /root/openrc && /usr/bin/glance image-create \
--name '#{image_hash['img_name']}' \
--is-public '#{image_hash['public']}' \
--container-format='#{image_hash['container_format']}' \
--disk-format='#{image_hash['disk_format']}' \
--min-ram='#{image_hash['min_ram']}' \
#{image_hash['glance_properties']} \
--file '#{image_hash['img_path']}'
EOF
  puts command
  stdout = `#{command}`
  return_code = $?.exitstatus
  [ stdout, return_code ]
end

# check if Glance is online
# waited until the glance is started because when vCenter used as a glance
# backend launch may takes up to 1 minute.
def wait_for_glance
  5.times.each do |retries|
    sleep 10 if retries > 0
    return if image_list[:exit_code] == 0
  end
  raise 'Could not get a list of glance images!'
end

# upload image to Glance
# if it have not been already uploaded
def upload_image(image)
  list_of_images = image_list
  if list_of_images[:images].include?(image['img_name']) && list_of_images[:exit_code] == 0
    puts "Image '#{image['img_name']}' is already present!"
    return 0
  end

  stdout, return_code = image_create(image)
  if return_code == 0
    puts "Image '#{image['img_name']}' was uploaded from '#{image['img_path']}'"
  else
    puts "Image '#{image['img_name']}' upload from '#{image['img_path']}' have FAILED!"
  end
  puts stdout
  return return_code
end

########################

wait_for_glance

test_vm_images.each do |image|
  upload_image(image)
end
