#! /usr/bin/ruby

# TODO: check against drive UUID's not just identifiers.

@threads = []
@drives = []
@working = []
@readyed = false

# This will do damaging things.
@armed = true;

@settings = {
  label: 'RESOURCE',
  data: '/Users/michael/Desktop/CONTENT/*'
}

# These are essentially parameters to the `grep` command.
@drive_identifiers = [
  'DOS_FAT_32'
]

def gui_clear
  puts "\e[H\e[2J"
end

def gui_draw_table
  gui_clear
  puts @drives.count.to_s + ' drive(s)'
  @drives.each do |drive|
    puts drive + ":\t" + status(drive)
  end
end

def main_thread()
  while (true) do
    gui_draw_table
    look_for_new_drives()
    sleep(0)

    if !@readyed && @working.empty?
      #puts 'READY / DONE.'
      @readyed = true
    end
  end
end

def get_drives
  disk_ids = []
  drive_string = @drive_identifiers.join(' | grep ')
  disks = `diskutil list | grep #{drive_string}`.split("\n")
  disks.each do |disk|
    disk_ids.push /.*GB\s+(.*)/.match(disk)[1]
  end

  disk_ids
end

def get_drive_uuid(identifier)

end

def new_a(old_list, new_list)
  new_a = []

  new_list.each do |n|
    new_a.push n if !old_list.include?(n)
  end

  new_a
end

def old_a(old_list, new_list)
  old_a = []

  old_list.each do |n|
    old_a.push n if !new_list.include?(n)
  end

  old_a
end

def status(drive, status = nil)
  file_name = drive + '.lock'
  if status == nil
    if File.exists?(file_name)
      `cat #{drive}.lock`
    else
      ""
    end
  else
    `echo '#{status}' > #{file_name}`
  end
end

def lock_drive(drive)
  file_name = drive + '.lock'
  if File.exists?(file_name)
    return false
  end
  status(drive, 'locked')
end

def unlock_drive(drive)
  file_name = drive + '.lock'
  File.delete file_name
end

def format_drive(drive)
  #puts "Erasing #{drive}"
  status(drive, 'formatting')
  `diskutil reformat #{drive}`
  if !$?.success?
    sleep 1
    #puts "Retrying erasing #{drive}"
    `diskutil reformat #{drive}`
    if !$?.success?
      sleep 2
      #puts "Retrying erase #{drive}"
      `diskutil reformat #{drive}`
      if !$?.success?
        return status(drive, 'format failed')
      end
    end
  end
  status(drive, 'formatted')
end

def eject_drive(drive)
  #puts "Ejecting #{drive}"
  status(drive, 'ejecting')
  `diskutil unmountDisk #{drive}`
  
  if !$?.success?
    sleep 1
#    puts "retrying unmount #{drive}"
    `diskutil unmountDisk #{drive}`
    if !$?.success?
      sleep 2
      #puts "retrying unmount #{drive}"
      `diskutil unmountDisk #{drive}`
      if !$?.success?
        return status(drive, 'eject failed')
      else
      end
    end
  end
  status(drive, 'ejected')
end

def new_drive(drive)
  #status(drive, 'found')
  #puts "Found " + drive

  if lock_drive(drive)
    @working.push drive
    sleep 1

    # Erase Drive
    if @armed
      format_drive drive
      sleep 1
    end

    # Label Drive
    if @armed
      status(drive, 'labeling')
      #puts "Labeling #{drive}"
      `diskutil renameVolume #{drive} "#{@settings[:label]}"`
      status(drive, 'labeled')
      sleep 1
    end

    # Copy Content
    if @armed
      mount_point = /^(?:\S+\s){2}(.*) \(/.match(`mount | grep #{drive}`)[1]
      # TODO Wait for mount point.
      #puts "Copying #{drive}"
      status(drive, 'copying')
      `rsync -av #{@settings[:data]} "#{mount_point}/"`
      status(drive, 'copied')
      sleep 1
    end

    # Eject
    eject_drive drive
    sleep 1

    @working.delete drive
    @readyed = false

    unlock_drive(drive)
  else
    status(drive, 'lock failed')
  end
end

def old_drive(drive)
  #puts "Lost " + drive
end

def look_for_new_drives
  current_drives = get_drives()
  
  new_drives = new_a(@drives, current_drives)
  old_drives = old_a(@drives, current_drives)

  @drives = current_drives

  new_drives.each do |drive|
    @threads << Thread.new(drive) do |drive|
      new_drive(drive)
    end
  end
  old_drives.each do |drive|
    @threads << Thread.new(drive) do |drive|
      old_drive(drive)
    end
  end
end

`rm *.lock > /dev/null 2> /dev/null`

main_thread()



@threads.each { |aThread|  aThread.join }
