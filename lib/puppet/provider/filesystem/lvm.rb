Puppet::Type.type(:filesystem).provide :lvm do
    desc "Manages filesystem of a logical volume"

    commands :mount => 'mount', :df => 'df', :tune2fs => 'tune2fs'

    def create
        mkfs(@resource[:fs_type])
    end

    def exists?
        fstype != nil
    end

    def destroy
        # no-op
    end

    def fstype
        mount('-f', '--guess-fstype', @resource[:name]).strip
    rescue Puppet::ExecutionFailure
        nil
    end

    def mkfs(fs_type)
        mkfs_params = { "reiserfs" => "-q" }
        mkfs_cmd    = ["mkfs.#{fs_type}", @resource[:name]]
        
        if mkfs_params[fs_type]
            mkfs_cmd << mkfs_params[fs_type]
        end
        
        if resource[:options]
            mkfs_options = Array.new(resource[:options].split)
            mkfs_cmd << mkfs_options
        end

        execute mkfs_cmd
    end

    def self.filesystems
      mounts = []
      lines = df('-TlhP', '--exclude-type=tmpfs').split("\n")
      lines.shift  # remove header
      lines.each do | line |
        mount = line.split(/\ +/)
        mount[2] = findoptions(mount[0]).join(' ')
        mounts << mount
      end
    end

    def self.instances
      filesystems.map { | fs | new(:name => fs[0], :fs_type => fs[1], :options => fs[2]) }
    end

    def self.findoptions(device)
      options = []
      attrs = tune2fs('-l', device).split("\n")
      attrs.shift
      attrs.each do | attr |
        opts = attr.split(':')
        case opts.first
          when "Block Size"
            options << "-b #{opts.last}"
          when "Filesystem UUID"
            options << "-U #{opts.last}"
          when "Inode size"
            options << "-I #{opts.last}"
          # TODO map more attributes where mkfs options match tune2fs options
        end
      end
    end



end
